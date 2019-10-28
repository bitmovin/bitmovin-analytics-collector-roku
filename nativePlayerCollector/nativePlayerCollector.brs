sub init()
  m.tag = "[nativePlayerCollector] "
  m.changeImpressionId = false
  m.collectorCore = m.top.findNode("collectorCore")
end sub

sub initializePlayer(player)
  m.player = player
  m.player.observeFieldScoped("content", "onSourceChanged")
  m.player.observeFieldScoped("contentIndex", "onSourceChanged")
  m.previousState = ""
  m.currentState = player.state
  m.player.observeFieldScoped("state", "onPlayerStateChanged")
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "native",
    version: "unknown"
  }
  updateSampleData(playerData)
end sub

sub onPlayerStateChanged()
  m.previousState = m.currentState
  m.currentState = m.player.state
  stateChangedData = {}

  if m.player.state = "playing"
    if m.changeImpressionId = true
      stateChangedData.impressionId = m.collectorCore.callFunc("createImpressionId")
      m.changeImpressionId = false
    else
      stateChangedData.impressionId = m.collectorCore.callFunc("getCurrentImpressionId")
    end if
  else if m.player.state = "finished"
    m.changeImpressionId = true
  end if

  m.previousTimestamp = m.currentTimestamp
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  duration = getDuration(m.currentTimestamp, m.previousTimestamp)

  stateChangedData.duration = duration
  stateChangedData.state = m.previousState
  stateChangedData.time =  m.currentTimestamp

  updateSampleData(stateChangedData)
end sub

sub updateSampleData(sampleData)
  m.collectorCore.callFunc("updateSampleAndSendAnalyticsRequest", sampleData)
end sub

sub onSourceChanged()
  m.changeImpressionId = true
end sub