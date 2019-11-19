'@SGNode nativePlayerCollectorTests
'@TestSuite [NPCT] Native Player Collector Tests

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests methods present on the node
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test setAnalyticsConfig with valid params - returns true
'@Params[{"customDataTest": "customData"}]
function NPCT__setAnalyticsConfig_valid_params(analyticsConfig) as void
  isAnalyticsConfigSet = setAnalyticsConfig(analyticsConfig)
  m.AssertTrue(isAnalyticsConfigSet)
end function

'@Test setAnalyticsConfig with invalid params - returns invalid
'@Params[invalid]
function NPCT__setAnalyticsConfig_invalid_params(analyticsConfig) as void
  isAnalyticsConfigSet = setAnalyticsConfig(analyticsConfig)
  m.AssertInvalid(isAnalyticsConfigSet)
end function
