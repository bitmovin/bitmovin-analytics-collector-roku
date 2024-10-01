'@SGNode analyticsDataTaskTests
'@TestSuite [ADTT] Analytics Data Task Tests

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests analyticsDataTask
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test pushToAnalyticsEventsQueue - valid params - returns true
'@Params[{"customDataTest": "customData"}]
function ADTT__pushToAnalyticsEventsQueue_valid_params(sampleEvent) as void
  m.AssertTrue(pushToAnalyticsEventsQueue(sampleEvent))
end function

'@Test pushToAnalyticsEventsQueue - invalid params - returns false
'@Params[invalid]
function ADTT__pushToAnalyticsEventsQueue_invalid_params(sampleEvent) as void
  m.AssertFalse(pushToAnalyticsEventsQueue(sampleEvent))
end function

'@Test clearAnalyticsEventsQueue - not empty analyticsEventsQueue - returns true
'@Params[{"customDataTest": "customData"}]
function ADTT__clearAnalyticsEventsQueue_not_empty_analyticsEventsQueue(sampleEvent) as void
  pushToAnalyticsEventsQueue(sampleEvent)
  m.AssertTrue(clearAnalyticsEventsQueue())
end function

'@Test clearAnalyticsEventsQueue - empty analyticsEventsQueue - returns false
function ADTT__clearAnalyticsEventsQueue_empty_analyticsEventsQueue() as void
  m.AssertFalse(clearAnalyticsEventsQueue())
end function
