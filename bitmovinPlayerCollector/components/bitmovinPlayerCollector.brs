sub init()
  m.previousState = ""
  m.tag = "[bitmovinPlayerCollector] "
  m.player = invalid
  m.top.collectorReady = false
  m.config = getCollectorConfig()

  m.collectorCoreLib = CreateObject("roSgNode", "componentLibrary")
  m.collectorCoreLib.id = "collectorCoreLib"
  m.collectorCoreLib.uri = m.config.dependencies.collectorCoreLib
  m.collectorCoreLib.observeField("loadStatus", "onCollectorCoreLoaded")

  m.collectorCoreLoadingTask = CreateObject("roSgNode", "Task")
  m.collectorCoreLoadingTask.appendChild(m.collectorCoreLib)
  m.top.appendChild(m.collectorCoreLoadingTask)
end sub

sub onCollectorCoreLoaded()
  print m.tag; "Load status for the collector core: "; m.collectorCoreLib.loadStatus
  if m.collectorCoreLib.loadStatus = "ready"
    m.collectorCore = CreateObject("roSgNode", "collectorCoreLib:collectorCore")
    m.collectorCore.id = "collectorCore"

    ' m.timer = CreateObject("roSgNode", "timer")
    ' m.timer.duration = 10
    ' m.top.appendChild(m.timer)
    ' m.timer.observeField("fire", "onThresholdReached")
    ' m.timer.control = "start"

    m.top.collectorReady = true
  end if
end sub

sub initializePlayer(player)
  m.player = player
  m.player.observeField("playerState", "onPlayerStateChanged")

  updatePlayerData()
end sub

sub updatePlayerData()
  m.collectorCore.callFunc("updateSample", {
    player: "Bitmovin", 
    autoplay: "false", ' TODO: read from player
    playerKey: "7e9c8483-ea84-423e-b675-19cf31dec43a", ' TODO: read from player
    playerTech: "native",
    version: "1.1.0" ' TODO: read from player
  })
end sub

sub onPlayerStateChanged()
  if m.player.playerState = "playing"
    appInfo = CreateObject("roAppInfo")
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "stalling"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "paused"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "finished"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "error"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "none"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "setup"
    print m.tag; "Player event caught "; m.player.playerState
  else if m.player.playerState = "ready"
    print m.tag; "Player event caught "; m.player.playerState
  end if
end sub

' sub onThresholdReached()
'   print m.tag; "Threshold reached"
'   sendAnalyticsRequest()
'   m.timer.duration = 60
'   m.timer.control = "start"
' end sub

sub sendAnalyticsRequest()
  ' Collect all the necessary data here and call the collector core's method
  ' m.collectorCore.callFunc("sendAnalyticsRequest", data)

  m.collectorCore.callFunc("sendAnalyticsRequest")
end sub
