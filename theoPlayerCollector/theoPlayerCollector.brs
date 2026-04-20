sub init()
  m.tag = "[theoPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
  m.videoStartTimeoutTimer = m.top.FindNode("videoStartTimeoutTimer")
  m.collectorStates = getCollectorStates()
  m.videoStartFailedEvents = getVideoStartFailedEvents()
  m.errorSeverities = getErrorSeverities()
  m.appInfo = CreateObject("roAppInfo")
  m.deviceInfo = CreateObject("roDeviceInfo")
  m.videoNode = invalid
end sub

' ===== PUBLIC METHODS =====

sub initializeAnalytics(config = invalid)
  m.collectorCore.callFunc("initializeAnalytics", config)
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player

  m.playerStateTimer = CreateObject("roTimespan")
  m.videoNode = m.player.callFunc("getVideoNode")

  resetCollectorState()

  setUpObservers()
  detectSourceFormat()

  eventData = {
    playerTech: "Roku:THEOplayer"
    version: getPlayerVersion()
    player: "theoplayer"
    playerKey: getPlayerKeyFromManifest(m.appInfo)
    playerStartupTime: 1
  }

  sendAnalyticsRequestAndClearValues(eventData, 0, m.collectorStates.SETUP)
end sub

function getPlayerKeyFromManifest(appInfo)
  if appInfo = invalid then return invalid

  return appInfo.getValue("theo_player_license_key")
end function

sub destroy(param = invalid)
  clearVideoStartTimeout()
  unobserveFields(true)

  if m.collectorCore <> invalid
    m.collectorCore.callFunc("internalDestroy", invalid)
  end if
end sub

function getPlayerVersion()
  return "theoplayer-" + m.player.version
end function

function setAnalyticsConfig(config)
  if config = invalid then return invalid

  return m.collectorCore.callFunc("updateAnalyticsConfig", config)
end function

sub setNewMetadata(metadata = invalid)
  if metadata = invalid then return

  m.pendingMetadata = metadata
end sub

sub applyPendingMetadata()
  if m.pendingMetadata = invalid then return

  updateSample(m.pendingMetadata)
  m.pendingMetadata = invalid
end sub

function shouldFinishRunningSample()
  return m.currentState = m.collectorStates.PLAYING or m.currentState = m.collectorStates.PAUSED
end function

function setCustomData(customData)
  if customData = invalid then return invalid
  sanitized = m.collectorCore.callFunc("extractCustomDataFields", customData)
  if not m.collectorCore.callFunc("isCustomDataChanging", sanitized) then return invalid

  if shouldFinishRunningSample() then finishRunningSampleForCustomDataUpdate()
  return updateSample(sanitized)
end function

sub setCustomDataOnce(customData)
  if customData = invalid then return

  if m.currentState <> m.collectorStates.SETUP then finishRunningSample()

  duration = getDuration(m.playerStateTimer)
  createTempMetadataSampleAndSendAnalyticsRequest(customData, duration, m.currentState)
end sub

sub finishRunningSample()
  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()

  sendAnalyticsRequestAndClearValues({}, duration, m.currentState)
end sub

sub programChange(newSourceMetadata = invalid)
  if newSourceMetadata = invalid then return

  if m.currentState = m.collectorStates.SETUP then
    ' no source loaded yet, handle gracefully and treat it as a simple metadata update, no new impression
    m.collectorCore.callFunc("updateAnalyticsConfig", newSourceMetadata)
    return
  end if

  ' Conclude current impression
  setVideoTimeEnd()
  stateDuration = m.playerStateTimer.TotalMilliseconds()

  finalSampleData = { isProgramChange: true }
  if m.currentState = m.collectorStates.PLAYING
    finalSampleData.played = stateDuration
  else if m.currentState = m.collectorStates.PAUSED
    finalSampleData.paused = stateDuration
  end if

  sendAnalyticsRequestAndClearValues(finalSampleData, stateDuration, m.currentState, true)

  ' Start new impression with new metadata
  m.collectorCore.callFunc("setupSample")

  ' Apply new program metadata (config-level fields: title, videoId, cdnProvider, isLive, customData, experimentName)
  m.collectorCore.callFunc("updateAnalyticsConfig", newSourceMetadata)

  ' Apply URL fields (mpdUrl, m3u8Url, progUrl, path) and infer streamFormat
  updateSample(getProgramChangeSourceMetadata(newSourceMetadata))

  ' Send first sample of new impression
  setVideoTimeStart()
  setVideoTimeEnd()
  sendAnalyticsRequestAndClearValues({ isProgramChange: true, videoStartupTime: 1 }, 0, "programChange", true)

  ' Resume state tracking
  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

