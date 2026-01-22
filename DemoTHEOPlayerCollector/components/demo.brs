function init()
  m.tag = "[demo] "
  m.PlayerSourceType = getPlayerSourceType()
  m.playerConfig = {
    license: "INSERT-LICENSE-HERE"
  }

  m.THEOsdk = m.top.findNode("THEOsdk")
  m.THEOsdk.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onLoadStatusChanged(sourceType = invalid)
  m.THEOplayer = CreateObject("RoSGNode", "THEOsdk:THEOplayer")
  m.playerContainer = m.top.findNode("THEOPlayerContainer")
  m.playerContainer.appendChild(m.THEOplayer)

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
