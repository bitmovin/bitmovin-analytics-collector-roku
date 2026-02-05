sub init()
  m.tag = "[theoPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
  m.collectorStates = getCollectorStates()
  m.appInfo = CreateObject("roAppInfo")
  m.deviceInfo = CreateObject("roDeviceInfo")
end sub

' ===== PUBLIC METHODS =====

sub initializeAnalytics(config = invalid)
  m.collectorCore.callFunc("initializeAnalytics", config)
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player

  setUpObservers()

  eventData = {
    playerTech: "theo"
    version: getPlayerVersion()
    player: "theo"
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
  unobserveFields(true)

  if m.collectorCore <> invalid
    m.collectorCore.callFunc("internalDestroy", invalid)
  end if
end sub

function getPlayerVersion()
  return "theo-" + m.player.version
end function

function setAnalyticsConfig(config)
  if config = invalid then return invalid

  return m.collectorCore.callFunc("updateAnalyticsConfig", config)
end function

sub setNewMetadata(metadata = invalid)
  ' TODO: Implement (possibly extract into `baseCollector`)
end sub

function setCustomData(customData)
  ' TODO: Implement (possibly extract into `baseCollector`)
end function

sub setCustomDataOnce(customData)
  ' TODO: Implement (possibly extract into `baseCollector`)
end sub

' ===== HELPER METHODS =====

sub decorateSampleWithPlaybackData(sampleData)
  if sampleData = invalid then return

  videoNode = m.player.callFunc("getVideoNode")
  sampleData.Append(getVideoWindowSize(videoNode))
  sampleData.Append({ size: getSizeType(sampleData.videoWindowHeight, sampleData.videoWindowWidth) })

  ' Set audio language
  currentAudioLanguage = getCurrentAudioLanguage(m.player.audioTracks)
  if currentAudioLanguage <> invalid then sampleData.Append({ audioLanguage: currentAudioLanguage })

  ' Set subtitle language
  currentSubtitleTrack = getCurrentSubtitleLanguage(m.player.textTracks)
  if currentSubtitleTrack <> invalid then sampleData.Append({ subtitleLanguage: currentSubtitleTrack })

  ' Set subtitle enabled
  sampleData.Append({subtitleEnabled: getDeviceSubtitlesEnabled()})

  ' Set video duration
  sampleData.Append({videoDuration: getVideoDuration()})
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

sub setUpObservers()
  ' TODO: observe

  ' TODO: Implement `onHeartbeat`
  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")
end sub

sub unobserveFields(isDestroy = false)
  if m.player <> invalid
    ' TODO: unobserve
  end if

  if m.collectorCore <> invalid
    m.collectorCore.unobserveFieldScoped("fireHeartbeat")
  end if
end sub

' ===== Player event callbacks =====


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