function getProgramChangeSourceMetadata(metadata)
  sourceMetadata = {}
  if metadata.DoesExist("path") then sourceMetadata.path = metadata.path
  if metadata.DoesExist("mpdUrl")
    sourceMetadata.mpdUrl = metadata.mpdUrl
    sourceMetadata.streamFormat = "dash"
  end if
  if metadata.DoesExist("m3u8Url")
    sourceMetadata.m3u8Url = metadata.m3u8Url
    sourceMetadata.streamFormat = "hls"
  end if
  if metadata.DoesExist("progUrl")
    sourceMetadata.progUrl = metadata.progUrl
    sourceMetadata.streamFormat = "progressive"
  end if
  return sourceMetadata
end function

' ===== HELPER METHODS =====

sub finishRunningSampleForCustomDataUpdate()
  setVideoTimeEnd()
  stateDuration = m.playerStateTimer.TotalMilliseconds()

  if m.currentState = m.collectorStates.PLAYING
    sendAnalyticsRequestAndClearValues({ played: stateDuration }, stateDuration, m.currentState)
    m.playerStateTimer.Mark()
    setVideoTimeStart()
  else if m.currentState = m.collectorStates.PAUSED
    if m.isBuffering
      sample = { videoTimeStart: m.currentTimeAtPauseStart, buffered: stateDuration }
      sendAnalyticsRequestAndClearValues(sample, stateDuration, m.currentState)
    else
      sendAnalyticsRequestAndClearValues({ paused: stateDuration }, stateDuration, m.currentState)
    end if
    m.playerStateTimer.Mark()
    setVideoTimeStart()
  end if
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

sub detectSourceFormat()
  source = getActiveSource(m.player)
  if source = invalid then return

  updateSample(mapSource(source))
end sub

function getActiveSource(player)
  if player = invalid or player.source = invalid then return invalid

  sources = player.source.sources
  if sources = invalid or sources.Count() = 0 then return invalid

  return sources[0]
end function

function mapSource(source)
  if source = invalid or source.type = invalid then return {}

  if source.type = "application/x-mpegURL"
    return { streamFormat: "hls", m3u8Url: source.src }
  else if source.type = "application/dash+xml"
    return { streamFormat: "dash", mpdUrl: source.src }
  else if source.type = "theolive"
    return { streamFormat: "hls", m3u8Url: source.src }
  else
    return { streamFormat: "progressive", progUrl: source.src }
  end if
end function

sub decorateSampleWithPlaybackData(sampleData)
  if sampleData = invalid then return

  if m.videoNode <> invalid
    sampleData.Append(getVideoWindowSize(m.videoNode))
    sampleData.Append({ size: getSizeType(sampleData.videoWindowHeight, sampleData.videoWindowWidth) })
  end if

  ' Set audio language
  currentAudioLanguage = getCurrentAudioLanguage(m.player.audioTracks)
  if currentAudioLanguage <> invalid then sampleData.Append({ audioLanguage: currentAudioLanguage })

  ' Set subtitle language
  currentSubtitleTrack = getCurrentSubtitleLanguage(m.player.textTracks)
  if currentSubtitleTrack <> invalid then sampleData.Append({ subtitleLanguage: currentSubtitleTrack })

  ' Set subtitle enabled
  sampleData.Append({ subtitleEnabled: getDeviceSubtitlesEnabled() })

  ' Set video duration
  sampleData.Append({ videoDuration: getVideoDuration() })
end sub

function getCurrentAudioLanguage(audioTracks)
  if audioTracks = invalid or audioTracks.Count() = 0 then return invalid

  for each audioTrack in audioTracks
    if audioTrack.enabled then return audioTrack.language
  end for

  return invalid
end function

function getCurrentSubtitleLanguage(textTracks)
  if textTracks = invalid or textTracks.Count() = 0 then return invalid

  for each textTrack in textTracks
    if textTrack.mode = "showing" then return textTrack.language
  end for

  return invalid
end function

