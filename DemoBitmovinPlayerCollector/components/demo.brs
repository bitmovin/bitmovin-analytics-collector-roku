function init()
  m.tag = "[demo] "
  m.playerConfig = getPlayerConfig()

  m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")

  m.bitmovinPlayerSDK = CreateObject("roSgNode", "componentLibrary")
  m.bitmovinPlayerSDK.id = "bitmovinPlayerSDK"
  m.bitmovinPlayerSDK.uri = "https://cdn.bitmovin.com/player/roku/1/bitmovinplayer.zip"
  m.top.appendChild(m.bitmovinPlayerSDK)
  m.bitmovinPlayerSDK.observeFieldScoped("loadStatus", "onLoadStatusChanged")

  m.isPlayerLoaded = false
end function

sub onLoadStatusChanged()
  m.bitmovinPlayer = CreateObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
  m.top.appendChild(m.bitmovinPlayer)
  m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)

  m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
  m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
  m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, m.playerConfig)
  m.bitmovinPlayer.setFocus(true)

  m.isPlayerLoaded = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if m.isPlayerLoaded = false then return false

  if key = "up"
    m.bitmovinPlayer.callFunc(m.bitmovinFunctions.LOAD, getExamplePlayerConfigWithContentNodeAndPlaylist())
    return true
  end if
  return false
end function
