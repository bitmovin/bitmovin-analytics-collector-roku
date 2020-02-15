sub init()
  m.version = "1.0.0"
  m.tag = "Bitmovin Analytics Collector "
  m.appInfo = CreateObject("roAppInfo")
  m.deviceInfo = CreateObject("roDeviceInfo")
  m.sectionRegistryName = "BitmovinAnalytics"
  m.analyticsDataTask = m.top.findNode("analyticsDataTask")
  m.licensingData = getLicensingData()

  setupSample()
  checkAnalyticsLicenseKey(m.licensingData)
end sub

sub checkAnalyticsLicenseKey(licensingData)
  if m.analyticsDataTask = invalid or licensingData = invalid then return
  m.analyticsDataTask.licensingData = licensingData
  m.analyticsDataTask.checkLicenseKey = true
end sub

sub setupSample()
  if m.sample = invalid
    m.sample = getAnalyticsSample()
  end if
  m.sample.analyticsVersion = getVersion()
  m.sample.key = m.licensingData.key
  m.sample.domain = m.appInfo.GetID()
  m.sample.userAgent = "roku-" + m.deviceInfo.GetModel() + "-" + m.deviceInfo.GetVersion()
  m.sample.screenHeight = m.deviceInfo.GetDisplaySize().h
  m.sample.screenWidth = m.deviceInfo.GetDisplaySize().w
  m.sample.userId = getPersistedUserId(m.sectionRegistryName)

  m.sample.sequenceNumber = 0
  m.sample.impressionId = createImpressionId()
end sub

sub clearSampleValues()
  m.sample.ad = 0
  m.sample.paused = 0
  m.sample.played = 0
  m.sample.seeked = 0
  m.sample.buffered = 0

  m.sample.playerStartupTime = 0
  m.sample.videoStartupTime = 0
  m.sample.startupTime = 0

  m.sample.duration = 0
  m.sample.droppedFrames = 0
end sub

function getVersion(param = invalid)
  return m.version
end function

function createImpressionId(param = invalid)
  return lcase(m.deviceInfo.GetRandomUUID())
end function

function getCurrentImpressionId(param = invalid)
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
  licenceKey = m.appInfo.getValue("bitmovin_analytics_license_key")
  if Len(licenceKey) = 0 then print m.tag ; "Warning: license key is not present in the manifest or is set as an empty string"

  licensingData = {
    key : licenceKey,
    domain : m.appInfo.getID(),
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

sub sendAnalyticsRequestAndClearValues()
  m.analyticsDataTask.eventData = m.sample
  m.sample.sequenceNumber++

  sendAnalyticsRequest()
  clearSampleValues()
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(updatedSampleData)
  if updatedSampleData = invalid return

  sendOnceSample = createSendOnceSample(updatedSampleData)
  m.analyticsDataTask.eventData = sendOnceSample

  sendAnalyticsRequest()
end sub

function updateSample(newSampleData)
  if newSampleData = invalid then return false

  m.sample.append(newSampleData)

  return true
end function

sub setVideoTimeStart(time)
  m.sample.videoTimeStart = time
end sub

sub setVideoTimeEnd(time)
  m.sample.videoTimeEnd = time
end sub

function createSendOnceSample(metadata)
  if metadata = invalid then return invalid
  tempSample = {}
  tempSample.append(m.sample)
  tempSample.append(metadata)

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