function getDeviceSubtitlesEnabled()
  return m.deviceInfo.GetCaptionsMode() = "On"
end function

function getVideoDuration()
  duration = m.player.duration
  if duration <> invalid then duration = duration * 1000

  return duration
end function

function updateSample(sampleData)
  if sampleData = invalid return false

  return m.collectorCore.callFunc("updateSample", sampleData)
end function

sub sendAnalyticsRequestAndClearValues(eventData, duration, state = m.previousState, skipHeartbeatReset = false)
  sampleData = eventData
  sampleData.Append({
    state: state,
    duration: duration,
    time: getCurrentTimeInMilliseconds()
  })
  decorateSampleWithPlaybackData(sampleData)

  updateSample(sampleData)
  m.collectorCore.callFunc("sendAnalyticsRequestAndClearValues", skipHeartbeatReset)
end sub

sub setUpObservers()
  m.player.callFunc("addEventListener", m.player.Event.play, m.top, "onPlay")
  m.player.callFunc("addEventListener", m.player.Event.playing, m.top, "onPlaying")
  m.player.callFunc("addEventListener", m.player.Event.pause, m.top, "onPause")
  m.player.callFunc("addEventListener", m.player.Event.sourcechange, m.top, "onSourceChange")
  m.player.callFunc("addEventListener", m.player.Event.destroy, m.top, "onDestroy")
  m.player.callFunc("addEventListener", m.player.Event.seeking, m.top, "onSeeking")
  m.player.callFunc("addEventListener", m.player.Event.timeupdate, m.top, "onTimeUpdate")
  m.player.callFunc("addEventListener", m.player.Event.error, m.top, "onError")

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")

  if m.videoNode <> invalid
    m.videoNode.observeFieldScoped("state", "onVideoNodeStateChanged")
  end if

  setUpQualityChangeObserver()
  setUpCsaiAdObservers()
end sub

sub setUpQualityChangeObserver()
  if m.player.Event <> invalid and m.player.Event.activequalitychanged <> invalid
    m.player.callFunc("addEventListener", m.player.Event.activequalitychanged, m.top, "onActiveQualityChanged")
  else
    m.player.callFunc("addEventListener", m.player.Event.bitratechange, m.top, "onBitrateChange")
  end if
end sub

sub unobserveFields(isDestroy = false)
  if m.player <> invalid
    m.player.callFunc("removeEventListener", m.player.Event.play, m.top, "onPlay")
    m.player.callFunc("removeEventListener", m.player.Event.playing, m.top, "onPlaying")
    m.player.callFunc("removeEventListener", m.player.Event.pause, m.top, "onPause")
    m.player.callFunc("removeEventListener", m.player.Event.sourcechange, m.top, "onSourceChange")
    m.player.callFunc("removeEventListener", m.player.Event.destroy, m.top, "onDestroy")
    m.player.callFunc("removeEventListener", m.player.Event.seeking, m.top, "onSeeking")
    m.player.callFunc("removeEventListener", m.player.Event.timeupdate, m.top, "onTimeUpdate")
    m.player.callFunc("removeEventListener", m.player.Event.error, m.top, "onError")

    if m.player.Event.activequalitychanged <> invalid then
      m.player.callFunc("removeEventListener", m.player.Event.activequalitychanged, m.top, "onActiveQualityChanged")
    end if

    if m.player.Event.bitratechange <> invalid then
      m.player.callFunc("removeEventListener", m.player.Event.bitratechange, m.top, "onBitrateChange")
    end if

  end if

  if m.collectorCore <> invalid
    m.collectorCore.unobserveFieldScoped("fireHeartbeat")
  end if

  if m.videoNode <> invalid
    m.videoNode.unobserveFieldScoped("state")
  end if

  tearDownCsaiAdObservers()
end sub

sub onHeartbeat()
  if m.isSeeking = true then return

  setVideoTimeEnd()

  duration = getDuration(m.playerStateTimer)
  m.playerStateTimer.Mark()

  eventData = {
    played: duration
  }

  sendAnalyticsRequestAndClearValues(eventData, duration, m.currentState)
  setVideoTimeStart()
end sub

sub startVideoStartUpTimer()
  m.videoStartupTimer = CreateObject("roTimeSpan")
end sub

