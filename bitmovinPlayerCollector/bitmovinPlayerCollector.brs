sub init()
  m.tag = "[bitmovinPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
  m.videoStartTimeoutTimer = m.top.FindNode("videoStartTimeoutTimer")
  m.videoStartFailedEvents = getVideoStartFailedEvents()
  m.errorSeverities = getErrorSeverities()
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
  ' Set up sourceLoaded observer seperately since we never intend to unobserve it unless the collector is destroyed
  m.player.observeFieldScoped("sourceLoaded", "onSourceLoaded")

  m.previousState = ""
  m.currentState = player.playerState

  eventData = {
    playerTech: "bitmovin",
    version: getPlayerVersion(),
    player: "bitmovin",
    playerKey: getPlayerKeyFromManifest(m.appInfo),

    playerStartupTime: 1
  }
  sendAnalyticsRequestAndClearValues(eventData, 0, m.currentState)
end sub

sub destroy(param = invalid)
  unobserveFields(true)

  if m.collectorCore <> invalid
    setVideoTimeEnd()

    ' When the Bitmovin SDK fires PLAYING/PAUSED→READY just before the destroy event,
    ' the playerStateTimer is reset during that transition — use the saved pre-READY values.
    if m.priorStateBeforeReady <> invalid and m.priorDurationBeforeReady > 0
      duration = m.priorDurationBeforeReady
      effectiveState = m.priorStateBeforeReady
    else
      duration = getDuration(m.playerStateTimer)
      effectiveState = m.currentState
    end if

    sampleData = {
      state: effectiveState,
      duration: duration,
      time: getCurrentTimeInMilliseconds()
    }
    if effectiveState = m.playerStates.PLAYING
      sampleData.played = duration
    else if effectiveState = m.playerStates.PAUSED
      sampleData.paused = duration
    end if
    decorateSampleWithPlaybackData(sampleData)
    updateSample(sampleData)
    m.collectorCore.callFunc("internalDestroy", invalid)
  end if
end sub

sub setUpObservers()
  unobserveFields()

  m.player.observeFieldScoped("playerState", "onPlayerStateChanged")
  m.player.observeFieldScoped("seek", "onSeek")
  m.player.observeFieldScoped("seeked", "onSeeked")

  m.player.observeFieldScoped("play", "onPlay")
  m.player.observeFieldScoped("sourceUnloaded", "onSourceUnloaded")

  m.player.observeFieldScoped("videoDownloadQualityChanged", "onVideoDownloadQualityChanged")

  m.player.observeFieldScoped("error", "onError")
  m.player.observeFieldScoped("destroy", "onDestroy")

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")
end sub

sub unobserveFields(isDestroy = false)
  if m.player <> invalid
    m.player.unobserveFieldScoped("playerState")
    m.player.unobserveFieldScoped("seek")
    m.player.unobserveFieldScoped("seeked")

    m.player.unobserveFieldScoped("play")

    ' Only unobserve sourceLoaded if it is a destroy event so we can collect data again when a new source is loaded
    if isDestroy then m.player.unobserveFieldScoped("sourceLoaded")

    m.player.unobserveFieldScoped("sourceUnloaded")

    m.player.unobserveFieldScoped("videoDownloadQualityChanged")

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

  m.priorStateBeforeReady = invalid
  m.priorDurationBeforeReady = invalid

  m.currentVideoBitrate = invalid

  m.observersTornDown = false

  m.pendingErrorSession = invalid
end sub

sub onPlayerStateChanged()
  transitionToState(m.player.playerState)
  m.collectorCore.playerState = m.currentState

  setVideoTimeEnd()
  handlePreviousState(m.previousState)
  handleCurrentState()

  ' The Bitmovin SDK fires PLAYING/PAUSED→READY synchronously before the destroy event.
  ' handlePreviousState's <> READY guard (which prevents double-counting on source changes)
  ' blocks the played/paused sample and the timer is reset below — so we save the duration
  ' here for destroy() to recover it when it finds the state is READY.
  if m.currentState = m.playerStates.READY and (m.previousState = m.playerStates.PLAYING or m.previousState = m.playerStates.PAUSED)
    m.priorStateBeforeReady = m.previousState
    m.priorDurationBeforeReady = m.playerStateTimer.TotalMilliseconds()
  else
    m.priorStateBeforeReady = invalid
    m.priorDurationBeforeReady = invalid
  end if

  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

