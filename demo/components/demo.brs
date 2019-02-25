function init()
  m.tag = "[demo] "

  m.config = getDemoConfig()
  m.analyticsConfig = getAnalyticsConfig()
  m.playerConfig = getPlayerConfig()

  m.bitmovinPlayerCollectorLib = CreateObject("roSgNode", "componentLibrary")
  m.bitmovinPlayerCollectorLib.id = "bitmovinPlayerCollectorLib"
  m.bitmovinPlayerCollectorLib.uri = m.config.dependencies.analyticsLib
  m.top.appendChild(m.bitmovinPlayerCollectorLib)
  m.bitmovinPlayerCollectorLib.observeField("loadStatus", "onLoadStatusChanged")

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
  if m.collector.collectorReady = true
    m.bitmovinPlayer = CreateObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
    m.top.appendChild(m.bitmovinPlayer)
    m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
    m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.ERROR, "catchVideoError")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.WARNING, "catchVideoWarning")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.SEEK, "onSeek")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.SEEKED, "onSeeked")
    m.collector.callFunc("initializePlayer", m.bitmovinPlayer)
    m.collector.optionalAnalyticsData = m.analyticsConfig
    m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, m.playerConfig)
  end if
end sub
