sub setupSsaiService()
  m.SSAI_STATES = getSsaiStates()
  m.AD_TYPE = getAdTypes()
  m.AD_QUARTILES = getAdQuartileTypes()
  m.AD_TIMER_INIT_VALUE = -1
  m.adIndex = 0
  resetSsaiHelpers()
end sub

sub resetReportedQuartiles()
  m.reportedQuartilesForCurrentAd = {}

  for each quartileName in m.AD_QUARTILES.keys()
    quartileValue = m.AD_QUARTILES[quartileName]
    m.reportedQuartilesForCurrentAd[quartileValue] = false
  end for
end sub

sub resetSsaiHelpers()
  m.ssaiState = m.SSAI_STATES.IDLE
  m.currentAdMetadata = {}
  m.isFirstSampleOfAd = false
  m.adCustomData = {}
  m.lastAdStartTimer = invalid
  m.hasErrorBeenReportedForCurrentAd = false

  resetAdValues = {
    adIndex: invalid
    adId: invalid
    adSystem: invalid
    adPosition: invalid
    adImpressionId: invalid
  }
  resetReportedQuartiles()
  updateSample(resetAdValues)
end sub

function getSsaiAdSample()
  adSample = getBaseAdSample()

  adSample.adType = m.AD_TYPE.SSAI

  if m.lastAdStartTimer = invalid
    adSample.timeSinceAdStartedInMs = m.AD_TIMER_INIT_VALUE
  else
    adSample.timeSinceAdStartedInMs = m.lastAdStartTimer.TotalMilliseconds()
  end if

  return adSample
end function

sub adBreakStart(adBreakMetadata = invalid)
  if m.ssaiState <> m.SSAI_STATES.IDLE then return

  m.ssaiState = m.SSAI_STATES.AD_BREAK_STARTED
  m.currentAdMetadata = adBreakMetadata
end sub

sub adStart(adMetadata = invalid)
  if m.ssaiState = m.SSAI_STATES.IDLE then return
  m.lastAdStartTimer = CreateObject("roTimespan")
  resetReportedQuartiles()
  m.hasErrorBeenReportedForCurrentAd = false

  m.top.fireHeartbeat = true

  sampleUpdate = {
    adImpressionId: getRandomImpressionId()
  }
  sampleUpdate.append(m.analyticsConfig)
  updateSample(sampleUpdate)
  m.ssaiState = m.SSAI_STATES.ACTIVE
  m.isFirstSampleOfAd = true

  if adMetadata <> invalid
    m.adCustomData = adMetadata.customData
    m.currentAdMetadata = {
      adPosition: m.currentAdMetadata.adPosition,
      adId: adMetadata.adId,
      adSystem: adMetadata.adSystem,
      customData: m.adCustomData
    }
  end if

  adStartedEngagementSample = getSsaiAdSample()
  adStartedEngagementSample.append({ started: 1 })
  sendAnalyticsSampleOnce(adStartedEngagementSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
end sub

sub adBreakEnd()
  if m.ssaiState = m.SSAI_STATES.IDLE then return

  if m.ssaiState = m.SSAI_STATES.ACTIVE
    m.top.fireHeartbeat = true
    updateSample(m.analyticsConfig)
  end if

  resetSsaiHelpers()
end sub

sub manipulateSampleForSsai()
  if m.ssaiState <> m.SSAI_STATES.ACTIVE then return

  sampleUpdate = {}

  sampleUpdate.ad = m.AD_TYPE.SSAI

  if m.currentAdMetadata <> invalid
    sampleUpdate.adId = m.currentAdMetadata.adId
    sampleUpdate.adSystem = m.currentAdMetadata.adSystem
    sampleUpdate.adPosition = m.currentAdMetadata.adPosition
  end if

  if m.isFirstSampleOfAd
    sampleUpdate.adIndex = m.adIndex
    m.isFirstSampleOfAd = false
    m.adIndex++
  else
    updateSample({adIndex: invalid})
  end if

  customData = m.adCustomData
  if customData <> invalid
    for each key in getCustomDataValueKeys()
      if customData.DoesExist(key) then sampleUpdate.AddReplace(key, customData[key])
    end for
  end if

  updateSample(sampleUpdate)
end sub

function getFlagForAdQuartile(adQuartile)
  if adQuartile = m.AD_QUARTILES.FIRST then
    return { quartile1: 1 }
  else if adQuartile = m.AD_QUARTILES.MIDPOINT then
    return { midpoint: 1 }
  else if adQuartile = m.AD_QUARTILES.THIRD then
    return { quartile3: 1 }
  else if adQuartile = m.AD_QUARTILES.COMPLETED then
    return { completed: 1 }
  else
    return {}
  end if
end function

function getFailedAdQuartileProp(adQuartile, adQuartileMetadata)
  if adQuartileMetadata = invalid or adQuartileMetadata.failedBeaconUrl = invalid return {}
  failedBeaconUrl = adQuartileMetadata.failedBeaconUrl

  if adQuartile = m.AD_QUARTILES.FIRST then
    return { quartile1FailedBeaconUrl: failedBeaconUrl }
  else if adQuartile = m.AD_QUARTILES.MIDPOINT then
    return { midpointFailedBeaconUrl: failedBeaconUrl }
  else if adQuartile = m.AD_QUARTILES.THIRD then
    return { quartile3FailedBeaconUrl: failedBeaconUrl }
  else if adQuartile = m.AD_QUARTILES.COMPLETED then
    return { completedFailedBeaconUrl: failedBeaconUrl }
  else
    return {}
  end if
end function

function adQuartileFinished(adQuartile, adQuartileMetadata = invalid)
  if m.ssaiState <> m.SSAI_STATES.ACTIVE or hasQuartileAlreadyBeenReported(adQuartile) then return invalid

  adSample = getSsaiAdSample()

  quartileFlag = getFlagForAdQuartile(adQuartile)
  failedBeaconFlag = getFailedAdQuartileProp(adQuartile, adQuartileMetadata)
  adSample.append(quartileFlag)
  adSample.append(failedBeaconFlag)

  sendAnalyticsSampleOnce(adSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
  markQuartileAsReported(adQuartile)

  return adSample
end function

function isCurrentSampleSsaiRelated()
  return m.ssaiState = m.SSAI_STATES.ACTIVE or m.ssaiState = m.SSAI_STATES.AD_BREAK_STARTED
end function

function hasQuartileAlreadyBeenReported(adQuartile)
  return m.reportedQuartilesForCurrentAd[adQuartile]
end function

sub markQuartileAsReported(adQuartile)
  m.reportedQuartilesForCurrentAd[adQuartile] = true
end sub

sub onError(errorCode, errorMessage)
  if m.ssaiState = m.SSAI_STATES.IDLE or m.hasErrorBeenReportedForCurrentAd then return

  adSample = getSsaiAdSample()
  adSample.errorCode = errorCode
  adSample.errorMessage = errorMessage

  sendAnalyticsSampleOnce(adSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
  m.hasErrorBeenReportedForCurrentAd = true
end sub
