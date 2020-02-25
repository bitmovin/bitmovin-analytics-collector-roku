function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()

  m.nativePlayer = m.top.findNode("nativePlayer")

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
