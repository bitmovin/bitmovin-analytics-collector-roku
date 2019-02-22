sub init()
  m.tag = "[bitmovinAdapter]"
  m.previousState = ""
  m.player = invalid
  m.top.adapterReady = false
  m.top.findNode("loadCoreTask").findNode("core").observeField("loadStatus", "onCoreLoaded")
  print m.tag; m.top.findNode("loadCoreTask").findNode("core").loadStatus
end sub

sub onCoreLoaded()
  print m.tag; "Load status for the analytics core: "; m.top.findNode("loadCoreTask").findNode("core").loadStatus
  if m.top.findNode("loadCoreTask").findNode("core").loadStatus = "ready"
    m.bitmovinAnalyticsCore = createObject("roSgNode", "core:Collector")
    m.bitmovinAnalyticsCore.id = "core"

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
  ' Collect all the necessary data here and call the core's method
  ' m.bitmovinAnalyticsCore.callFunc("sendAnalyticsRequest", data)

  m.bitmovinAnalyticsCore.callFunc("sendAnalyticsRequest")
end sub
