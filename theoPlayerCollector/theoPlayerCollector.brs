sub init()
  m.tag = "[theoPlayerCollector] "
  m.collectorCore = m.top.FindNode("collectorCore")
  m.collectorStates = getCollectorStates()
  m.appInfo = CreateObject("roAppInfo")
end sub

' ===== PUBLIC METHODS =====

sub initializeAnalytics(config = invalid)
  m.collectorCore.callFunc("initializeAnalytics", config)
end sub

sub initializePlayer(player)
  unobserveFields()
  m.player = player

  setUpObservers()

  eventData = {
    playerTech: "theo"
    version: getPlayerVersion()
    player: "theo"
    playerKey: getPlayerKeyFromManifest(m.appInfo)
    playerStartupTime: 1
  }

  sendAnalyticsRequestAndClearValues(eventData, 0, m.collectorStates.SETUP)
end sub

function getPlayerKeyFromManifest(appInfo)
  if appInfo = invalid then return invalid

  return appInfo.getValue("theo_player_license_key")
end function

sub destroy(param = invalid)
  unobserveFields(true)

  if m.collectorCore <> invalid
    m.collectorCore.callFunc("internalDestroy", invalid)
  end if
end sub

function getPlayerVersion()
  return "theo-" + m.player.version
end function

function setAnalyticsConfig(config)
  if config = invalid then return invalid

  return m.collectorCore.callFunc("updateAnalyticsConfig", config)
end function

sub setNewMetadata(metadata = invalid)
  ' TODO: Implement (possibly extract into `baseCollector`)
end sub

function setCustomData(customData)
  ' TODO: Implement (possibly extract into `baseCollector`)
end function

sub setCustomDataOnce(customData)
  ' TODO: Implement (possibly extract into `baseCollector`)
end sub

' ===== HELPER METHODS =====

sub decorateSampleWithPlaybackData(sampleData)
  ' TODO: Implement
end sub

' TODO: This is a copy of `bitmovinPlayerCollector`s implementation - maybe extract
function updateSample(sampleData)
  if sampleData = invalid return false

  return m.collectorCore.callFunc("updateSample", sampleData)
end function

' TODO: This is a copy of `bitmovinPlayerCollector`s implementation - maybe extract
sub sendAnalyticsRequestAndClearValues(eventData, duration, state = m.previousState)
  sampleData = eventData
  sampleData.Append({
    state: state,
    duration: duration,
    time: getCurrentTimeInMilliseconds()
  })
  decorateSampleWithPlaybackData(sampleData)

  updateSample(sampleData)
  m.collectorCore.callFunc("sendAnalyticsRequestAndClearValues")
end sub

sub setUpObservers()
  ' TODO: observe

  m.collectorCore.observeFieldScoped("fireHeartbeat", "onHeartbeat") ' TODO: Implement `onHeartbeat`
end sub

sub unobserveFields(isDestroy = false)
  if m.player <> invalid
    ' TODO: unobserve
  end if

  if m.collectorCore <> invalid
    m.collectorCore.unobserveFieldScoped("fireHeartbeat")
  end if
end sub

' ===== Player event callbacks =====


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
