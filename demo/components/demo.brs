function init()
  m.tag = "[demo] "
  m.nativePlayer = m.top.findNode("nativePlayer")

  m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
  m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)
  setNativePlayerContent(m.nativePlayer)
  m.nativePlayer.control = "play"
  m.nativePlayer.setFocus(true)
end function

sub setNativePlayerContent(player)
  videoContent = createObject("RoSGNode", "ContentNode")
  videoContent.url = "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
  videoContent.title = "Art of motion"
  videoContent.streamformat = "hls"
  player.content = videoContent
end sub
