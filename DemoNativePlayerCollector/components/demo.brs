function init()
  m.tag = "[demo] "
  m.nativePlayer = m.top.findNode("nativePlayer")

  m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
  m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)

  source = getPlayerSource1()
  changeSource(source)

  m.nativePlayer.control = "play"
  m.nativePlayer.setFocus(true)
end function

sub changeSource(content)
  m.nativePlayer.content = content
end sub

function getPlayerSource1()
  videoContent = createObject("RoSGNode", "ContentNode")
  videoContent.url = "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
  videoContent.title = "Art of motion"
  videoContent.streamformat = "hls"
  return videoContent
end function

function getPlayerSource2()
  videoContent = createObject("RoSGNode", "ContentNode")
  videoContent.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
  videoContent.streamFormat = "hls"
  videoContent.title = "Sintel"
  return videoContent
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if key = "up" and press
    source = getPlayerSource2()
    changeSource(source)
    m.nativePlayer.control = "play"
    m.nativePlayer.setFocus(true)
    return true
  end if
  return false
end function
