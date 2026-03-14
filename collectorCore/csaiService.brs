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

  adSample = getBaseAdSample()
  adSample.adImpressionId = getRandomImpressionId()
  adSample.adType = getAdTypes().CSAI
  adSample.adStartupTime = adStartupTime
  adSample.adIndex = m.csaiAdIndex
  m.csaiAdIndex++
  adSample.adPodPosition = m.csaiAdPodPosition
  m.csaiAdPodPosition++

  if ad <> invalid
    adSample.adId = ad.id
    adSample.adSystem = ad.adSystem
    if ad.duration <> invalid then adSample.adDuration = ad.duration * 1000
    if ad.width <> invalid then adSample.adPlaybackWidth = ad.width
    if ad.height <> invalid then adSample.adPlaybackHeight = ad.height
    if ad.creativeId <> invalid then adSample.creativeId = ad.creativeId
    if ad.resourceUri <> invalid then adSample.mediaUrl = ad.resourceUri
  end if

  adBreakForPosition = m.csaiCurrentAdBreak
  if ad <> invalid and ad.adBreak <> invalid then adBreakForPosition = ad.adBreak
  adSample.adPosition = csaiMapTimeOffsetToPosition(adBreakForPosition)

  m.activeCsaiAdSample = adSample
  sendCsaiAdSampleWithFlag({ started: 1 })
end sub

sub csaiOnAdEnd(ad = invalid)
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return

  sendCsaiAdSampleWithFlag({ completed: 1 })

  csaiTransitionFromActive()
end sub

sub csaiOnAdSkip(ad = invalid)
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return

  sendCsaiAdSampleWithFlag({ skipped: 1 })

  csaiTransitionFromActive()
end sub

sub csaiOnAdError(eventData = invalid)
  if m.csaiState = m.CSAI_STATES.IDLE then return

  flag = {}
  if eventData <> invalid
    flag.errorCode = eventData.code
    flag.errorMessage = eventData.message
  end if
  sendCsaiAdSampleWithFlag(flag)

  resetCsaiHelpers()
end sub

sub csaiOnAdBreakEnd()
  if m.csaiState = m.CSAI_STATES.IDLE then return
  resetCsaiHelpers()
end sub

sub csaiOnAdFirstQuartile()
  csaiSetQuartileFlag(getAdQuartileTypes().FIRST, { quartile1: 1 })
end sub

sub csaiOnAdMidpoint()
  csaiSetQuartileFlag(getAdQuartileTypes().MIDPOINT, { midpoint: 1 })
end sub

sub csaiOnAdThirdQuartile()
  csaiSetQuartileFlag(getAdQuartileTypes().THIRD, { quartile3: 1 })
end sub

sub csaiSetQuartileFlag(quartile, flag)
  if m.csaiState <> m.CSAI_STATES.ACTIVE then return
  if m.activeCsaiAdSample = invalid then return
  if m.csaiReportedQuartiles[quartile] = true then return

  m.csaiReportedQuartiles[quartile] = true
  sendCsaiAdSampleWithFlag(flag)
end sub

sub csaiTransitionFromActive()
  m.csaiState = m.CSAI_STATES.AD_BREAK_STARTED
  m.activeCsaiAdSample = invalid
  m.csaiAdStartTimer = invalid
end sub

sub sendCsaiAdSampleWithFlag(flag)
  if m.activeCsaiAdSample = invalid then return
  sample = {}
  sample.append(m.activeCsaiAdSample)
  sample.timeSinceAdStartedInMs = getCsaiTimePlayed()
  sample.append(flag)
  sendAnalyticsSampleOnce(sample, m.AnalyticsRequestTypes.AD_ENGAGEMENT)
end sub

function getCsaiTimePlayed()
  if m.csaiAdStartTimer = invalid then return 0
  return m.csaiAdStartTimer.TotalMilliseconds()
end function

function csaiMapTimeOffsetToPosition(adBreak)
  if adBreak = invalid or adBreak.timeOffset = invalid then return "midroll"
  timeOffset = adBreak.timeOffset
  if timeOffset = 0 then return "preroll"
  if timeOffset = -1 then return "postroll"
  return "midroll"
end function