sub stopVideoStartUpTimer()
  if m.videoStartupTimer = invalid or m.videoStartUpTime >= 0 then return

  m.videoStartUpTime = m.videoStartupTimer.TotalMilliseconds()

  startupEventData = {
    videoStartupTime: m.videoStartUpTime,
    startupTime: m.videoStartUpTime
  }

  sendAnalyticsRequestAndClearValues(startupEventData, m.videoStartUpTime, "startup")
end sub

sub trackVideoStart()
  if m.didVideoPlay = false
    m.didVideoPlay = true
    clearVideoStartTimeout()
  end if
end sub

sub startVideoStartTimeout()
  m.videoStartTimeoutTimer.observeFieldScoped("fire", "onVideoStartTimeout")
  m.videoStartTimeoutTimer.control = "start"
end sub

sub clearVideoStartTimeout()
  m.videoStartTimeoutTimer.unobserveFieldScoped("fire")
  m.videoStartTimeoutTimer.control = "stop"
end sub

sub onVideoStartTimeout()
  durationMilliseconds = m.videoStartTimeoutTimer.duration * 1000
  clearVideoStartTimeout()
  sendVideoStartError(m.videoStartFailedEvents.Timeout, durationMilliseconds, "error")
end sub

sub sendVideoStartError(reason, duration, state, additionalEventData = invalid)
  if reason = invalid return

  eventData = {}
  if additionalEventData <> invalid then eventData.Append(additionalEventData)

  eventData.Append({
    videoStartFailed: true,
    videoStartFailedReason: reason
  })

  sendAnalyticsRequestAndClearValues(eventData, duration, state)
end sub

' ===== Player event callbacks =====

sub onSourceChange(eventData = invalid)
  clearVideoStartTimeout()

  sourceChangedFromInitialOne = m.currentState <> m.collectorStates.SETUP
  if sourceChangedFromInitialOne
    sendClosingSampleForCurrentState()
    m.collectorCore.callFunc("setupSample") ' new analytics impression
    resetCollectorState()
  end if

  detectSourceFormat()
  applyPendingMetadata()
end sub

sub onPlay(eventData = invalid)
  startVideoStartUpTimer()

  if m.didAttemptPlay = false and m.didVideoPlay = false then startVideoStartTimeout()
  m.didAttemptPlay = true
end sub

sub onPlaying(eventData = invalid)
  stopVideoStartUpTimer()
  trackVideoStart()

  if m.currentState = m.collectorStates.PLAYING then return

  onPlayerStateChanged(m.collectorStates.PLAYING)
  m.isBuffering = false
end sub

sub onPause(eventData = invalid)
  if m.player.seeking then return
  if m.collectorCore.callFunc("isCsaiAdBreakInProgress") then return

  ' save currentTime in case pause is due to a seek
  m.currentTimeAtPauseStart = getCurrentPlayerTimeInMs()

  onPlayerStateChanged(m.collectorStates.PAUSED)
end sub

sub onActiveQualityChanged(eventData = invalid)
  if eventData = invalid then return

  processQualityChangeEvent(eventData.quality)
end sub

sub onBitrateChange(eventData = invalid)
  if eventData = invalid then return

  processQualityChangeEvent(eventData.bitrate)
end sub

sub processQualityChangeEvent(newBitrate)
  if newBitrate = invalid then return

  m.currentVideoBitrate = newBitrate

  ' Send qualityChange sample only if the player is currently playing, otherwise only update the bitrate in the sample
  ' Note: on the initial bitratechange event the player is not playing yet

  if m.currentState = m.collectorStates.PLAYING
    ' send playing state sample for the previous bitrate
    setVideoTimeEnd()
    stateDuration = m.playerStateTimer.TotalMilliseconds()
    sendAnalyticsRequestAndClearValues({ played: stateDuration }, stateDuration, m.currentState)
    m.playerStateTimer.Mark()
    setVideoTimeStart()

    ' send qualityChange change sample
    sample = {
      videoBitrate: m.currentVideoBitrate,
      videoTimeStart: getCurrentPlayerTimeInMs(),
      videoTimeEnd: getCurrentPlayerTimeInMs()
    }
    sendAnalyticsRequestAndClearValues(sample, 0, "qualityChange")
  end if

  updateSample({ videoBitrate: m.currentVideoBitrate })

end sub

