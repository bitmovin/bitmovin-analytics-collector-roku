sub init()
  m.tag = "[bitmovinPlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
  m.playerStateTimer = CreateObject("roTimespan")
  m.appInfo = CreateObject("roAppInfo")
  m.deviceInfo = CreateObject("roDeviceInfo")
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
    playerKey: getPlayerKeyFromManifest(m.appInfo),

    playerStartupTime: 1
  }
  sendAnalyticsRequestAndClearValues(eventData, 0, m.currentState)
end sub

sub setUpObservers()
  m.player.observeFieldScoped("playerState", "onPlayerStateChanged")
  m.player.observeFieldScoped("seek", "onSeek")
  m.player.observeFieldScoped("seeked", "onSeeked")

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")

  m.player.observeFieldScoped("play", "onPlay")
  m.player.observeFieldScoped("sourceLoaded", "onSourceLoaded")
  m.player.observeFieldScoped("sourceUnloaded", "onSourceUnloaded")

  m.player.observeFieldScoped("error", "onError")
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
end sub

sub onPlayerStateChanged()
  transitionToState(m.player.playerState)
  m.collectorCore.playerState = m.currentState

  setVideoTimeEnd()
  handlePreviousState()
  handleCurrentState()

  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

sub handlePreviousState()
  if m.previousState = m.playerStates.PLAYING
    onPlayed()
  else if m.previousState = m.playerStates.PAUSED
    onPaused()
  else if m.previousState = m.playerStates.BUFFERING
    onBufferingEnd()
  end if
end sub

sub handleCurrentState()
  if m.currentState = m.playerStates.PLAYING
    onVideoStart()
  else if m.currentState = m.playerStates.PAUSED
    onPause()
  else if m.currentState = m.playerStates.BUFFERING
    onBuffering()
  else if m.currentState = m.playerStates.FINISHED
    onFinished()
  end if
end sub

sub onPlayed()
  played = m.playerStateTimer.TotalMilliseconds()
  eventData = {
    played: played
  }

  sendAnalyticsRequestAndClearValues(eventData, played)
end sub

function wasSeeking()
  return m.seekTimer <> invalid
end function

sub onPause()
  ' The video node does not have a seeking state, because of that we have to assume that on pause is the beginning of a seek operation until proven otherwise
  m.alreadySeeking = true
  m.seekStartPosition = getCurrentPlayerTimeInMs()
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onPaused()
  ' If we did not change from the pause state to playing that means a seek is happening
  if m.currentState <> m.playerStates.PLAYING then return

  paused = m.playerStateTimer.TotalMilliseconds()
  eventData = {
    paused: paused
  }

  sendAnalyticsRequestAndClearValues(eventData, paused)
  resetSeekHelperVariables()
end sub

sub resetSeekHelperVariables()
  m.alreadySeeking = false
  m.seekStartPosition = invalid
  m.seekTimer = invalid
end sub

sub onBuffering()
  ' If we did not change from playing to buffering that means the buffering was caused by a seek and thus we do not report it
  if m.previousState <> m.playerStates.PLAYING then return
  m.bufferTimer = CreateObject("roTimespan")
end sub

sub onBufferingEnd()
  if m.bufferTimer = invalid then return

  buffered = m.bufferTimer.TotalMilliseconds()
  m.bufferTimer = invalid

  eventData = {
    buffered: buffered
  }

  sendAnalyticsRequestAndClearValues(eventData, buffered)
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
    errorMessage: m.player.error.message,
    errorSegments: []
  }

  if m.player.downloadFinished <> invalid then errorSample.errorSegments.push(m.player.downloadFinished)

  resetSeekHelperVariables()

  duration = getDuration(m.playerStateTimer)
  sendAnalyticsRequestAndClearValues(errorSample, duration, m.player.playerState)
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

function setAnalyticsConfig(configData)
  if configData = invalid return invalid

  return updateSample(configData)
end function

function getImpressionIdForSample()
  return m.collectorCore.callFunc("createImpressionId")
end function

function getPlayerKeyFromManifest(appInfo)
  if appInfo = invalid then return invalid

  return appInfo.getValue("bitmovin_player_license_key")
end function

sub onPlay()
  startVideoStartUpTimer()
end sub

sub onSourceLoaded()
  config = m.player.callFunc("getConfig", invalid)

  checkForSourceSpecificMetadata(config)
  if config.autoplay = false then return

  startVideoStartUpTimer()

  checkForNewMetadata()
  ' Do not change impression id when it is a initial source change
  if m.currentState <> m.player.BitmovinPlayerState.SETUP
    handleManualSourceChange()
  end if
end sub

sub onSourceUnloaded()
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

sub checkForSourceSpecificMetadata(config)
  updatedMetadata = mapStream(config.source)
  updateSample(updatedMetadata)
  if config.analytics = invalid then return

  updateSampleAndSendAnalyticsRequest(config.analytics)
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
  return time%
end function

sub setVideoTimeStart()
  m.collectorCore.callFunc("setVideoTimeStart", getCurrentPlayerTimeInMs())
end sub

sub setVideoTimeEnd()
  m.collectorCore.callFunc("setVideoTimeEnd", getCurrentPlayerTimeInMs())
end sub

function getPlayerVersion()
  return "unknown"
end function