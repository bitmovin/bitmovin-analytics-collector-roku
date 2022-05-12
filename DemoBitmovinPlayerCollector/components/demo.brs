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
    key: "YOUR_ANALYTICS_KEY",
    isLive: false,
    title: "Art of Motion",
    videoId: "ArtOfMotion",
    customUserId: "John Smith",
    experimentName: "local-development"
  }
  m.bitmovinPlayerCollector.callFunc("initializeAnalytics", analyticsConfig)
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
  handled = false

  if m.isPlayerReady = false then return handled

  if key = "up" and press
    sourceConfig = getSourceConfig(m.PlayerSourceType.TOS)
    analyticsConfig = {
      isLive: false,
      title: "Tears of Steel",
      videoId: "tears-of-steel",
    }
    changeSource(sourceConfig, analyticsConfig)
    handled = true
  else if key = "down" and press
    ' Demo for deinitializing the analytics collector.
    ' Destroy the collector before the player
    m.bitmovinPlayerCollector.callFunc("destroy", invalid)
    m.bitmovinPlayer.callFunc("destroy", invalid)
    sleep(1000) ' Wait for some time
    onLoadStatusChanged() ' Setup a new video
    handled = true
  end if

  return handled
end function
