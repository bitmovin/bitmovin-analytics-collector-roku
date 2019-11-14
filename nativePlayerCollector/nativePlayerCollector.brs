sub init()
  m.tag = "[nativePlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
  m.playerStateTimer = CreateObject("roTimespan")
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player
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
  stateChangedData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates)
  m.playerStateTimer.Mark()

  if m.currentState = m.playerStates.PLAYING
    onSeeked()
    onVideoStart()
  else if m.currentState = m.playerStates.PAUSED
    onSeek()
  else if m.currentState = m.playerStates.ERROR
    onError()
  end if

  updateSampleDataAndSendAnalyticsRequest(stateChangedData)
end sub

sub onHeartbeat()
  finishRunningSample()
end sub

sub setPreviousAndCurrentPlayerState()
  m.previousState = m.currentState
  m.currentState = m.player.state
end sub

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

function getCommonSampleData(timer, state)
  commonSampleData = {}

  if timer <> invalid and state <> invalid
    commonSampleData.duration = getDuration(timer)
    commonSampleData.state = state
    commonSampleData.time =  getCurrentTimeInMilliseconds()
  end if

  return commonSampleData
end function

sub updateSampleDataAndSendAnalyticsRequest(sampleData)
  m.collectorCore.callFunc("updateSampleAndSendAnalyticsRequest", sampleData)
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(sampleData)
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
  if m.seekStartPosition <> invalid and m.seekStartPosition <> m.player.position and m.seekTimer <> invalid
    updateSampleDataAndSendAnalyticsRequest({"seeked": m.seekTimer.TotalMilliseconds()})
  end if

  m.alreadySeeking = false
  m.seekStartPosition = invalid
  m.seekTimer = invalid
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

sub onSourceChanged()
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
  errorSample = {
    errorCode: m.player.errorCode,
    errorMessage: m.player.errorMsg,
    errorSegments: []
  }

  if m.player.streamingSegment <> invalid then errorSample.errorSegments.push(m.player.streamingSegment)
  if m.player.downloadedSegment <> invalid then errorSample.errorSegments.push(m.player.downloadedSegment)

  updateSampleDataAndSendAnalyticsRequest(errorSample)
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
