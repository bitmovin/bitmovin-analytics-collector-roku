sub setupCsaiService()
  m.CSAI_STATES = {
    IDLE: "IDLE",
    AD_BREAK_STARTED: "AD_BREAK_STARTED",
    ACTIVE: "ACTIVE"
  }
  m.csaiAdIndex = 0
  resetCsaiHelpers()
end sub

sub resetCsaiHelpers()
  m.csaiState = m.CSAI_STATES.IDLE
  m.activeCsaiAdSample = invalid
  m.csaiCurrentAdBreak = invalid
  m.csaiAdBreakStartTimer = invalid
  m.csaiAdStartTimer = invalid
  m.csaiReportedQuartiles = {}
  m.csaiAdPodPosition = 0
end sub
sub csaiOnAdBreakBegin(adBreak = invalid)
  if m.csaiState <> m.CSAI_STATES.IDLE then return

  m.csaiState = m.CSAI_STATES.AD_BREAK_STARTED
  m.csaiCurrentAdBreak = adBreak
  m.csaiAdBreakStartTimer = CreateObject("roTimespan")
end sub

sub csaiOnAdBegin(ad = invalid)
  if m.csaiState = m.CSAI_STATES.IDLE then return

  adStartupTime = 0
  if m.csaiAdBreakStartTimer <> invalid
    adStartupTime = m.csaiAdBreakStartTimer.TotalMilliseconds()
    m.csaiAdBreakStartTimer = invalid
  end if

  m.csaiAdStartTimer = CreateObject("roTimespan")
  m.csaiState = m.CSAI_STATES.ACTIVE
  m.csaiReportedQuartiles = {}

  adSample = createCsaiAdSample()
  adSample.adStartupTime = adStartupTime
  adSample.started = 1

  if ad <> invalid
    adSample.adId = ad.id
    adSample.adSystem = ad.adSystem
    if ad.duration <> invalid then adSample.adDuration = ad.duration * 1000
    if ad.width <> invalid then adSample.adPlaybackWidth = ad.width
    if ad.height <> invalid then adSample.adPlaybackHeight = ad.height
    if ad.creativeId <> invalid then adSample.creativeId = ad.creativeId
    ' THEO's resourceUri is the VAST tag URL, not the media file.
    if ad.resourceUri <> invalid then adSample.adTagUrl = ad.resourceUri
    if ad.clickThrough <> invalid then adSample.adClickthroughUrl = ad.clickThrough
    if ad.type <> invalid then adSample.isLinear = ad.type = "linear"
    applyCsaiAdCustomData(adSample, ad)
  end if

  adBreakForPosition = m.csaiCurrentAdBreak
  if ad <> invalid and ad.adBreak <> invalid then adBreakForPosition = ad.adBreak
  adSample.adPosition = csaiMapTimeOffsetToPosition(adBreakForPosition)

  m.activeCsaiAdSample = adSample
end sub

' A fresh CSAI ad sample with the fields every CSAI ad sample shares; takes the next adIndex and
' adPodPosition.
function createCsaiAdSample() as object
  adSample = getBaseAdSample()
  adSample.adImpressionId = getRandomImpressionId()
  adSample.adType = getAdTypes().CSAI
  ' CSAI has no slate concept; matches Android, which never sets it on client-side ads.
  adSample.isSlate = false
  ' The base sample carries the content's streamFormat, which is wrong for the ad.
  adSample.streamFormat = invalid
  adSample.adIndex = m.csaiAdIndex
  m.csaiAdIndex++
  adSample.adPodPosition = m.csaiAdPodPosition
  m.csaiAdPodPosition++
  return adSample
end function

' THEO fills ad.customData from RAF's parsed VAST. RAF drops <UniversalAdId> entirely, and
' `creativeadid` is Creative@AdID (lowercased by RAF), so no universalAdId can be mapped here.
sub applyCsaiAdCustomData(adSample, ad)
  customData = ad.customData
  if customData <> invalid
    ' RAF sends "" for VAST elements that are missing (e.g. no Creative@AdID), so empty means absent.
    if isNonEmptyCsaiValue(customData.creativeadid) then adSample.creativeAdId = customData.creativeadid
    if isNonEmptyCsaiValue(customData.advertiser) then adSample.advertiserName = customData.advertiser
    if isNonEmptyCsaiValue(customData.adtitle) then adSample.adTitle = customData.adtitle
    ' Fallback only: RAF's format name ("mp4", "dash", "hls"), not the MIME type Android and Web send.
    if isNonEmptyCsaiValue(customData.streamformat) then adSample.streamFormat = customData.streamformat
  end if

  ' The ad's MIME type, which THEO's Ad does not carry; the player collector looks it up from RAF.
  if isNonEmptyCsaiValue(ad.mimeType) then adSample.streamFormat = ad.mimeType

  ' Same fallback as the Android collector's IMA mapping.
  if adSample.adTitle = invalid and isNonEmptyCsaiValue(ad.id) then adSample.adTitle = ad.id
