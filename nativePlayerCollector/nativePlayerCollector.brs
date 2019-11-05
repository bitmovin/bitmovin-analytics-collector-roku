sub init()
  m.tag = "[nativePlayerCollector] "
  m.changeImpressionId = false
  m.collectorCore = m.top.findNode("collectorCore")
  m.playerStates = getPlayerStates()
  m.playerStateTimer = CreateObject("roTimespan")
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player
  updateSampleDataAndSendAnalyticsRequest({"playerStartupTime": 1}, false)

  setUpObservers()
  setUpHelperVariables()

  m.player.observeFieldScoped("content", "onSourceChanged")
  m.player.observeFieldScoped("contentIndex", "onSourceChanged")
  m.previousState = ""
  m.currentState = player.state
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "native",
    version: "unknown"
  }
  updateSampleDataAndSendAnalyticsRequest(playerData, false)
end sub

sub setUpObservers()
  m.player.observeFieldScoped("state", "onPlayerStateChanged")
  m.collectorCore.observeFieldScoped("fireHeartBeat", "onHeartBeat")
  m.player.observeFieldScoped("seek", "onSeek")

  m.player.observeFieldScoped("control", "onControlChanged")
end sub

sub unobserveFields()
  if m.player = invalid then return

  m.player.unobserveFieldScoped("state")
  m.player.unobserveFieldScoped("seek")

  m.player.unobserveFieldScoped("control")
end sub

sub setUpHelperVariables()
  m.seekStartPosition = invalid
  m.alreadySeeking = false
end sub

sub onPlayerStateChanged()
  setPreviousAndCurrentPlayerState()
  m.collectorCore.playerState = m.currentState

  stateChangedData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates)
  m.playerStateTimer.Mark()

  if m.currentState = "playing"
    onSeeked()
    onVideoStart()
    if m.changeImpressionId = true
      stateChangedData.impressionId = m.collectorCore.callFunc("createImpressionId")
      m.changeImpressionId = false
    else
      stateChangedData.impressionId = m.collectorCore.callFunc("getCurrentImpressionId")
    end if
  else if m.currentState = "finished"
    m.changeImpressionId = true
  else if m.currentState = "paused"
    onSeek()
  else if m.currentState = "error"
    onError()
  end if

  updateSampleDataAndSendAnalyticsRequest(stateChangedData, false)
end sub

sub onHeartBeat()
  finishRunningSample(false)
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
    previousState = mapPlayerStateForAnalytic(possiblePlayerStates, state)
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

sub updateSampleDataAndSendAnalyticsRequest(sampleData, isSendOnceMetadata)
  if sampleData = invalid or isSendOnceMetadata = invalid then return

  m.collectorCore.callFunc("updateSampleAndSendAnalyticsRequest", sampleData, isSendOnceMetadata)
end sub

sub onSeek()
  if m.alreadySeeking = true then return

  m.alreadySeeking = true
  m.seekStartPosition = m.player.position
  m.seekTimer = createObject("roTimeSpan")
end sub

sub onSeeked()
  if m.seekStartPosition <> invalid and m.seekStartPosition <> m.player.position and m.seekTimer <> invalid
    updateSampleDataAndSendAnalyticsRequest({"seeked": m.seekTimer.TotalMilliseconds()}, false)
  end if

  m.alreadySeeking = false
  m.seekStartPosition = invalid
  m.seekTimer = invalid
end sub

sub onControlChanged()
  if m.player.control = "play"
    m.videoStartupTimer = createObject("roTimeSpan")
  end if
end sub

sub onVideoStart()
  if m.videoStartupTimer = invalid then return

  updateSampleDataAndSendAnalyticsRequest({"videoStartupTime": m.videoStartupTimer.TotalMilliseconds()}, false)

  m.videoStartupTimer = invalid
end sub

sub onSourceChanged()
  m.changeImpressionId = true
end sub

sub onError()
  errorSample = {
    errorCode: m.player.errorCode,
    errorMessage: m.player.errorMsg,
    errorSegments: []
  }

  if m.player.streamingSegment <> invalid then errorSample.errorSegments.push(m.player.streamingSegment)
  if m.player.downloadedSegment <> invalid then errorSample.errorSegments.push(m.player.downloadedSegment)

  updateSampleDataAndSendAnalyticsRequest(errorSample, false)
end sub

function setCustomData(customData)
  if customData = invalid then return invalid
  finishRunningSample(false)
  return m.collectorCore.callFunc("updateSample", customData)
end function

sub finishRunningSample(isSendOnceMetadata)
  setPreviousAndCurrentPlayerState()
  runningSampleData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates)
  m.playerStateTimer.Mark()
  updateSampleDataAndSendAnalyticsRequest(runningSampleData, isSendOnceMetadata)
end sub


sub setCustomDataOnce(customData)
  if customData = invalid then return
  finishRunningSample(false)
  sendOnceCustomData = createUpdatedSampleData(m.previousState, m.playerStateTimer, m.playerStates, customData)

  updateSampleDataAndSendAnalyticsRequest(sendOnceCustomData, true)
end sub
