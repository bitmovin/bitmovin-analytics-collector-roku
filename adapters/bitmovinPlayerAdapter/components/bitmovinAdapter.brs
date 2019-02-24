sub init()
  m.tag = "[bitmovinAdapter]"
  m.previousState = ""
  m.player = invalid
  m.top.adapterReady = false
  m.config = getAdapterConfig()

  m.collectorCoreLib = createObject("roSgNode", "componentLibrary")
  m.collectorCoreLib.id = "collectorCoreLib"
  m.collectorCoreLib.uri = m.config.dependencies.collectorCoreLib
  m.collectorCoreLib.observeField("loadStatus", "onCollectorCoreLoaded")

  m.collectorCoreLoadingTask = createObject("roSgNode", "Task")
  m.collectorCoreLoadingTask.appendChild(m.collectorCoreLib)
  m.top.appendChild(m.collectorCoreLoadingTask)
end sub

sub onCollectorCoreLoaded()
  print m.tag; "Load status for the collector core: "; m.collectorCoreLib.loadStatus
  if m.collectorCoreLib.loadStatus = "ready"
    m.collectorCore = createObject("roSgNode", "collectorCoreLib:collectorCore")
    m.collectorCore.id = "collectorCore"

    ' m.timer = createObject("roSgNode", "timer")
    ' m.timer.duration = 10
    ' m.top.appendChild(m.timer)
    ' m.timer.observeField("fire", "onThresholdReached")
    ' m.timer.control = "start"

    m.top.adapterReady = true
  end if
end sub

sub initializePlayer(player)
  m.player = player
  m.player.observeField("playerState", "onPlayerStateChanged")
end sub

sub onPlayerStateChanged()
  if m.player.playerState = "playing"
    appInfo = createObject("roAppInfo")
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "stalling"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "paused"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "finished"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "error"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "none"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "setup"
    print m.tag; "Adapter event caught "; m.player.playerState
  else if m.player.playerState = "ready"
    print m.tag; "Adapter event caught "; m.player.playerState
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
