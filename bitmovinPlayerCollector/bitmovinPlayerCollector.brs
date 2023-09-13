sub init()
  m.tag = "[bitmovinPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
  m.videoStartTimeoutTimer = m.top.FindNode("videoStartTimeoutTimer")
  m.videoStartFailedEvents = getVideoStartFailedEvents()
  m.playerStateTimer = CreateObject("roTimespan")
  m.appInfo = CreateObject("roAppInfo")
  m.deviceInfo = CreateObject("roDeviceInfo")
end sub

sub initializeAnalytics(config = invalid)
  m.collectorCore.callFunc("initializeAnalytics", config)
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player

  setUpHelperVariables()
  setUpObservers()

  m.previousState = ""
  m.currentState = player.playerState

  eventData = {
    playerTech: "bitmovin",
    version: getPlayerVersion(),
    player: "Bitmovin",
    playerKey: getPlayerKeyFromManifest(m.appInfo),

    playerStartupTime: 1
  }
  sendAnalyticsRequestAndClearValues(eventData, 0, m.currentState)
end sub

sub destroy(param = invalid)
  unobserveFields()

  if m.collectorCore <> invalid
    m.collectorCore.callFunc("internalDestroy", invalid)
  end if
end sub

sub setUpObservers()
  m.player.observeFieldScoped("playerState", "onPlayerStateChanged")
  m.player.observeFieldScoped("seek", "onSeek")
  m.player.observeFieldScoped("seeked", "onSeeked")

  m.player.observeFieldScoped("play", "onPlay")
  m.player.observeFieldScoped("sourceLoaded", "onSourceLoaded")
  m.player.observeFieldScoped("sourceUnloaded", "onSourceUnloaded")

  m.player.observeFieldScoped("error", "onError")
  m.player.observeFieldScoped("destroy", "onDestroy")

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")
end sub

sub unobserveFields()
  if m.player <> invalid
    m.player.unobserveFieldScoped("playerState")
    m.player.unobserveFieldScoped("seek")
    m.player.unobserveFieldScoped("seeked")

    m.player.unobserveFieldScoped("play")
    m.player.unobserveFieldScoped("sourceLoaded")
    m.player.unobserveFieldScoped("sourceUnloaded")

    m.player.unobserveFieldScoped("error")
    m.player.unobserveFieldScoped("destroy")
  end if

  if m.collectorCore <> invalid
    m.collectorCore.unobserveFieldScoped("fireHeartbeat")
  end if
end sub

sub setUpHelperVariables()
  m.seekStartPosition = invalid
  m.alreadySeeking = false

  m.newMetadata = invalid

  m.playerStates = m.player.BitmovinPlayerState
  m.playerControls = getPlayerControls()

  m.videoStartUpTime = -1

  m.didAttemptPlay = false
  m.didVideoPlay = false
end sub

sub onPlayerStateChanged()
  transitionToState(m.player.playerState)
  m.collectorCore.playerState = m.currentState

  setVideoTimeEnd()
  handlePreviousState(m.previousState)
  handleCurrentState()

  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

sub handlePreviousState(previousState)
  if previousState = m.playerStates.PLAYING and m.currentState <> m.playerStates.READY
    onPlayed(previousState)
  else if previousState = m.playerStates.PAUSED and m.currentState <> m.playerStates.READY
    onPaused(previousState)
  else if previousState = m.playerStates.STALLING and m.currentState <> m.playerStates.READY
    onBufferingEnd(previousState)
  end if
end sub

sub handleCurrentState()
  if m.currentState = m.playerStates.PLAYING
    onVideoStart()
  else if m.currentState = m.playerStates.STALLING
    onBuffering()
  else if m.currentState = m.playerStates.FINISHED
    onFinished()
  else if m.currentState = m.playerStates.READY
    playerConfig = m.player.callFunc("getConfig", invalid)
    if playerConfig.autoplay = false
      stopVideoStartUpTimer()
    end if
  end if
end sub

sub handleIntermediateState(intermediateState)
  transitionToState(intermediateState)
  setVideoTimeEnd()

  handlePreviousState(m.currentState)

  m.playerStateTimer.Mark()
  setVideoTimeStart()
  transitionToState(m.previousState)
end sub

sub onPlay()
  startVideoStartUpTimer()

  if m.didAttemptPlay = false and m.didVideoPlay = false then startVideoStartTimeoutTimer()

  m.didAttemptPlay = true
end sub

sub onPlayed(state)
  played = m.playerStateTimer.TotalMilliseconds()
  eventData = {
    played: played
  }

  sendAnalyticsRequestAndClearValues(eventData, played, state)
end sub

sub onPaused(state)
  ' If we did not change from the pause state to playing that means a seek is happening
  if m.currentState <> m.playerStates.PLAYING then return

  paused = m.playerStateTimer.TotalMilliseconds()
  eventData = {
    paused: paused
  }

  sendAnalyticsRequestAndClearValues(eventData, paused, state)
end sub

sub resetSeekHelperVariables()
  m.alreadySeeking = false
  m.seekStartPosition = invalid
  m.seekTimer = invalid
