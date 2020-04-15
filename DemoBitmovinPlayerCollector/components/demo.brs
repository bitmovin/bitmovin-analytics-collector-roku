function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()

  m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")
  m.bitmovinPlayerSDK = CreateObject("roSgNode", "componentLibrary")
  m.bitmovinPlayerSDK.id = "bitmovinPlayerSDK"
  m.bitmovinPlayerSDK.uri = "https://cdn.bitmovin.com/player/roku/1/bitmovinplayer.zip"
  m.top.appendChild(m.bitmovinPlayerSDK)
  m.bitmovinPlayerSDK.observeFieldScoped("loadStatus", "onLoadStatusChanged")

  m.isPlayerReady = false
end function

sub onLoadStatusChanged()
  m.bitmovinPlayer = CreateObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
  m.top.appendChild(m.bitmovinPlayer)

  playerConfig = {
    playback: {
      autoplay: true,
      muted: true
    },
    adaptation: {
      preload: false
    },
    source: getSourceConfig(m.PlayerSourceType.SINTEL)
  }
  analyticsConfig = {
    isLive: false,
    title: "Art of Motion",
    videoId: "ArtOfMotion",
    customUserId: "John Smith",
    experimentName: "local-development"
  }
  m.bitmovinPlayerCollector.callFunc("setAnalyticsConfig", analyticsConfig)
  m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)

  m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
  m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
  m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, playerConfig)
  m.bitmovinPlayer.setFocus(true)

  m.isPlayerReady = true
end sub

sub changeSource(sourceConfig, analyticsConfig)
  m.bitmovinPlayer.callFunc(m.bitmovinFunctions.LOAD, sourceConfig)
  m.bitmovinPlayerCollector.callFunc("setAnalyticsConfig", analyticsConfig)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if m.isPlayerReady = false then return false

  if key = "up" and press
    sourceConfig = getSourceConfig(m.PlayerSourceType.AOM)
    analyticsConfig = {
      isLive: false,
      title: "Sintel",
      videoId: "Sintel",
    }
    changeSource(sourceConfig, analyticsConfig)
    return true
  end if
  return false
end function
