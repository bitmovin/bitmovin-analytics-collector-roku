sub init()
  m.tag = "[bitmovinPlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
  m.playerStateTimer = CreateObject("roTimespan")
  m.appInfo = CreateObject("roAppInfo")
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player
  m.deviceInfo = CreateObject("roDeviceInfo")
  updateSample({"playerStartupTime": 1})
  updateSample({"playerKey": getPlayerKeyFromManifest(m.appInfo)})

  setUpHelperVariables()
  setUpObservers()

  m.previousState = ""
  m.currentState = player.playerState
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "bitmovin",
    version: "unknown"
  }
  updateSampleDataAndSendAnalyticsRequest(playerData)
end sub

sub setUpObservers()
  m.player.observeFieldScoped("sourceLoaded", "onSourceChanged")
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
  if m.player = invalid or m.collectorCore = invalid then return

  m.player.unobserveFieldScoped("sourceLoaded")
  m.player.unobserveFieldScoped("state")
  m.player.unobserveFieldScoped("seek")
  m.player.unobserveFieldScoped("seeked")

  m.collectorCore.unobserveFieldScoped("fireHeartbeat")


  m.player.unobserveFieldScoped("play")
  m.player.unobserveFieldScoped("sourceLoaded")
  m.player.unobserveFieldScoped("sourceUnloaded")

  m.collectorCore.unobserveFieldScoped("error")
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
  setPreviousAndCurrentPlayerState()
  m.collectorCore.playerState = m.currentState

  handlePreviousState()
  handleCurrentState()

  m.playerStateTimer.Mark()
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
  newSampleData = getClearSampleData()

  newSampleData.Append(getCommonSampleData(m.playerStateTimer, m.previousState))
  newSampleData.played = m.playerStateTimer.TotalMilliseconds()

  updateSampleDataAndSendAnalyticsRequest(newSampleData)
end sub

function wasSeeking()
  return m.seekTimer <> invalid
end function

sub onPause()
  ' The video node does not have a seeking state, because of that we have to assume that on pause is the beginning of a seek operation until proven otherwise
  m.alreadySeeking = true
  m.seekStartPosition = m.player.position
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onPaused()
  ' If we did not change from the pause state to playing that means a seek is happening
  if m.currentState <> m.playerStates.PLAYING then return

  newSampleData = getClearSampleData()

  newSampleData.Append(getCommonSampleData(m.seekTimer, m.previousState))
  newSampleData.paused = m.playerStateTimer.TotalMilliseconds()

  updateSampleDataAndSendAnalyticsRequest(newSampleData)
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

  newSampleData = getClearSampleData()

  newSampleData.Append(getCommonSampleData(m.bufferTimer, m.previousState))
  newSampleData.buffered = m.bufferTimer.TotalMilliseconds()

  updateSampleDataAndSendAnalyticsRequest(newSampleData)

  m.bufferTimer = invalid
end sub

sub onHeartbeat()
  finishRunningSample()
end sub

sub setPreviousAndCurrentPlayerState()
  m.previousState = m.currentState
  m.currentState = m.player.playerState
end sub

'Return the video window size as reported by the video element of the player.
'@return {Object} - Object containing videoWindowHeight and videoWindowWidth as required by the analytics sample.
function getVideoWindowSize()
  video = m.player.getChild(0)
  height = m.deviceInfo.GetDisplaySize().h
  width = m.deviceInfo.GetDisplaySize().w
  if video.height <> 0
    height = video.height
  end if
  if video.width <> 0
    width = video.width
  end if
  return {videoWindowHeight: height, videoWindowWidth: width}
end function

sub decorateSampleWithPlaybackData(sampleData)
  if sampleData = invalid then return

  sampleData.Append(getVideoWindowSize())
  sampleData.Append({size: getSizeType(sampleData.videoWindowHeight, sampleData.videoWindowWidth, m.deviceInfo)})
end sub

function getClearSampleData()
  sampleData = {}
  sampleData.Append(getDefaultStateTimeData())

  return sampleData
end function

function getCommonSampleData(timer, state)
  commonSampleData = {}

  if timer <> invalid and state <> invalid
    commonSampleData.duration = getDuration(timer)
    commonSampleData.state = state
    commonSampleData.time = getCurrentTimeInMilliseconds()
  end if

  return commonSampleData
end function

sub updateSampleDataAndSendAnalyticsRequest(sampleData)
  decorateSampleWithPlaybackData(sampleData)

  m.collectorCore.callFunc("updateSampleAndSendAnalyticsRequest", sampleData)
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(sampleData)
  decorateSampleWithPlaybackData(sampleData)

  m.collectorCore.callFunc("createTempMetadataSampleAndSendAnalyticsRequest", sampleData)
end sub

function updateSample(sampleData)
  if sampleData = invalid return false

  return m.collectorCore.callFunc("updateSample", sampleData)
end function

sub onSeek()
  if m.alreadySeeking = true then return

  m.alreadySeeking = true
  m.seekStartPosition = m.player.position
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onSeeked()
  newSampleData = getClearSampleData()

  newSampleData.Append(getCommonSampleData(m.seekTimer, m.previousState))
  newSampleData.seeked = m.seekTimer.TotalMilliseconds()
  newSampleData.state = "seeking" ' Manually override the state since the video node does not have a `seeking` state

  updateSampleDataAndSendAnalyticsRequest(newSampleData)

  resetSeekHelperVariables()
end sub

sub onVideoStart()
  stopVideoStartUpTimer()
end sub

sub onSourceChanged()
  checkForNewMetadata()
  handleImpressionIdChange()
end sub

sub handleImpressionIdChange()
  updateSample({impressionId: getImpressionIdForSample()})
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
  newSampleData = getClearSampleData()
  errorSample = {
    errorCode: m.player.error.code,
    errorMessage: m.player.error.message,
    errorSegments: []
  }

  if m.player.downloadFinished <> invalid then errorSample.errorSegments.push(m.player.downloadFinished)

  resetSeekHelperVariables()

  newSampleData.Append(errorSample)
  updateSampleDataAndSendAnalyticsRequest(newSampleData)
end sub

function setCustomData(customData)
  if customData = invalid then return invalid
  finishRunningSample()

  return updateSample(customData)
end function

sub finishRunningSample()
  setPreviousAndCurrentPlayerState()
  runningSampleData = getClearSampleData()
  runningSampleData.Append(getCommonSampleData(m.playerStateTimer, m.previousState))
  m.playerStateTimer.Mark()

  updateSampleDataAndSendAnalyticsRequest(runningSampleData)
end sub

sub setCustomDataOnce(customData)
  if customData = invalid then return
  finishRunningSample()

  sendOnceCustomData = getClearSampleData()
  sendOnceCustomData.Append(getCommonSampleData(m.playerStateTimer, m.previousState))
  sendOnceCustomData.Append(customData)

  createTempMetadataSampleAndSendAnalyticsRequest(sendOnceCustomData)
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
  updateSampleDataAndSendAnalyticsRequest({"videoStartupTime": m.videoStartupTime})
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
