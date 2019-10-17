sub init()
  m.version = "0.1.0"
  clearSample()
  m.analyticsDataTask = m.top.findNode("analyticsDataTask")
end sub

sub clearSample()
  m.sample = getAnalyticsSample()
  updateChannelInfo()
  updateDeviceInfo()
end sub

sub updateChannelInfo()
  appInfo = CreateObject("roAppInfo")
  m.sample.domain = appInfo.GetID()
end sub

sub updateDeviceInfo()
  deviceInfo = CreateObject("roDeviceInfo")
  m.sample.userAgent = "roku-" + deviceInfo.GetModel() + "-" + deviceInfo.GetVersion()
  m.sample.screenHeight = deviceInfo.GetDisplaySize().h
  m.sample.screenWidth = deviceInfo.GetDisplaySize().w
end sub

sub updateVersion()
  m.sample.analyticsVersion = m.version
end sub

function getVersion()
  return m.version
end function

function createImpressionId()
  return lcase(generateGuid())
end function

function getCurrentImpressionId()
  return m.sample.impressionId
end function

' TODO: Error handling if the keys are invalid
sub updateSample(values)
  for each v in values
    m.sample.append(values)
  end for

  m.analyticsDataTask.eventData = m.sample
  sendAnalyticsRequest()
end sub

sub sendAnalyticsRequest()
  m.analyticsDataTask.sendData = true
end sub