sub handlePreviousState(previousState)
  if previousState = m.playerStates.PLAYING and m.currentState <> m.playerStates.READY
    onPlayed(previousState)
  else if previousState = m.playerStates.PAUSED and m.currentState <> m.playerStates.READY
    onPaused(previousState)
  else if previousState = m.playerStates.STALLING and m.currentState <> m.playerStates.READY
    onBufferingEnd()
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

sub onBufferingEnd()
  if m.bufferTimer = invalid then return

  buffered = m.bufferTimer.TotalMilliseconds()
  eventData = {
    buffered: buffered
  }

  setVideoTimeStart()
  sendAnalyticsRequestAndClearValues(eventData, buffered, "buffering")
  resetBufferingTimer()
end sub

sub onHeartbeat()
  flushPlayingSegment()
end sub

sub flushPlayingSegment()
  setVideoTimeEnd()
  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()
  sendAnalyticsRequestAndClearValues({ played: duration }, duration, m.currentState)
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
  videoDuration = m.player.callFunc("getDuration", invalid)
  if videoDuration <> invalid then videoDuration = videoDuration * 1000
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

sub onVideoDownloadQualityChanged()
  eventData = m.player.videoDownloadQualityChanged
  if eventData = invalid then return
  targetQuality = eventData.targetQuality
  if targetQuality = invalid then return
  processQualityChangeEvent(targetQuality.bitrate)
end sub

sub processQualityChangeEvent(newBitrate)
  if newBitrate = invalid then return

  m.currentVideoBitrate = newBitrate

  ' Only send a qualityChange sample when playing; on the initial event the player is not playing yet
  if m.currentState = m.playerStates.PLAYING
    flushPlayingSegment()

    sample = {
      videoBitrate: m.currentVideoBitrate,
      videoTimeStart: getCurrentPlayerTimeInMs(),
      videoTimeEnd: getCurrentPlayerTimeInMs()
    }
    sendAnalyticsRequestAndClearValues(sample, 0, "qualityChange")
  end if

  updateSample({ videoBitrate: m.currentVideoBitrate })
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
  errorData = m.player.error

  setVideoTimeEnd()

  m.top.error = {
    error: {
      code: errorData.code,
      message: errorData.message,
      severity: m.errorSeverities.critical
    }
    errorContext: {
      originalError: errorData
    }
  }

  duration = getDuration(m.playerStateTimer)
  resetSeekHelperVariables()
  resetBufferingTimer()

  transformedError = m.top.error.error
  transformedErrorSample = {
    errorCode: transformedError.code
    errorMessage: transformedError.message
    errorSeverity: transformedError.severity
  }

  sendErrorSample(transformedErrorSample, duration)

  m.collectorCore.callFunc("onError", transformedErrorSample)
end sub

