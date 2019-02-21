function init()
  m.player = invalid
  m.top.findNode("loadCoreTask").findNode("core").observeField("loadStatus", "onCoreLoaded")
end function

sub onCoreLoaded()
  if m.top.findNode("loadCoreTask").findNode("core").loadStatus = "ready"
    m.bitmovinAdapter = createObject("roSGNode", "core:Collector")
    m.bitmovinAdapter.id = "adapter"

    m.top.appendChild(m.bitmovinAdapter)
end sub

sub initializePlayer(player)
  m.player = player
  m.player.observeField("playerState", "onPlayerStateChanged")
end sub

sub onPlayerStateChanged()
  if m.player.playerState = "playing"
    print m.player.playerState
  else if m.player.playerState = "stalling"
    print m.player.playerState
  else if m.player.playerState = "paused"
    print m.player.playerState
  else if m.player.playerState = "finished"
    print m.player.playerState
  else if m.player.playerState = "error"
    print m.player.playerState
  else if m.player.playerState = "none"
    print m.player.playerState
  else if m.player.playerState = "setup"
    print m.player.playerState
  else if m.player.playerState = "ready"
    print m.player.playerState     
  end if
end sub
