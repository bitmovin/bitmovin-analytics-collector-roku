function init()
  m.config = getDemoConfig()

  m.bitmovinAdapterLib = createObject("roSGNode", "ComponentLibrary")
  m.bitmovinAdapterLib.id = "core"
  'm.bitmovinAdapterLib.uri = "http://192.168.1.48:8080/roku/adapters/bitmovinPlayerAdapter.zip"
  m.bitmovinAdapterLib.uri = "http://192.168.1.48:8080/roku/analytics/core.zip"
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
  print m.bitmovinAdapterLib.loadStatus
  print m.bitmovinPlayerSDK.loadStatus
  if m.bitmovinPlayerSDK.loadStatus = "ready" and m.bitmovinAdapterLib.loadStatus = "ready"

    m.core = CreateObject("roSGNode", "core:Collector")

    print "both ready"
    m.bitmovinPlayer = CreateObject("roSGNode", "BitmovinPlayerSDK:BitmovinPlayer")
    print "created"
    m.top.appendChild(m.bitmovinPlayer)
    print "appended"
    m.BitmovinFunctions = m.bitmovinPlayer.BitmovinFunctions
    m.BitmovinFields = m.bitmovinPlayer.BitmovinFields
    print "setfieldtoo"
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.ERROR, "catchVideoError")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.WARNING, "catchVideoWarning")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.SEEK, "onSeek")
    'm.bitmovinPlayer.ObserveField(m.BitmovinFields.SEEKED, "onSeeked")

    m.bitmovinPlayer.callFunc(m.BitmovinFunctions.SETUP, m.config)
    print "setup"
  end if
end sub
