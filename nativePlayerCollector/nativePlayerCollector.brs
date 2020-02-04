sub init()
  m.tag = "[nativePlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
  m.playerStateTimer = CreateObject("roTimespan")
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player
  m.deviceInfo = CreateObject("roDeviceInfo")
  updateSample({"playerStartupTime": 1})

  setUpHelperVariables()
  setUpObservers()

  m.previousState = ""
  m.currentState = player.state
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "native",
    version: "unknown"
  }
  updateSampleDataAndSendAnalyticsRequest(playerData)
end sub

sub setUpObservers()
  m.player.observeFieldScoped("content", "onSourceChanged")
  m.player.observeFieldScoped("state", "onPlayerStateChanged")
  m.player.observeFieldScoped("seek", "onSeek")

  m.player.observeFieldScoped("control", "onControlChanged")

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat")
end sub

sub unobserveFields()
  if m.player = invalid or m.collectorCore = invalid then return

  m.player.unobserveFieldScoped("content")
  m.player.unobserveFieldScoped("contentIndex")
  m.player.unobserveFieldScoped("state")
  m.player.unobserveFieldScoped("seek")

  m.player.unobserveFieldScoped("control")

  m.collectorCore.unobserveFieldScoped("fireHeartbeat")
end sub

sub setUpHelperVariables()
  m.seekStartPosition = invalid
  m.alreadySeeking = false

  m.newMetadata = invalid

  m.playerStates = getPlayerStates()
  m.playerControls = getPlayerControls()
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
    if wasSeeking() then onSeeked()
  else if m.currentState = m.playerStates.PAUSED
    onPause()
  else if m.currentState = m.playerStates.ERROR
    onError()
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

  resetBufferingTimer()
end sub

sub resetBufferingTimer()
  m.bufferTimer = invalid
end sub

sub onFinished()
  resetBufferingTimer()
  resetSeekHelperVariables()
end sub

sub onHeartbeat()
  finishRunningSample()
end sub

sub setPreviousAndCurrentPlayerState()
  m.previousState = m.currentState
  m.currentState = m.player.state
end sub

function getClearSampleData()
  sampleData = {}
  sampleData.Append(getDefaultStateTimeData())

  return sampleData
end function

function createUpdatedSampleData(state, timer, possiblePlayerStates, customData = invalid)
  if state = invalid or timer = invalid or possiblePlayerStates = invalid
    return invalid
  end if

  sampleData = {}
  sampleData.Append(getDefaultStateTimeData())
  sampleData.Append(getCommonSampleData(timer, state))
  if customData <> invalid
    sampleData.Append(customData)
  end if

  if state = possiblePlayerStates.PLAYING or state = possiblePlayerStates.PAUSED
    previousState = mapNativePlayerStateForAnalytic(possiblePlayerStates, state)
    sampleData[previousState] = sampleData.duration
  end if

  return sampleData
end function

sub decorateSampleWithPlaybackData(sampleData)
  if sampleData = invalid then return

  sampleData.Append(getVideoWindowSize(m.player))
  sampleData.Append({size: getSizeType(sampleData.videoWindowHeight, sampleData.videoWindowWidth)})
end sub

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
  newSampleData.state = m.playerStates.SEEKING ' Manually override the state since the video node does not have a `seeking` state

  updateSampleDataAndSendAnalyticsRequest(newSampleData)

  resetSeekHelperVariables()
end sub

sub onControlChanged()
  if m.player.control = m.playerControls.PLAY
    m.videoStartupTimer = createObject("roTimeSpan")
  end if
end sub

sub onVideoStart()
  if m.videoStartupTimer = invalid then return

  updateSampleDataAndSendAnalyticsRequest({"videoStartupTime": m.videoStartupTimer.TotalMilliseconds()})

  m.videoStartupTimer = invalid
end sub

function mapContent(content)
  if content.STREAMFORMAT = "dash"
    return { streamFormat: "dash", mpdUrl: content.URL }
  else if content.STREAMFORMAT = "hls"
    return { streamFormat: "hls", m3u8Url: content.URL }
  else if content.STREAMFORMAT = "smooth"
    return { streamFormat: "smooth"}
  else if content.STREAMFORMAT = "mp4"
    return { streamFormat: "mp4", progUrl: content.URL }
  else
    return {}
  end if
end function

sub onSourceChanged()
  newStreamMetadata = mapContent(m.player.content)
  setNewMetadata(newStreamMetadata)
  checkForNewMetadata()
  handleImpressionIdChange()
end sub

sub handleImpressionIdChange()
  if m.player.content.getChildCount() > 0
    m.player.unobserveFieldScoped("contentIndex")
    m.player.observeFieldScoped("contentIndex", "onSourceChanged")
  end if

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
    errorCode: m.player.errorCode,
    errorMessage: m.player.errorMsg,
    errorSegments: []
  }

  if m.player.streamingSegment <> invalid then errorSample.errorSegments.push(m.player.streamingSegment)
  if m.player.downloadedSegment <> invalid then errorSample.errorSegments.push(m.player.downloadedSegment)

  resetSeekHelperVariables()
  resetBufferingTimer()

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
  runningSampleData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates)
  m.playerStateTimer.Mark()

  updateSampleDataAndSendAnalyticsRequest(runningSampleData)
end sub

sub setCustomDataOnce(customData)
  if customData = invalid then return
  finishRunningSample()
  sendOnceCustomData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates, customData)

  createTempMetadataSampleAndSendAnalyticsRequest(sendOnceCustomData)
end sub

function setAnalyticsConfig(configData)
  if configData = invalid return invalid

  return updateSample(configData)
end function

function getImpressionIdForSample()
  return m.collectorCore.callFunc("createImpressionId")
end function