sub sendErrorSample(transformedErrorSample, duration)
  currentSession = {
    impressionId: m.collectorCore.callFunc("getCurrentImpressionId")
    sequenceNumber: m.collectorCore.callFunc("getCurrentSequenceNumber")
  }

  ' A failover load started a new session while this error notification was
  ' still pending, so the error belongs to the session snapshotted on the
  ' unload rather than to the one being tracked now (AN-5074). The impression
  ' is the only signal that is guaranteed to have moved by this point: the
  ' player emits "sourceLoaded" - which is what switches the session - before
  ' it moves playerState off "error", and the pending error notification is
  ' delivered in between, so playerState still reads "error" here.
  isErrorFromPreviousSession = m.pendingErrorSession <> invalid and m.pendingErrorSession.impressionId <> currentSession.impressionId

  if isErrorFromPreviousSession
    ' Every live helper describes the failover source by now: the state timer
    ' has been marked again by its state changes, didVideoPlay flips as soon as
    ' it starts playing, and playerState follows it too. The sample has to
    ' describe the session that failed, so it is built from the snapshot alone.
    sampleDuration = m.pendingErrorSession.duration
    sampleState = m.pendingErrorSession.state
    sampleDidAttemptPlay = m.pendingErrorSession.didAttemptPlay
    sampleDidVideoPlay = m.pendingErrorSession.didVideoPlay

    m.collectorCore.callFunc("updateSample", { impressionId: m.pendingErrorSession.impressionId, sequenceNumber: m.pendingErrorSession.sequenceNumber })
  else
    sampleDuration = duration
    sampleState = m.player.playerState
    sampleDidAttemptPlay = m.didAttemptPlay
    sampleDidVideoPlay = m.didVideoPlay
  end if

  ' The startup watchdog is only ever started for the first source that
  ' attempts playback, so the source running now is the one still relying on
  ' it. An error belonging to an earlier session must not clear it, or a
  ' failover source that never starts loses its timeout sample.
  clearStartupWatchdog = not isErrorFromPreviousSession

  if sampleDidAttemptPlay = true and sampleDidVideoPlay = false
    videoStartFailed(m.videoStartFailedEvents.PlayerError, sampleDuration, sampleState, transformedErrorSample, clearStartupWatchdog)
  else
    ' Previous sample is already sent, no duration needed
    sendAnalyticsRequestAndClearValues(transformedErrorSample, 0, sampleState)
  end if

  if isErrorFromPreviousSession
    m.collectorCore.callFunc("updateSample", currentSession)
  else
    ' Stop collecting data
    m.observersTornDown = true
    unobserveFields()
  end if

  m.pendingErrorSession = invalid

  m.collectorCore.callFunc("adBreakEnd")
end sub

' Handler for player's onDestroy callback.
sub onDestroy()
  destroy()
end sub

function shouldFinishRunningSample()
  return m.currentState = m.playerStates.PLAYING or m.currentState = m.playerStates.PAUSED
end function

function setCustomData(customData)
  if customData = invalid then return invalid
  sanitized = m.collectorCore.callFunc("extractCustomDataFields", customData)
  if not m.collectorCore.callFunc("isCustomDataChanging", sanitized) then return invalid

  if shouldFinishRunningSample() then finishRunningSampleForCustomDataUpdate()
  return updateSample(sanitized)
end function

sub finishRunningSampleForCustomDataUpdate()
  setVideoTimeEnd()
  duration = getDuration(m.playerStateTimer)

  if m.currentState = m.playerStates.PLAYING
    sendAnalyticsRequestAndClearValues({ played: duration }, duration, m.currentState)
    m.playerStateTimer.Mark()
    setVideoTimeStart()
  else if m.currentState = m.playerStates.PAUSED
    sendAnalyticsRequestAndClearValues({ paused: duration }, duration, m.currentState)
    m.playerStateTimer.Mark()
    setVideoTimeStart()
  end if
end sub

sub setCustomDataOnce(customData)
  if customData = invalid then return
  sanitized = m.collectorCore.callFunc("extractCustomDataFields", customData)

  currentTime = getCurrentPlayerTimeInMs()
  sampleData = sanitized
  sampleData.Append({
    state: "customdatachange",
    duration: 0,
    videoTimeStart: currentTime,
    videoTimeEnd: currentTime,
    time: getCurrentTimeInMilliseconds()
  })
  decorateSampleWithPlaybackData(sampleData)

  m.collectorCore.callFunc("createTempMetadataSampleAndSendAnalyticsRequest", sampleData)
end sub

sub finishRunningSample()
  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()

  sendAnalyticsRequestAndClearValues({}, duration)
end sub

function setAnalyticsConfig(config)
  if config = invalid then return invalid

  return m.collectorcore.callFunc("updateAnalyticsConfig", config)
