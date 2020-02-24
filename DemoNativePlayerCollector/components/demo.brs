function init()
  m.tag = "[demo] "
  m.nativePlayer = m.top.findNode("nativePlayer")

  m.PlayerSourceType = {
    AOM: "AOM",
    SINTEL: "SINTEL",
    SINGLE_SPEED: "SINGLE_SPEED"
  }

  m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")
  m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)

  source = getPlayerSource(m.PlayerSourceType.AOM)
  changeSource(source)

  m.nativePlayer.control = "play"
  m.nativePlayer.setFocus(true)
end function

sub changeSource(content)
  m.nativePlayer.content = content
end sub

function getPlayerSource(sourceType)
  videoContent = createObject("RoSGNode", "ContentNode")
  if sourceType = m.PlayerSourceType.AOM
    videoContent.url = "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
    videoContent.title = "Art of motion"
    videoContent.streamformat = "hls"
  else if sourceType = m.PlayerSourceType.SINTEL
    videoContent.url = "https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
    videoContent.streamFormat = "hls"
    videoContent.title = "Sintel"
  else if sourceType = m.PlayerSourceType.SINGLE_SPEED
    videoContent.url = "https://bitmovin-a.akamaihd.net/content/analytics-teststreams/battlefield-60fps/mpds/battlefield-singlespeed.mpd"
    videoContent.streamFormat = "dash"
    videoContent.title = "Battlefield SingleSpeed"
  end if
  return videoContent
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if key = "up" and press
    source = getPlayerSource(m.PlayerSourceType.SINTEL)
    changeSource(source)
    m.nativePlayer.control = "play"
    m.nativePlayer.setFocus(true)
    return true
  end if
  return false
end function
