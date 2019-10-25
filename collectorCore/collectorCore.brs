sub init()
  m.version = "1.0.0"
  m.tag = "Bitmovin Analytics Collector "
  m.deviceInfo = CreateObject("roDeviceInfo")
  m.sectionRegistryName = "BitmovinAnalytics"
  m.licensingData = getLicensingData()

  clearSample()
  setAndRunAnalyticsDataTask()
end sub

sub setAndRunAnalyticsDataTask()
  m.analyticsDataTask = m.top.findNode("analyticsDataTask")
  m.analyticsDataTask.licensingData = m.licensingData
end sub

sub clearSample()
  m.sample = getAnalyticsSample()
  updateChannelInfo()
  updateDeviceInfo()
  updateVersion()
  updateKey(m.licensingData.key)
  m.sample.append({userId: getPersistedUserId(m.sectionRegistryName)})
end sub

sub updateChannelInfo()
  appInfo = CreateObject("roAppInfo")
  m.sample.domain = appInfo.GetID()
end sub

sub updateKey(key)
  m.sample.key = key
end sub

sub updateDeviceInfo()
  m.sample.userAgent = "roku-" + m.deviceInfo.GetModel() + "-" + m.deviceInfo.GetVersion()
  m.sample.screenHeight = m.deviceInfo.GetDisplaySize().h
  m.sample.screenWidth = m.deviceInfo.GetDisplaySize().w
end sub

sub updateVersion()
  m.sample.analyticsVersion = getVersion()
end sub

function getVersion()
  return m.version
end function

function createImpressionId()
  return lcase(m.deviceInfo.GetRandomUUID())
end function

function getCurrentImpressionId()
  return m.sample.impressionId
end function

function getPersistedUserId(sectionRegistryName)
  if sectionRegistryName = invalid
    return invalid
  end if

  persistedUserIdRegistryKey = "userId"
  userId = readFromRegistry(sectionRegistryName, persistedUserIdRegistryKey)
  if userId = invalid
    userId = m.deviceInfo.GetRandomUUID()
    userIdData = {key: persistedUserIdRegistryKey, value: userId}
    writeToRegistry(sectionRegistryName, userIdData)
  end if

  return userId
end function

function getLicensingData()
  appInfo = CreateObject("roAppInfo")
  licenceKey = appInfo.getValue("bitmovin_analytics_license_key")
  if Len(licenceKey) = 0 then print m.tag ; "Warning: license key is not present in the manifest or is set as an empty string"

  licensingData = {
    key : licenceKey,
    domain : appInfo.getID(),
    analyticsVersion : getVersion()
  }

  return licensingData
end function

' TODO: Error handling if the keys are invalid
sub updateSampleAndSendAnalyticsRequest(values)
  for each v in values
    m.sample.append(values)
  end for

  m.analyticsDataTask.eventData = m.sample
  sendAnalyticsRequest()
end sub

sub sendAnalyticsRequest()
  m.analyticsDataTask.sendData = true
end sub

Function readFromRegistry(registrySectionName, readKey)
     registrySection = CreateObject("roRegistrySection", registrySectionName)
     if registrySection.Exists(readKey)
         return registrySection.Read(readKey)
     end if
     return invalid
End Function

Function writeToRegistry(registrySectionName, dataToWrite)
    registrySection = CreateObject("roRegistrySection", registrySectionName)
    key = dataToWrite.key
    value = dataToWrite.value
    registrySection.Write(key, value)
    registrySection.Flush()
End Function