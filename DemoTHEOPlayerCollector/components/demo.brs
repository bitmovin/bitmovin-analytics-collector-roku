function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()

  m.THEOsdk = m.top.findNode("THEOsdk")
  m.THEOsdk.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onLoadStatusChanged()
  m.THEOplayer = CreateObject("RoSGNode", "THEOsdk:THEOplayer")
  m.playerContainer = m.top.findNode("THEOPlayerContainer")
  m.playerContainer.appendChild(m.THEOplayer)

  playerConfig = {
    license: "INSERT-LICENSE-HERE"
  }

  m.THEOplayer.callFunc("configure", playerConfig)

  m.THEOplayer.source = {
    "sources": [
      getPlayerSource(m.PlayerSourceType.AOM)
    ]
  }

  m.THEOplayer.callFunc("addEventListener", "error", m.top, "onError")
  m.THEOplayer.callFunc("addEventListener", "playing", m.top, "onPlaying")


  m.THEOplayer.setFocus(true)
  m.THEOplayer.callFunc("play")
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