end function

function getImpressionIdForSample()
  return m.collectorCore.callFunc("getRandomImpressionId")
end function

function getPlayerKeyFromManifest(appInfo)
  if appInfo = invalid then return invalid

  return appInfo.getValue("bitmovin_player_license_key")
end function

sub onSourceLoaded()
  if m.observersTornDown
    setUpObservers()
    m.observersTornDown = false
  end if

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
  ' Read before handleIntermediateState() marks the state timer again.
  durationInFinalState = getDuration(m.playerStateTimer)

  handleIntermediateState(m.currentState)
  m.videoStartUpTime = -1

  ' The player writes its "error" field a few ms after this unload (AN-5074), by
  ' which time the app may already have loaded a failover source and moved the
  ' session on - taking the startup flags, the state timer and the player's own
  ' state with it. Everything an error sample needs to describe this session is
  ' therefore kept here, while it is still true. See sendErrorSample().
  ' The sequence number is read after handleIntermediateState(), since that may
  ' have sent a closing sample and moved it on.
  m.pendingErrorSession = {
    impressionId: m.collectorCore.callFunc("getCurrentImpressionId")
    sequenceNumber: m.collectorCore.callFunc("getCurrentSequenceNumber")
    duration: durationInFinalState
    state: m.player.playerState
    didAttemptPlay: m.didAttemptPlay
    didVideoPlay: m.didVideoPlay
  }

  ' Source may be unloaded without a subsequent sourceLoaded/destroy event, so close out
  ' any active SSAI ad break here rather than leaving it open indefinitely.
  m.collectorCore.callFunc("adBreakEnd")
end sub

sub startVideoStartUpTimer()
  m.videoStartupTimer = createObject("roTimeSpan")
end sub

sub stopVideoStartUpTimer()
  if m.videoStartupTimer = invalid or m.videoStartupTime >= 0 then return

  m.videoStartUpTime = m.videoStartupTimer.TotalMilliseconds()

  eventData = {
    videoStartupTime: m.videoStartupTime,
    startupTime: m.videoStartUpTime,
    autoplay: getAutoplay(m.player.callFunc("getConfig"))
  }

  sendAnalyticsRequestAndClearValues(eventData, m.videoStartUpTime, "startup")
end sub

function getAutoplay(config)
  autoplay = false

  if config <> invalid
    if config.playback <> invalid
      autoplay = config.playback.autoplay = true
    end if
  end if

  return autoplay
end function

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
'@param {Boolean} clearStartupWatchdog - Whether the startup timeout timer belongs to this
'                                        sample's session and should be stopped with it
sub videoStartFailed(reason, duration, state, additionalEventData = invalid, clearStartupWatchdog = true)
  if reason = invalid return

  if clearStartupWatchdog then clearVideoStartTimeoutTimer()

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


function getCurrentPlayerTimeInMs()
  playerCurrentTime = m.player.callFunc("getCurrentTime")

  if playerCurrentTime = invalid
    return 0
  end if

  time% = playerCurrentTime * 1000
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

function adBreakStart(adBreakMetadata = invalid)
  m.collectorCore.callFunc("adBreakStart", adBreakMetadata)
end function

function adStart(adMetadata = invalid)
  m.collectorCore.callFunc("adStart", adMetadata)
end function

function adBreakEnd(param = invalid)
  m.collectorCore.callFunc("adBreakEnd")
end function

'Function to report that an `adQuartile` has been reached during an SSAI-based ad.
'@param {String} adQuartile - The adQuartile to be reported. Values can either be `"first'`, `"midpoint"`, `"third"` or `"completed"`.
'@param {Object} adQuartileMetadata - Metadata to be reported with the `adQuartile`. Can currently only contain a `failedBeaconUrl` to indicate that pinging a related beacon was not successful.
function adQuartileFinished(adQuartile, adQuartileMetadata = invalid)
  m.collectorCore.callFunc("adQuartileFinished", adQuartile, adQuartileMetadata)
end function