sub onError(eventData = invalid)
  setVideoTimeEnd()

  errorCode = invalid
  errorMessage = invalid

  if eventData <> invalid and eventData.errorObject <> invalid
    errorCode = eventData.errorObject.code
    errorMessage = eventData.errorObject.cause
  end if

  m.top.error = {
    error: {
      code: errorCode,
      message: errorMessage,
      severity: m.errorSeverities.critical
    },
    errorContext: {
      originalError: eventData
    }
  }

  ' If an error occurs during an active CSAI ad, also track it as an ad error
  m.collectorCore.callFunc("csaiOnAdError", { errorCode: errorCode, errorMessage: errorMessage })

  transformedError = m.top.error.error
  errorSample = {
    errorCode: transformedError.code,
    errorMessage: transformedError.message,
    errorSeverity: transformedError.severity,
    errorData: FormatJson(eventData)
  }

  if m.didAttemptPlay = true and m.didVideoPlay = false
    duration = getDuration(m.playerStateTimer)
    clearVideoStartTimeout()
    sendVideoStartError(m.videoStartFailedEvents.PlayerError, duration, "error", errorSample)
  else
    sendAnalyticsRequestAndClearValues(errorSample, 0, "error")
  end if

  m.collectorCore.callFunc("onError", errorSample)
end sub

sub onDestroy(eventData = invalid)
  destroy()
end sub

sub onTimeUpdate(eventData = invalid)
  if m.player.seeking then return

  m.lastKnownCurrentTime = eventData.currentTime
end sub

sub onPlayerStateChanged(newState)
  transitionToState(newState)
  m.collectorCore.playerState = m.currentState

  setVideoTimeEnd()
  handlePreviousState()
  m.playerStateTimer.Mark()
  setVideoTimeStart()
end sub

sub transitionToState(nextState)
  m.previousState = m.currentState
  m.currentState = nextState
end sub

sub handlePreviousState()
  ' conclude previous state

  stateDuration = m.playerStateTimer.TotalMilliseconds()

  if m.previousState = m.collectorStates.PLAYING
    ' PLAYING → any
    sample = { played: stateDuration }

    if m.currentState = m.collectorStates.SEEKING
      ' If we are entering seeking state the currentTime is already updated to the seek-target and thus the default
      ' videoTimeEnd of the sample for previous state would be wrong. We need to use the currentTime at the start of the
      ' seek as videoTimeEnd for the playing state.
      sample.videoTimeEnd = Cint(m.seekStartPosition * 1000)
    end if

    sendAnalyticsRequestAndClearValues(sample, stateDuration, m.previousState)
  else if m.previousState = m.collectorStates.PAUSED
    ' A paused state can mean multiple things as the player pauses during UI seek and buffering, possibilities are:
    ' 1) user-initiated pause (current time does not change during paused state)
    ' 2) UI-initiated seek (current time changes during paused state)
    ' 3) buffering (current time does not change but player signals buffering during paused state)

    if m.currentState = m.collectorStates.SEEKING
      ' PAUSED → SEEKING
      ' API seek while paused — just conclude the paused state
      sendAnalyticsRequestAndClearValues({ paused: stateDuration }, stateDuration, m.previousState)
    else if m.currentState = m.collectorStates.PLAYING
      ' PAUSED → PLAYING
      currentTime = getCurrentPlayerTimeInMs()

      if (m.currentTimeAtPauseStart <> currentTime)
        ' UI seek as current time changed during paused state w/o seeking event - signal seeking
        ' Note: This detection is needed because with seeks through the UI, the player does not always fire a seeking. But
        ' it does get paused before seeking so we can detect a seek when exiting paused state.
        sample = { videoTimeStart: m.currentTimeAtPauseStart, seeked: stateDuration }
        sendAnalyticsRequestAndClearValues(sample, stateDuration, "seeking")
      else if m.isBuffering
        ' buffering was signaled during paused state
        sample = { videoTimeStart: m.currentTimeAtPauseStart, buffered: stateDuration }
        sendAnalyticsRequestAndClearValues(sample, stateDuration, "buffering")
      else
        sendAnalyticsRequestAndClearValues({ paused: stateDuration }, stateDuration, m.previousState)
      end if
    end if
  else if m.previousState = m.collectorStates.SEEKING
    ' SEEKING → any
    sample = {
      videoTimeStart: Cint(m.seekStartPosition * 1000),
      seeked: stateDuration
    }
    sendAnalyticsRequestAndClearValues(sample, stateDuration, m.previousState)
    resetSeekHelperVariables()
  else if m.previousState = m.collectorStates.AD
    ' AD → any (ad finished or next ad started)
    sendAnalyticsRequestAndClearValues({ played: stateDuration }, stateDuration, m.previousState)
    if m.currentState <> m.collectorStates.AD
      updateSample({ videoBitrate: m.currentVideoBitrate })
    end if
  end if
