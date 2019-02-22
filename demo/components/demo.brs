function init()
  m.config = getDemoConfig()

  m.bitmovinAdapterLib = createObject("roSGNode", "ComponentLibrary")
  m.bitmovinAdapterLib.id = "bitmovinPlayerAdapter"
  m.bitmovinAdapterLib.uri = "http://192.168.1.48:8080/roku/adapters/bitmovinPlayerAdapter.zip"
  'm.bitmovinAdapterLib.uri = "http://192.168.1.48:8080/roku/analytics/core.zip"
  'm.bitmovinAdapterLib.uri = "https://cdn.bitmovin.com/player/roku/1/bitmovinplayer.zip"
  m.top.appendChild(m.bitmovinAdapterLib)
  m.bitmovinAdapterLib.observeField("loadStatus", "onLoadStatusChanged")

  m.bitmovinPlayerSDK = CreateObject("roSGNode", "ComponentLibrary")
  m.bitmovinPlayerSDK.id = "BitmovinPlayerSDK"
  m.bitmovinPlayerSDK.uri = "https://cdn.bitmovin.com/player/roku/1/bitmovinplayer.zip"
  m.top.appendChild(m.bitmovinPlayerSDK)
  m.bitmovinPlayerSDK.observeField("loadStatus", "onLoadStatusChanged")
end function

sub onLoadStatusChanged()
  print "Load Status for Adapter: " ; m.bitmovinAdapterLib.loadStatus
  print "Load Status for Player: " ;m.bitmovinPlayerSDK.loadStatus
  if m.bitmovinPlayerSDK.loadStatus = "ready" and m.bitmovinAdapterLib.loadStatus = "ready"
    m.adapter = CreateObject("roSGNode", "bitmovinPlayerAdapter:bitmovinAdapter")
    m.top.appendChild(m.adapter)
    m.adapter.observeField("adapterReady", "onAdapterReady")
  end if
end sub

sub onAdapterReady()
  print "ADAPTER STATUS: "; m.adapter.adapterReady
  if m.adapter.adapterReady = true
    m.bitmovinPlayer = CreateObject("roSGNode", "BitmovinPlayerSDK:BitmovinPlayer")
    m.top.appendChild(m.bitmovinPlayer)
    m.BitmovinFunctions = m.bitmovinPlayer.BitmovinFunctions
    m.BitmovinFields = m.bitmovinPlayer.BitmovinFields
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.ERROR, "catchVideoError")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.WARNING, "catchVideoWarning")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.SEEK, "onSeek")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.SEEKED, "onSeeked")
    m.adapter.callFunc("initializePlayer", m.bitmovinPlayer)
    m.bitmovinPlayer.callFunc(m.BitmovinFunctions.SETUP, m.config)
  end if
end sub
