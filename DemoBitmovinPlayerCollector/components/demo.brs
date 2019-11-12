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

sub onLoadStatusChanged()
  print m.tag; "Load status for collector: "; m.bitmovinPlayerCollectorLib.loadStatus
  print m.tag; "Load status for player: "; m.bitmovinPlayerSDK.loadStatus
  if m.bitmovinPlayerSDK.loadStatus = "ready" and m.bitmovinPlayerCollectorLib.loadStatus = "ready"
    m.collector = CreateObject("roSgNode", "bitmovinPlayerCollectorLib:bitmovinPlayerCollector")
    m.collector.observeField("collectorReady", "onCollectorReady")
  end if
end sub

sub onCollectorReady()
  print m.tag; "Collector status: "; m.collector.collectorReady
    m.bitmovinPlayer = CreateObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
    m.top.appendChild(m.bitmovinPlayer)
    m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
    m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
    m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, m.playerConfig)
    m.bitmovinPlayerCollector.callFunc("initializePlayer", m.bitmovinPlayer)
end sub
