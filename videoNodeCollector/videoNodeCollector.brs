sub init()
  m.tag = "[videoNodeCollector] "
  initializeCollectorCore()
end sub

sub  initializeCollectorCore()
  m.collectorCore = CreateObject("roSGNode", "collectorCore")
  m.collectorCore.id = "collectorCore"
  m.top.collectorReady = true
end sub

sub initializePlayer(player)
  m.player = player
  m.previousState = ""
  m.currentState = player.state
  m.player.observeField("state", "onPlayerStateChanged")
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  playerData = {
    player: "Roku",
    playerTech: "native",
    version: invalid
  }
  updateSampleData(playerData)
end sub

sub updateSampleData(sampleData)
  m.collectorCore.callFunc("updateSample", sampleData)
end sub

sub onPlayerStateChanged()
  m.previousState = m.currentState
  m.currentState = m.player.state
  print m.tag; "State change: "; m.previousState; " --> "; m.currentState

  if m.player.state = "none"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "buffering"
  ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "playing"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "paused"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "stopped"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "finished"
    ' print m.tag; "Player event caught "; m.player.state
  else if m.player.state = "error"
      ' print m.tag; "Player event caught "; m.player.state
  end if

  m.previousTimestamp = m.currentTimestamp
  m.currentTimestamp = getCurrentTimeInMilliseconds()
  duration = getDuration(m.currentTimestamp, m.previousTimestamp)

  stateChangedData = {
    duration: duration,
    state: m.previousState,
    time: m.currentTimestamp.ToStr()
  }
  updateSampleData(stateChangedData)
  sendAnalyticsRequest()
end sub

sub sendAnalyticsRequest()
  ' Collect all the necessary data here and call the collector core's method
  ' m.collectorCore.callFunc("sendAnalyticsRequest", data)

  m.collectorCore.callFunc("sendAnalyticsRequest")
end sub

  ' Utility functions
function getCurrentTimeInMilliseconds()
  dateTime = CreateObject("roDateTime")
  return dateTime.AsSeconds().ToStr() + "000"
end function

function getCurrentTimeInSeconds()
  dateTime = CreateObject("roDateTime")
  return dateTime.AsSeconds()
end function

function getDuration(currentTimestamp, previousTimestamp)
  if currentTimestamp = invalid or previousTimestamp = invalid
    return invalid
  end if

  return (currentTimestamp - previousTimeStamp).ToStr()
end function