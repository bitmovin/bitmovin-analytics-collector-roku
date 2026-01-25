sub init()
  m.tag = "[theoPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
end sub

sub initializeAnalytics(config = invalid)
  m.collectorCore.callFunc("initializeAnalytics", config)
end sub

sub initializePlayer(player)
  m.player = player
  ' TODO: Implement
end sub

sub destroy(param = invalid)
  ' TODO: Implement
end sub

function getPlayerVersion()
  ' TODO: Implement
end function

function setAnalyticsConfig(config)
  ' TODO: Most likely implement in baseCollector
end function

sub setNewMetadata(metadata = invalid)
  ' TODO: Most likely implement in baseCollector
end sub

function setCustomData(customData)
  ' TODO: Most likely implement in baseCollector
end function

sub setCustomDataOnce(customData)
  ' TODO: Most likely implement in baseCollector
end sub

' ====== SSAI related ad callbacks ======

function adBreakStart(adBreakMetadata = invalid)
  m.collectorCore.callFunc("adBreakStart", adBreakMetadata)
end function

function adStart(adMetadata = invalid)
  m.collectorCore.callFunc("adStart", adMetadata)
end function

function adBreakEnd()
  m.collectorCore.callFunc("adBreakEnd")
end function

'Function to report that an `adQuartile` has been reached during an SSAI-based ad.
'@param {String} adQuartile - The adQuartile to be reported. Values can either be `"first'`, `"midpoint"`, `"third"` or `"completed"`.
'@param {Object} adQuartileMetadata - Metadata to be reported with the `adQuartile`. Can currently only contain a `failedBeaconUrl` to indicate that pinging a related beacon was not successful.
function adQuartileFinished(adQuartile, adQuartileMetadata = invalid)
  m.collectorCore.callFunc("adQuartileFinished", adQuartile, adQuartileMetadata)
end function
