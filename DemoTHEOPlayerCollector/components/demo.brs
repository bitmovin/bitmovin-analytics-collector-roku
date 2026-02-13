function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()

  m.theoPlayerCollector = CreateObject("roSgNode", "theoPlayerCollector")

  m.playerConfig = {
    license: m.appInfo.getValue("theo_player_license_key")
  }
  m.THEOsdk = m.top.findNode("THEOsdk")
  m.THEOsdk.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onLoadStatusChanged(sourceType = invalid)
  m.THEOplayer = CreateObject("RoSGNode", "THEOsdk:THEOplayer")
  m.playerContainer = m.top.findNode("THEOPlayerContainer")
  m.playerContainer.appendChild(m.THEOplayer)

  analyticsConfig = {
    key: "YOUR_ANALYTICS_KEY",
    isLive: false,
    title: "Art of Motion",
    videoId: "ArtOfMotion",
    customUserId: "John Smith",
    experimentName: "local-development-theo"
  }

  m.theoPlayerCollector.callFunc("initializeAnalytics", analyticsConfig)
  m.theoPlayerCollector.callFunc("initializePlayer", m.THEOplayer)
  m.theoPlayerCollector.observeFieldScoped("error", "onCollectorError")

  preparePlayer(m.PlayerSourceType.AOM)

  m.THEOplayer.callFunc("play")
  m.THEOplayer.setFocus(true)
end sub

sub preparePlayer(sourceType)
  m.THEOplayer.callFunc("configure", m.playerConfig)

  m.THEOplayer.source = {
    "sources": [
      getPlayerSource(sourceType)
    ]
  }

  m.THEOplayer.callFunc("addEventListener", "error", m.top, "onError")
  m.THEOplayer.callFunc("addEventListener", "playing", m.top, "onPlaying")
end sub


' ================================ '
' ========== CALLBACKS =========== '
' ================================ '

function onError(eventData)
  print "-> ERROR: "; eventData
end function

function onPlaying(eventData)
  print "-> PLAYING: "; eventData
end function

sub onCollectorError(event)
  errorData = event.getData()
  print "-> COLLECTOR ERROR: "; FormatJson(errorData)

  ' It's possible to override the error severity here before it gets sent to the analytics backend
  ' errorData.error.severity = "INFO"
  ' m.theoPlayerCollector.error = errorData

end sub

function onKeyEvent(key as string, press as boolean) as boolean
  handled = false

  if m.isPlayerReady = false then return handled

  if key = "down" and press
    m.THEOplayer.callFunc("destroy")
    sleep(1000)
    onLoadStatusChanged()
    handled = true
  end if

  return handled
end function