end sub

function isNonEmptyCsaiValue(value) as boolean
  return value <> invalid and value <> ""
end function

function csaiOnAdEnd(ad = invalid) as object
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return invalid

  m.activeCsaiAdSample.completed = 1
  sentSample = sendCsaiAdSample()
  csaiTransitionFromActive()
  return sentSample
end function

function csaiOnAdSkip(ad = invalid) as object
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return invalid

  m.activeCsaiAdSample.skipped = 1
  sentSample = sendCsaiAdSample()
  csaiTransitionFromActive()
  return sentSample
end function

function csaiOnAdError(error = invalid) as object
  if m.csaiState = m.CSAI_STATES.IDLE then return invalid

  if m.csaiState = m.CSAI_STATES.AD_BREAK_STARTED
    adSample = createCsaiAdSample()
    if m.csaiAdBreakStartTimer <> invalid
      adSample.adStartupTime = m.csaiAdBreakStartTimer.TotalMilliseconds()
      m.csaiAdBreakStartTimer = invalid
    end if
    adSample.adPosition = csaiMapTimeOffsetToPosition(m.csaiCurrentAdBreak)
    m.activeCsaiAdSample = adSample
  end if

  if error <> invalid
    m.activeCsaiAdSample.errorCode = error.errorCode
    m.activeCsaiAdSample.errorMessage = error.errorMessage
  end if
  m.activeCsaiAdSample.errorSeverity = getErrorSeverities().critical

  sentSample = sendCsaiAdSample()
  csaiTransitionFromActive()
  return sentSample
end function


sub csaiOnAdBreakEnd()
  if m.csaiState = m.CSAI_STATES.IDLE then return

  resetCsaiHelpers()
end sub

sub csaiOnAdFirstQuartile()
  csaiSetQuartileFlag(getAdQuartileTypes().FIRST)
end sub

sub csaiOnAdMidpoint()
  csaiSetQuartileFlag(getAdQuartileTypes().MIDPOINT)
end sub

sub csaiOnAdThirdQuartile()
  csaiSetQuartileFlag(getAdQuartileTypes().THIRD)
end sub

function getCsaiFlagForAdQuartile(quartile)
  if quartile = getAdQuartileTypes().FIRST then return { quartile1: 1 }
  if quartile = getAdQuartileTypes().MIDPOINT then return { midpoint: 1 }
  if quartile = getAdQuartileTypes().THIRD then return { quartile3: 1 }
  return {}
end function

sub csaiSetQuartileFlag(quartile)
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return
  if m.activeCsaiAdSample = invalid then return
  if m.csaiReportedQuartiles[quartile] = true then return

  m.activeCsaiAdSample.append(getCsaiFlagForAdQuartile(quartile))
  m.csaiReportedQuartiles[quartile] = true
end sub

sub csaiTransitionFromActive()
  m.csaiState = m.CSAI_STATES.AD_BREAK_STARTED
  m.activeCsaiAdSample = invalid
  m.csaiAdStartTimer = invalid
end sub

function sendCsaiAdSample() as object
  if m.activeCsaiAdSample = invalid then return invalid
  m.activeCsaiAdSample.timeSinceAdStartedInMs = getCsaiTimePlayed()
  sendAnalyticsSampleOnce(m.activeCsaiAdSample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
  return m.activeCsaiAdSample
end function

function getCsaiTimePlayed()
  if m.csaiAdStartTimer = invalid then return 0
  return m.csaiAdStartTimer.TotalMilliseconds()
end function

function isCsaiAdBreakInProgress() as boolean
  return m.csaiState <> m.CSAI_STATES.IDLE
end function

sub manipulateSampleForCsai()
  if m.sample.state <> "ad" then return
  updateSample({ ad: getAdTypes().CSAI })
end sub

function csaiMapTimeOffsetToPosition(adBreak)
  if adBreak = invalid or adBreak.timeOffset = invalid then return "mid"
  timeOffset = adBreak.timeOffset
  if timeOffset = 0 then return "pre"
  if timeOffset = -1 then return "post"
  return "mid"
end function