end sub

sub resetBufferingTimer()
  m.bufferTimer = invalid
end sub

sub onBuffering()
  ' If we did not change from playing to buffering that means the buffering was caused by a seek and thus we do not report it
  if m.previousState <> m.playerStates.PLAYING then return
  m.bufferTimer = CreateObject("roTimespan")
end sub

sub onBufferingEnd(state)
  if m.bufferTimer = invalid then return

  buffered = m.bufferTimer.TotalMilliseconds()
  eventData = {
    buffered: buffered
  }

  setVideoTimeStart()
  sendAnalyticsRequestAndClearValues(eventData, buffered, state)
  resetBufferingTimer()
end sub

sub onHeartbeat()
  setVideoTimeEnd()

  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()

  eventData = {
    played: duration
  }

  sendAnalyticsRequestAndClearValues(eventData, duration, m.player.playerState)
  setVideoTimeStart()
end sub

sub transitionToState(nextState)
  m.previousState = m.currentState
  m.currentState = nextState
end sub

sub decorateSampleWithPlaybackData(sampleData)
  if sampleData = invalid then return

  sampleData.Append(getVideoWindowSize(m.player.FindNode("MainVideo")))
  sampleData.Append({size: getSizeType(sampleData.videoWindowHeight, sampleData.videoWindowWidth)})

  ' Set audio language
  currentAudioTrack = m.player.callFunc("getAudio", invalid)
  if getInterface(currentAudioTrack, "ifAssociativeArray") <> invalid then
    sampleData.Append({audioLanguage: currentAudioTrack.language})
  end if

  ' Set subtitle language
  currentSubtitleTrack = m.player.callFunc("getSubtitle", invalid)
  if getInterface(currentSubtitleTrack, "ifAssociativeArray") <> invalid then
    sampleData.Append({subtitleLanguage: currentSubtitleTrack.language})
  end if

  ' Set subtitle enabled
  subtitleEnabled = false
  if m.deviceInfo.GetCaptionsMode() = "On" then
    subtitleEnabled = True
  end if
  sampleData.Append({subtitleEnabled: subtitleEnabled})

  ' Set video duration
  videoDuration = m.player.callFunc("getDuration", invalid) * 1000
  sampleData.Append({videoDuration: videoDuration})
end sub

function updateSample(sampleData)
  if sampleData = invalid return false

  return m.collectorCore.callFunc("updateSample", sampleData)
end function

sub onSeek()
  if m.alreadySeeking = true then return

  m.alreadySeeking = true
  m.seekStartPosition = getCurrentPlayerTimeInMs()
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onSeeked()
  duration = m.seekTimer.TotalMilliseconds()
  eventData = {
    videoTimeStart: m.seekStartPosition,
    seeked: duration
  }

  sendAnalyticsRequestAndClearValues(eventData, duration, "seeked")
  setVideoTimeStart() 'Finished seeking does not trigger a state change, need to manually set videoTimeStart
  resetSeekHelperVariables()
end sub

sub onVideoStart()
  stopVideoStartUpTimer()

  if m.didVideoPlay = false
    m.didVideoPlay = true
    clearVideoStartTimeoutTimer()
  end if
end sub

sub handleManualSourceChange()
  m.collectorCore.callFunc("setupSample")
end sub

sub setNewMetadata(metadata = invalid)
  if metadata = invalid then return

  m.newMetadata = metadata
end sub

sub checkForNewMetadata()
  if m.newMetadata = invalid then return

  updateSample(m.newMetadata)
  m.newMetadata = invalid
end sub

sub onError()
  setVideoTimeEnd()

  errorSample = {
    errorCode: m.player.error.code,
    errorMessage: m.player.error.message
  }

  duration = getDuration(m.playerStateTimer)
  resetSeekHelperVariables()
  resetBufferingTimer()

  if m.didAttemptPlay = true and m.didVideoPlay = false
    videoStartFailed(m.videoStartFailedEvents.PlayerError, duration, m.player.playerState, errorSample)
  else
    ' Previous sample is already sent, no duration needed
    sendAnalyticsRequestAndClearValues(errorSample, 0, m.player.playerState)
  end if

  ' Stop collecting data
  unobserveFields()
end sub

' Handler for player's onDestroy callback.
sub onDestroy()
  destroy()
end sub

function setCustomData(customData)
  if customData = invalid then return invalid
  finishRunningSample()

  return updateSample(customData)
end function

sub finishRunningSample()
  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()

  sendAnalyticsRequestAndClearValues({}, duration)
end sub

sub setCustomDataOnce(customData)
  if customData = invalid then return
  finishRunningSample()

  duration = getDuration(m.playerStateTimer)
  createTempMetadataSampleAndSendAnalyticsRequest(customData, duration)
end sub

sub setAnalyticsConfig(config)
  if config = invalid then return

  m.collectorcore.callFunc("updateAnalyticsConfig", config)
end sub

function getImpressionIdForSample()
  return m.collectorCore.callFunc("createImpressionId")
