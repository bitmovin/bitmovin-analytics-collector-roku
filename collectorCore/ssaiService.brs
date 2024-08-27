sub setupSsaiService()
  m.SSAI_STATES = getSsaiStates()
  m.AD_TYPE = getAdTypes()
  m.AD_QUARTILES = getAdQuartileTypes()
  m.adIndex = 0
  resetSsaiHelpers()
end sub

sub resetSsaiHelpers()
  m.ssaiState = m.SSAI_STATES.IDLE
  m.currentAdMetadata = {}
  m.isFirstSampleOfAd = false
  m.adCustomData = {}

  resetAdValues = {
    adIndex: invalid
    adId: invalid
    adSystem: invalid
    adPosition: invalid
    adImpressionId: invalid
  }
  updateSample(resetAdValues)
end sub

sub adBreakStart(adBreakMetadata = invalid)
  if m.ssaiState <> m.SSAI_STATES.IDLE then return

  m.ssaiState = m.SSAI_STATES.AD_BREAK_STARTED
  m.currentAdMetadata = adBreakMetadata
end sub

sub adStart(adMetadata = invalid)
  if m.ssaiState = m.SSAI_STATES.IDLE then return

  adImpressionIdUpdate = {
    adImpressionId: getRandomImpressionId()
  }
  updateSample(adImpressionIdUpdate)
  m.top.fireHeartbeat = true

  updateSample(m.analyticsConfig)
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

sub adQuartileFinished(adQuartile, adQuartileMetadata = invalid)
  adTypes = getAdTypes()
  adSample = getBaseAdSample()
  adSample.adType = adTypes.SSAI

  quartileFlag = getFlagForAdQuartile(adQuartile)
  adSample.append(quartileFlag)

  if adQuartileMetadata <> invalid then
    adSample.adQuartileMetadata = adQuartileMetadata
  end if

  ' TODO: Check if we need to increase m.sample.sequenceNumber
  ' TODO: outsource this into method that allows sending arbitrary samples once
  m.AnalyticsDataTask.eventData = {
    requestType: m.AnalyticsRequestTypes.AD_ENGAGEMENT
    requestData: adSample
  }
  sendAnalyticsRequest()
end sub
