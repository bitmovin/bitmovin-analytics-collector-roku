function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()

  m.nativePlayer = m.top.findNode("nativePlayer")
  m.nativePlayerCollector = CreateObject("roSgNode", "nativePlayerCollector")

  analyticsConfig = {
    key: "YOUR_ANALYTICS_KEY",
    title: "Sintel",
    videoId: "Sintel",
    customUserId: "John Smith",
    experimentName: "local-development"
  }
  m.nativePlayerCollector.callFunc("initializeAnalytics", analyticsConfig)
  m.nativePlayerCollector.callFunc("initializePlayer", m.nativePlayer)

  source = getPlayerSource(m.PlayerSourceType.SINTEL)
  changeSource(source)

  m.nativePlayer.control = "play"
  m.nativePlayer.setFocus(true)
end function

sub changeSource(sourceConfig, analyticsConfig = invalid)
  m.nativePlayer.content = sourceConfig
  m.nativePlayerCollector.callFunc("setAnalyticsConfig", analyticsConfig)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if key = "up" and press
    source = getPlayerSource(m.PlayerSourceType.SINTEL)
    analyticsConfig = {
      title: "Sintel",
      videoId: "Sintel"
    }
    changeSource(source, analyticsConfig)
    m.nativePlayer.control = "play"
    m.nativePlayer.setFocus(true)
    return true
  end if
  return false
end function
