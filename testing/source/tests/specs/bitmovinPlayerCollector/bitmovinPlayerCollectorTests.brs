'@SGNode bitmovinPlayerCollectorTests
'@TestSuite [BPCT] Bitmovin Player Collector Tests

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests bitmovinPlayerCollector
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test getPlayerKeyFromManifest with invalid params - returns invalid
'@Params[invalid]
function BPCT__getPlayerKeyFromManifest_invalid_params(appInfo) as void
  bitmovinPlayerKey = getPlayerKeyFromManifest(appInfo)
  m.AssertInvalid(bitmovinPlayerKey)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests bitmovinPlayerCollector API
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test setAnalyticsConfig with valid params - returns true
'@Params[{"customDataTest": "customData"}]
function BPCT__setAnalyticsConfig_valid_params(analyticsConfig) as void
  isAnalyticsConfigSet = setAnalyticsConfig(analyticsConfig)
  m.AssertTrue(isAnalyticsConfigSet)
end function

'@Test setAnalyticsConfig with invalid params - returns invalid
'@Params[invalid]
function BPCT__setAnalyticsConfig_invalid_params(analyticsConfig) as void
  isAnalyticsConfigSet = setAnalyticsConfig(analyticsConfig)
  m.AssertInvalid(isAnalyticsConfigSet)
end function