end sub

sub sendClosingSampleForCurrentState()
  setVideoTimeEnd()
  stateDuration = m.playerStateTimer.TotalMilliseconds()

  if m.currentState = m.collectorStates.PLAYING
    sendAnalyticsRequestAndClearValues({ played: stateDuration }, stateDuration, m.currentState)
  else if m.currentState = m.collectorStates.PAUSED
    if m.isBuffering
      sample = { videoTimeStart: m.currentTimeAtPauseStart, buffered: stateDuration }
      sendAnalyticsRequestAndClearValues(sample, stateDuration, "buffering")
    else
      sendAnalyticsRequestAndClearValues({ paused: stateDuration }, stateDuration, m.currentState)
    end if
  else if m.currentState = m.collectorStates.AD
    sendAnalyticsRequestAndClearValues({ played: stateDuration }, stateDuration, m.currentState)
  end if

  m.playerStateTimer.Mark()
end sub

function getCurrentPlayerTimeInMs()
  currentTime = m.player.currentTime
  if currentTime = invalid then return 0

  time% = currentTime * 1000
  return Cint(time%)
end function

sub setVideoTimeStart()
  m.collectorCore.callFunc("setVideoTimeStart", getCurrentPlayerTimeInMs())
end sub

sub setVideoTimeEnd()
  m.collectorCore.callFunc("setVideoTimeEnd", getCurrentPlayerTimeInMs())
end sub

sub onSeeking(eventData = invalid)
  if m.isSeeking = true or m.currentState = m.collectorStates.SETUP then return

  m.isSeeking = true

  ' At the time when we receive the seeking event, the player has already updated the `currentTime` to the
  ' seek-target. Thus we need to rely on our last tracked `currentTime` to get an approximate starting position.
  m.seekStartPosition = m.lastKnownCurrentTime

  onPlayerStateChanged(m.collectorStates.SEEKING)
end sub

sub resetSeekHelperVariables()
  m.isSeeking = false
  m.seekStartPosition = invalid
end sub

sub resetCollectorState()
  m.previousState = ""
  m.currentState = m.collectorStates.SETUP

  m.didAttemptPlay = false
  m.didVideoPlay = false
  m.videoStartupTimer = invalid
  m.videoStartUpTime = -1

  m.currentVideoBitrate = invalid
  m.isBuffering = false
  m.isSeeking = false
  m.seekStartPosition = invalid
  m.currentTimeAtPauseStart = invalid
  m.lastKnownCurrentTime = 0
end sub

sub onVideoNodeStateChanged()
  if m.videoNode = invalid or m.currentState = m.collectorStates.SETUP then return

  state = m.videoNode.state

  if state = "buffering"
    m.isBuffering = true
  end if
end sub

' ====== CSAI related ad observers and callbacks ======

sub setUpCsaiAdObservers()
  if m.player.ads = invalid then return

  adEvents = m.player.ads.events
  if adEvents = invalid then return

  m.player.ads.callFunc("addEventListener", adEvents.adbreakbegin, m.top, "onAdBreakBegin")
  m.player.ads.callFunc("addEventListener", adEvents.adbegin, m.top, "onAdBegin")
  m.player.ads.callFunc("addEventListener", adEvents.adend, m.top, "onAdEnd")
  m.player.ads.callFunc("addEventListener", adEvents.adbreakend, m.top, "onAdBreakEnd")
  m.player.ads.callFunc("addEventListener", adEvents.adfirstquartile, m.top, "onAdFirstQuartile")
  m.player.ads.callFunc("addEventListener", adEvents.admidpoint, m.top, "onAdMidpoint")
  m.player.ads.callFunc("addEventListener", adEvents.adthirdquartile, m.top, "onAdThirdQuartile")
  m.player.ads.callFunc("addEventListener", adEvents.aderror, m.top, "onAdError")
