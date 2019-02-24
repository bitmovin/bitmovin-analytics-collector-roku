function init()
  m.tag = "[demo] "

  m.config = getDemoConfig()
  m.analyticsConfig = getAnalyticsConfig()
  m.playerConfig = getPlayerConfig()

  m.bitmovinAdapterLib = createObject("roSgNode", "componentLibrary")
  m.bitmovinAdapterLib.id = "bitmovinPlayerAdapter"
  m.bitmovinAdapterLib.uri = m.config.dependencies.analyticsLib
  m.top.appendChild(m.bitmovinAdapterLib)
  m.bitmovinAdapterLib.observeField("loadStatus", "onLoadStatusChanged")

  m.bitmovinPlayerSDK = createObject("roSgNode", "componentLibrary")
  m.bitmovinPlayerSDK.id = "bitmovinPlayerSDK"
  m.bitmovinPLayerSDK.uri = m.config.dependencies.playerLib
  m.top.appendChild(m.bitmovinPlayerSDK)
  m.bitmovinPlayerSDK.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onLoadStatusChanged()
  print m.tag; "Load status for Adapter: "; m.bitmovinAdapterLib.loadStatus
  print m.tag; "Load status for Player: "; m.bitmovinPlayerSDK.loadStatus
  if m.bitmovinPlayerSDK.loadStatus = "ready" and m.bitmovinAdapterLib.loadStatus = "ready"
    m.adapter = createObject("roSgNode", "bitmovinPlayerAdapter:bitmovinAdapter")
    m.adapter.observeField("adapterReady", "onAdapterReady")
  end if
end sub

sub onAdapterReady()
  print m.tag; "Adapter status: "; m.adapter.adapterReady
  if m.adapter.adapterReady = true
    m.bitmovinPlayer = createObject("roSgNode", "bitmovinPlayerSdk:bitmovinPlayer")
    m.top.appendChild(m.bitmovinPlayer)
    m.bitmovinFunctions = m.bitmovinPlayer.bitmovinFunctions
    m.bitmovinFields = m.bitmovinPlayer.bitmovinFields
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.ERROR, "catchVideoError")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.WARNING, "catchVideoWarning")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.SEEK, "onSeek")
    ' m.bitmovinPlayer.observeField(m.bitmovinFields.SEEKED, "onSeeked")
    m.adapter.callFunc("initializePlayer", m.bitmovinPlayer)
    m.adapter.optionalAnalyticsData = m.analyticsConfig
    m.bitmovinPlayer.callFunc(m.bitmovinFunctions.setup, m.playerConfig)
  end if
end sub
