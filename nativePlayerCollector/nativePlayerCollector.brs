sub init()
  m.tag = "[nativePlayerCollector] "
  m.collectorCore = m.top.findNode("collectorCore")
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
    version: "unknown"
  }
  updateSampleData(playerData)
end sub

sub onPlayerStateChanged()
  m.previousState = m.currentState
  m.currentState = m.player.state
  'TODO remove the print statments, leave only code related to updating the sample

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
  duration = getDuration(m.currentTimestamp.toInt(), m.previousTimestamp.toInt())

  stateChangedData = {
    duration: duration,
    state: m.previousState,
    time: m.currentTimestamp.ToStr()
  }
  updateSampleData(stateChangedData)
end sub

sub updateSampleData(sampleData)
  m.collectorCore.callFunc("updateSample", sampleData)
end sub