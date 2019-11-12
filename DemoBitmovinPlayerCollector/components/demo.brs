function init()
  m.tag = "[demo] "
  m.playerConfig = getPlayerConfig()

  m.bitmovinPlayerCollector = CreateObject("roSgNode", "bitmovinPlayerCollector")

  m.bitmovinPlayerSDK = CreateObject("roSgNode", "componentLibrary")
  m.bitmovinPlayerSDK.id = "bitmovinPlayerSDK"
  m.bitmovinPLayerSDK.uri = m.config.dependencies.playerLib
  m.top.appendChild(m.bitmovinPlayerSDK)
  m.bitmovinPlayerSDK.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onCollectorReady()
    m.bitmovinPlayer = CreateObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
    m.top.appendChild(m.bitmovinPlayer)
    m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
    m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
    m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, m.playerConfig)
    m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
end sub