end function

function getPlayerKeyFromManifest(appInfo)
  if appInfo = invalid then return invalid

  return appInfo.getValue("bitmovin_player_license_key")
end function

sub onSourceLoaded()
  playerConfig = m.player.callFunc("getConfig", invalid)

  checkForSourceSpecificMetadata(playerConfig.source)

  startVideoStartUpTimer()

  checkForNewMetadata()
  ' Do not change impression id when it is a initial source change
  if m.currentState <> m.player.BitmovinPlayerState.SETUP
    handleManualSourceChange()
  end if
end sub

sub onSourceUnloaded()
  handleIntermediateState(m.currentState)
  m.videoStartUpTime = -1
end sub

sub startVideoStartUpTimer()
  m.videoStartupTimer = createObject("roTimeSpan")
end sub

sub stopVideoStartUpTimer()
  if m.videoStartupTimer = invalid or m.videoStartupTime >= 0 then return

  m.videoStartUpTime = m.videoStartupTimer.TotalMilliseconds()
  eventData = {
    videoStartupTime: m.videoStartupTime,
    startupTime: m.videoStartUpTime
  }

  sendAnalyticsRequestAndClearValues(eventData, m.videoStartUpTime, "startup")
end sub

sub onFinished()
  m.videoStartUpTime = -1
  resetBufferingTimer()
  resetSeekHelperVariables()
end sub

sub startVideoStartTimeoutTimer()
  m.videoStartTimeoutTimer.observeFieldScoped("fire", "onVideoStartTimeout")
  m.videoStartTimeoutTimer.control = "start"
end sub

sub clearVideoStartTimeoutTimer()
  m.videoStartTimeoutTimer.unobserveFieldScoped("fire")
  m.videoStartTimeoutTimer.control = "stop"
end sub

sub onVideoStartTimeout()
  durationMilliseconds = m.videoStartTimeoutTimer.duration * 1000
  videoStartFailed(m.videoStartFailedEvents.Timeout, durationMilliseconds, m.player.playerState)
end sub

'Trigger videoStartFailed sample
'@param {String} reason - Reason why videostart failed
'@param {number} duration - Duration of the state in milliseconds
'@param {String} state - State of the player in which the failure happened
'@param {Object} additionalEventData - Additional event data that is added to the sample
sub videoStartFailed(reason, duration, state, additionalEventData = invalid)
  if reason = invalid return

  clearVideoStartTimeoutTimer()

  eventData = {}
  if additionalEventData <> invalid then eventData.Append(additionalEventData)

  eventData.Append({
    videoStartFailed: true,
    videoStartFailedReason: reason
  })
  sendAnalyticsRequestAndClearValues(eventData, duration, state)
end sub

'Function to map source to object valid for video node to accept. Sets stream format based upon which stream type entered and value as url.
'@params {Object} source - Source object conforming to Bitmovin API standards
'@return {Object} - Source object formatted for video node to acccept.
function mapStream(source)
  if source.dash <> invalid
    return { streamFormat: "dash", mpdUrl: source.dash }
  else if source.hls <> invalid
    return { streamFormat: "hls", m3u8Url: source.hls }
  else if source.smooth <> invalid
    return { streamFormat: "smooth"}
  else if source.progressive <> invalid and type(source.progressive) = "roString"
    return { streamFormat: "mp4", progUrl: source.progressive }
  else if source.progressive <> invalid and type(source.progressive) = "roAssociativeArray"
    return { streamFormat: source.progressive.type , progUrl: source.progressive.url }
  else
    return {}
  end if
end function

sub checkForSourceSpecificMetadata(sourceConfig)
  updatedVideoMetadata = mapStream(sourceConfig)
  updateSample(updatedVideoMetadata)
end sub

sub sendAnalyticsRequestAndClearValues(eventData, duration, state = m.previousState)
  sampleData = eventData
  sampleData.Append({
    state: state,
    duration: duration,
    time: getCurrentTimeInMilliseconds()
  })
  decorateSampleWithPlaybackData(sampleData)

  updateSample(sampleData)
  m.collectorCore.callFunc("sendAnalyticsRequestAndClearValues")
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(eventData, duration, state = m.previousState)
  sampleData = eventData
  sampleData.Append({
    state: state,
    duration: duration,
    time: getCurrentTimeInMilliseconds()
  })
  decorateSampleWithPlaybackData(sampleData)

  m.collectorCore.callFunc("createTempMetadataSampleAndSendAnalyticsRequest", sampleData)
end sub

function getCurrentPlayerTimeInMs()
  time% = m.player.currentTime * 1000
  return Cint(time%)
end function

sub setVideoTimeStart()
  m.collectorCore.callFunc("setVideoTimeStart", getCurrentPlayerTimeInMs())
end sub

sub setVideoTimeEnd()
  m.collectorCore.callFunc("setVideoTimeEnd", getCurrentPlayerTimeInMs())
end sub

function getPlayerVersion()
  return "bitmovin-" + m.player.callFunc(m.player.BitmovinFunctions.GET_VERSION)
end function