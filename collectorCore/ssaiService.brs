sub setupSsaiService()
  m.SSAI_STATES = getSsaiStates()
  m.AD_TYPE = getAdTypes()
  m.AD_QUARTILES = getAdQuartileTypes()
  m.AD_TIMER_INIT_VALUE = -1
  m.adIndex = -1
  m.ssaiAdPodPosition = -1
  resetSsaiHelpers()
end sub

sub resetReportedQuartiles()
  m.reportedQuartilesForCurrentAd = {}

  for each quartileName in m.AD_QUARTILES.keys()
    quartileValue = m.AD_QUARTILES[quartileName]
    m.reportedQuartilesForCurrentAd[quartileValue] = false
  end for
end sub

sub resetSsaiAdState()
  m.currentAdIsSlate = false
  m.currentAdDurationMs = invalid
end sub

sub resetSsaiHelpers()
  m.ssaiState = m.SSAI_STATES.IDLE
  m.currentAdMetadata = {}
  m.isFirstSampleOfAd = false
  m.adCustomData = {}
  m.lastAdStartTimer = invalid
  m.hasErrorBeenReportedForCurrentAd = false
  m.ssaiExpectedPaidAds = invalid
  m.ssaiExpectedSlates = invalid
  m.completedPaidAds = invalid
  m.completedSlates = invalid
  m.ssaiAdPodPosition = -1
  resetSsaiAdState()

  resetAdValues = {
    adIndex: invalid
    adId: invalid
    adSystem: invalid
    adPosition: invalid
    adImpressionId: invalid
    creativeId: invalid
    creativeAdId: invalid
    advertiserName: invalid
    title: invalid
    universalAdIdValue: invalid
    universalAdIdRegistry: invalid
  }
  resetReportedQuartiles()
  updateSample(resetAdValues)
end sub

function getSsaiAdSample()
  adSample = getBaseAdSample()

  adSample.adType = m.AD_TYPE.SSAI
  adSample.adPodPosition = m.ssaiAdPodPosition

  if m.currentAdMetadata <> invalid
    adSample.creativeId = m.currentAdMetadata.creativeId
    adSample.creativeAdId = m.currentAdMetadata.creativeAdId
    adSample.advertiserName = m.currentAdMetadata.advertiserName
    adSample.title = m.currentAdMetadata.title
    adSample.universalAdIdValue = m.currentAdMetadata.universalAdIdValue
    adSample.universalAdIdRegistry = m.currentAdMetadata.universalAdIdRegistry
  end if

  if m.lastAdStartTimer = invalid
    adSample.timeSinceAdStartedInMs = m.AD_TIMER_INIT_VALUE
  else
    adSample.timeSinceAdStartedInMs = m.lastAdStartTimer.TotalMilliseconds()
  end if

  if m.currentAdDurationMs <> invalid then adSample.adDuration = m.currentAdDurationMs
  adSample.isSlate = m.currentAdIsSlate = true
  if m.ssaiExpectedPaidAds <> invalid then adSample.expectedPaidAds = m.ssaiExpectedPaidAds
  if m.ssaiExpectedSlates <> invalid then adSample.expectedSlates = m.ssaiExpectedSlates
  if m.completedPaidAds <> invalid then adSample.completedPaidAds = m.completedPaidAds
  if m.completedSlates <> invalid then adSample.completedSlates = m.completedSlates
  adSample.exitedAdBreak = false

  return adSample
end function

function sanitizeAdCount(value)
  if value = invalid then return invalid
  if value < 0
    print "Warning: Ad count metadata (expectedPaidAds, expectedSlates) must not be negative. Sanitising to 0."
    return 0
  end if
  return value
end function

sub ssaiOnSourceChange()
  if m.SSAI_STATES = invalid then return
  adBreakEnd()
end sub

sub adBreakStart(adBreakMetadata = invalid)
  if m.ssaiState <> m.SSAI_STATES.IDLE then return
  if not checkAdPositionValidity(adBreakMetadata)
    print "Warning: adBreakMetadata.adPosition must be a String with value 'preroll', 'midroll' or 'postroll'"
    return
  end if

  m.ssaiState = m.SSAI_STATES.AD_BREAK_STARTED
  m.currentAdMetadata = adBreakMetadata

  if adBreakMetadata <> invalid
    m.ssaiExpectedPaidAds = sanitizeAdCount(adBreakMetadata.expectedPaidAds)
    if m.ssaiExpectedPaidAds <> invalid then m.completedPaidAds = 0
    m.ssaiExpectedSlates = sanitizeAdCount(adBreakMetadata.expectedSlates)
    if m.ssaiExpectedSlates <> invalid then m.completedSlates = 0
  end if
end sub

function checkAdPositionValidity(adBreakMetadata)
  if isInvalid(adBreakMetadata) then return true

  adPosition = adBreakMetadata.adPosition

  if type(adPosition) <> "roString" then return false
  if adPosition = "preroll" or adPosition = "midroll" or adPosition = "postroll" then return true
  return false
