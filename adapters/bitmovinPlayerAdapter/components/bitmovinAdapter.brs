sub init()
  m.previousState = ""
  m.player = invalid
  m.top.adapterReady = false
  m.top.findNode("loadCoreTask").findNode("core").observeField("loadStatus", "onCoreLoaded")
  print m.top.findNode("loadCoreTask").findNode("core").loadStatus
end sub

sub onCoreLoaded()
  print "LOAD STATUS FOR THE ANALYTICS CORE :"; m.top.findNode("loadCoreTask").findNode("core").loadStatus
  if m.top.findNode("loadCoreTask").findNode("core").loadStatus = "ready"
    m.bitmovinAnalyticsCore = createObject("roSGNode", "core:Collector")
    m.bitmovinAnalyticsCore.id = "core"

    ' m.timer = CreateObject("roSGNode", "Timer")
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
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "stalling"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "paused"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "finished"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "error"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "none"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "setup"
    print "Adapter Event cought ";m.player.playerState
  else if m.player.playerState = "ready"
    print "Adapter Event cought ";m.player.playerState
  end if
end sub

' sub onThresholdReached()
'   print "threshold reached"
'   sendAnalyticsRequest()
'   m.timer.duration = 60
'   m.timer.control = "start"
' end sub

sub sendAnalyticsRequest()
  'collect all the necessary data here and call the cores method
  'm.bitmovinAnalyticsCore.callFunc("sendAnalyticsRequest", data)

  m.bitmovinAnalyticsCore.callFunc("sendAnalyticsRequest")
end sub