end sub

sub tearDownCsaiAdObservers()
  if m.player = invalid or m.player.ads = invalid then return

  adEvents = m.player.ads.events
  if adEvents = invalid then return

  m.player.ads.callFunc("removeEventListener", adEvents.adbreakbegin, m.top, "onAdBreakBegin")
  m.player.ads.callFunc("removeEventListener", adEvents.adbegin, m.top, "onAdBegin")
  m.player.ads.callFunc("removeEventListener", adEvents.adend, m.top, "onAdEnd")
  m.player.ads.callFunc("removeEventListener", adEvents.adbreakend, m.top, "onAdBreakEnd")
  m.player.ads.callFunc("removeEventListener", adEvents.adfirstquartile, m.top, "onAdFirstQuartile")
  m.player.ads.callFunc("removeEventListener", adEvents.admidpoint, m.top, "onAdMidpoint")
  m.player.ads.callFunc("removeEventListener", adEvents.adthirdquartile, m.top, "onAdThirdQuartile")
  m.player.ads.callFunc("removeEventListener", adEvents.aderror, m.top, "onAdError")
end sub

sub onAdBreakBegin(eventData = invalid)
  adBreak = invalid
  if eventData <> invalid then adBreak = eventData.adBreak
  print m.tag; "onAdBreakBegin: timeOffset="; adBreak?.timeOffset; " maxDuration="; adBreak?.maxDuration
  updateSample({ videoBitrate: invalid })
  m.collectorCore.callFunc("csaiOnAdBreakBegin", adBreak)
end sub

sub onAdBegin(eventData = invalid)
  ad = invalid
  if eventData <> invalid then ad = eventData.ad
  print m.tag; "onAdBegin: id="; ad?.id; " duration="; ad?.duration
  m.collectorCore.callFunc("csaiOnAdBegin", ad)
  onPlayerStateChanged(m.collectorStates.AD)
end sub

sub onAdEnd(eventData = invalid)
  ad = invalid
  if eventData <> invalid then ad = eventData.ad
  print m.tag; "onAdEnd: id="; ad?.id
  m.collectorCore.callFunc("csaiOnAdEnd", ad)
end sub

sub onAdBreakEnd(eventData = invalid)
  print m.tag; "onAdBreakEnd"
  m.collectorCore.callFunc("csaiOnAdBreakEnd")
end sub

sub onAdFirstQuartile(eventData = invalid)
  print m.tag; "onAdFirstQuartile"
  m.collectorCore.callFunc("csaiOnAdFirstQuartile")
end sub

sub onAdMidpoint(eventData = invalid)
  print m.tag; "onAdMidpoint"
  m.collectorCore.callFunc("csaiOnAdMidpoint")
end sub

sub onAdThirdQuartile(eventData = invalid)
  print m.tag; "onAdThirdQuartile"
  m.collectorCore.callFunc("csaiOnAdThirdQuartile")
end sub

sub onAdError(eventData = invalid)
  errorCode = invalid
  errorMessage = invalid
  if eventData <> invalid
    if eventData.errcode <> invalid then errorCode = Val(eventData.errcode)
    if eventData.errmsg <> invalid then errorMessage = eventData.errmsg
  end if
  m.collectorCore.callFunc("csaiOnAdError", { errorCode: errorCode, errorMessage: errorMessage })
end sub

' ====== SSAI related ad callbacks ======

function adBreakStart(adBreakMetadata = invalid)
  m.collectorCore.callFunc("adBreakStart", adBreakMetadata)
end function

function adStart(adMetadata = invalid)
  m.collectorCore.callFunc("adStart", adMetadata)
end function

function adBreakEnd()
  m.collectorCore.callFunc("adBreakEnd")
end function

'Function to report that an `adQuartile` has been reached during an SSAI-based ad.
'@param {String} adQuartile - The adQuartile to be reported. Values can either be `"first'`, `"midpoint"`, `"third"` or `"completed"`.
'@param {Object} adQuartileMetadata - Metadata to be reported with the `adQuartile`. Can currently only contain a `failedBeaconUrl` to indicate that pinging a related beacon was not successful.
function adQuartileFinished(adQuartile, adQuartileMetadata = invalid)
  m.collectorCore.callFunc("adQuartileFinished", adQuartile, adQuartileMetadata)
end function