end function

sub adStart(adMetadata = invalid)
  if m.ssaiState = m.SSAI_STATES.IDLE then return
  m.lastAdStartTimer = CreateObject("roTimespan")
  resetReportedQuartiles()
  m.hasErrorBeenReportedForCurrentAd = false

  m.adIndex++
  m.ssaiAdPodPosition++

  resetSsaiAdState()

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
    adPosition = invalid
    if m.currentAdMetadata <> invalid then adPosition = m.currentAdMetadata.adPosition
    m.currentAdMetadata = {
      adPosition: adPosition,
      adId: adMetadata.adId,
      adSystem: adMetadata.adSystem,
      customData: m.adCustomData,
      creativeId: adMetadata.creativeId,
      creativeAdId: adMetadata.creativeAdId,
      advertiserName: adMetadata.advertiserName,
      title: adMetadata.title,
      universalAdIdValue: adMetadata.universalAdIdValue,
      universalAdIdRegistry: adMetadata.universalAdIdRegistry
    }
    m.currentAdIsSlate = adMetadata.isSlate = true
    if adMetadata.duration <> invalid
      m.currentAdDurationMs = cint(adMetadata.duration * 1000)
    end if
  end if

  adStartedEngagementSample = getSsaiAdSample()
  adStartedEngagementSample.append({ started: 1 })
  sendAnalyticsSampleOnce(adStartedEngagementSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
end sub

sub adBreakEnd()
  if m.ssaiState = m.SSAI_STATES.IDLE then return

  if m.ssaiState = m.SSAI_STATES.ACTIVE
    exitSample = getSsaiAdSample()
    exitSample.exitedAdBreak = true
    if not hasQuartileAlreadyBeenReported(m.AD_QUARTILES.COMPLETED)
      exitSample.closed = 1
    end if
    sendAnalyticsSampleOnce(exitSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)

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
    sampleUpdate.creativeId = m.currentAdMetadata.creativeId
    sampleUpdate.creativeAdId = m.currentAdMetadata.creativeAdId
    sampleUpdate.advertiserName = m.currentAdMetadata.advertiserName
    sampleUpdate.title = m.currentAdMetadata.title
    sampleUpdate.universalAdIdValue = m.currentAdMetadata.universalAdIdValue
    sampleUpdate.universalAdIdRegistry = m.currentAdMetadata.universalAdIdRegistry
  end if

  if m.isFirstSampleOfAd
    sampleUpdate.adIndex = m.adIndex
    m.isFirstSampleOfAd = false
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
    print "Warning: adQuartile must be a String with value 'first', 'midpoint', 'third', 'completed'"
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
  if adQuartileMetadata <> invalid and type(adQuartileMetadata.failedBeaconUrl) = "roString" then adQuartileMetadata.failedBeaconUrl = adQuartileMetadata.failedBeaconUrl.Left(500)

  if adQuartile = m.AD_QUARTILES.COMPLETED
    if m.currentAdIsSlate = true and m.completedSlates <> invalid
      m.completedSlates++
    else if m.currentAdIsSlate = false and m.completedPaidAds <> invalid
      m.completedPaidAds++
    end if
  end if

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

' Returns a finalEventData-compatible event AA with exitedAdBreak:true when the session is
' destroyed mid-ad-break, or invalid otherwise.
' Only fires for ACTIVE state (an ad has actually started); AD_BREAK_STARTED alone has no ad sample.
function getSsaiBreakExitEventForDestroy()
  if m.ssaiState <> m.SSAI_STATES.ACTIVE then return invalid

  exitSample = getSsaiAdSample()
  exitSample.exitedAdBreak = true
  if not hasQuartileAlreadyBeenReported(m.AD_QUARTILES.COMPLETED)
    exitSample.closed = 1
  end if
  return {
    requestType: m.AnalyticsRequestTypes.AD_ENGAGEMENT
    requestData: exitSample
    isSsaiRelated: true
  }
end function

function hasQuartileAlreadyBeenReported(adQuartile)
  return m.reportedQuartilesForCurrentAd[adQuartile]
end function

sub markQuartileAsReported(adQuartile)
  m.reportedQuartilesForCurrentAd[adQuartile] = true
end sub

function onError(errorSample) as object
  if m.ssaiState = m.SSAI_STATES.IDLE or m.hasErrorBeenReportedForCurrentAd then return invalid

  if errorSample.errorSeverity = invalid then errorSample.errorSeverity = getErrorSeverities().critical

  adSample = getSsaiAdSample()
  adSample.errorCode = errorSample.errorCode
  adSample.errorMessage = errorSample.errorMessage
  adSample.errorSeverity = errorSample.errorSeverity

  sendAnalyticsSampleOnce(adSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)

  m.hasErrorBeenReportedForCurrentAd = true

  return adSample
end function
