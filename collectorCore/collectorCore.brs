sub init()
  m.version = "1.0.0"
  m.tag = "Bitmovin Analytics Collector "
  m.deviceInfo = CreateObject("roDeviceInfo")
  m.sectionRegistryName = "BitmovinAnalytics"
  m.analyticsDataTask = m.top.findNode("analyticsDataTask")
  m.licensingData = getLicensingData()

  clearSample()
  setLicensingAnalyticsDataTask(m.licensingData)
end sub

sub setLicensingAnalyticsDataTask(licensingData)
  if m.analyticsDataTask = invalid or licensingData = invalid then return
  m.analyticsDataTask.licensingData = licensingData
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

function getVersion(param = invalid) ' invalid param, unused but due to nature, required to be passed in.
  return m.version
end function

function createImpressionId(param = invalid) ' invalid param, unused but due to nature, required to be passed in.
  return lcase(m.deviceInfo.GetRandomUUID())
end function

function getCurrentImpressionId(param = invalid) ' invalid param, unused but due to nature, required to be passed in.
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
sub updateSampleAndSendAnalyticsRequest(updatedSampleData)
  if updatedSampleData = invalid return

  updateSample(updatedSampleData)
  m.analyticsDataTask.eventData = m.sample

  sendAnalyticsRequest()
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(updatedSampleData)
  if updatedSampleData = invalid return

  sendOnceSample = createSendOnceSample(updatedSampleData)
  m.analyticsDataTask.eventData = sendOnceSample

  sendAnalyticsRequest()
end sub

function updateSample(newSampleData)
  if newSampleData = invalid then return false
  for each data in newSampleData
    m.sample.append(newSampleData)
  end for

  return true
end function

function createSendOnceSample(metadata)
  if metadata = invalid then return invalid
  tempSample = {}
  tempSample.append(m.sample)
  for each data in metadata
    tempSample.append(metadata)
  end for

  return tempSample
end function

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
