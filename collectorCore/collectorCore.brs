sub init()
  m.version = "2.6.3"
  m.tag = "Bitmovin Analytics Collector [collectorCore] "
  m.appInfo = CreateObject("roAppInfo")
  m.domain = m.appInfo.GetID() + ".roku"
  m.deviceInfo = CreateObject("roDeviceInfo")
  m.sectionRegistryName = "BitmovinAnalytics"
  m.AnalyticsDataTask = m.top.findNode("analyticsDataTask")
  m.analyticsConfig = CreateObject("roAssociativeArray")
  m.sample = invalid
end sub

sub initializeAnalytics(config = invalid)
  m.AnalyticsDataTask.callFunc("runTask", invalid)

  ' Set licenseKey if present in analytics configuration
  if config <> invalid and config.DoesExist("key")
    setLicenseKey(config.key)
  end if

  resetSaaiHelpers()

  checkAnalyticsLicenseKey()
  setupSample()

  updateAnalyticsConfig(config)
end sub

sub resetSsaiHelpers()
  m.ssaiStates = getSsaiStates()
  m.ssaiState = m.ssaiStates.IDLE
  m.currentAdMetadata = {}
  m.isFirstSampleOfAd = false
  m.adCustomData = invalid
end sub

' Clean up AnalyticsDataTask
sub internalDestroy(param = invalid)
  m.AnalyticsDataTask.callFunc("stopTask", invalid)
end sub

' #region Licensing

sub checkAnalyticsLicenseKey()
  if isInvalid(m.AnalyticsDataTask) then return

  m.AnalyticsDataTask.licensingData = getLicensingData()
  m.AnalyticsDataTask.checkLicenseKey = true
end sub

function getLicensingData()
  licenseKey = getLicenseKey()

  if isInvalid(licenseKey) or Len(licenseKey) = 0
    print m.tag; "Warning: license key is not present in the analyticsConfig or manifest, or is set as an empty string."
  end if

  return {
    key : licenseKey,
    domain : m.domain,
    analyticsVersion : getVersion()
  }
end function

' Returns Bitmovin analytics license key that is set in the analytics configuration or the manifest (as fallback), or invalid.
function getLicenseKey()
  if isInvalid(m.analyticsConfig) or isInvalid(m.appInfo) return invalid

  licenseKey = pluck(m.analyticsConfig, ["key"])
  if isInvalid(licenseKey)
    licenseKey = m.appInfo.getValue("bitmovin_analytics_license_key")
  end if

  return licenseKey
end function

sub setLicenseKey(licenseKey)
  m.analyticsConfig.key = licenseKey
end sub

' #endregion

' Sets up sample that is sent to Bitmovin Analytics.
sub setupSample()
  if isInvalid(m.sample)
    m.sample = getAnalyticsSample()
  end if
  m.sample.analyticsVersion = getVersion()
  m.sample.key = getLicenseKey()
  m.sample.domain = m.domain
  m.sample.userAgent = getUserAgent()
  m.sample.screenHeight = m.deviceInfo.GetDisplaySize().h
  m.sample.screenWidth = m.deviceInfo.GetDisplaySize().w
  m.sample.userId = getPersistedUserId(m.sectionRegistryName)
  m.sample.language = m.deviceInfo.GetCurrentLocale()

  m.sample.sequenceNumber = 0
  m.sample.impressionId = createImpressionId()
  m.sample.deviceInformation = getDeviceInformation()
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

  m.sample.errorCode = invalid
  m.sample.errorMessage = invalid
end sub

' Return the Bitmovin Analytics collector version.
function getVersion()
  return m.version
end function

' Return a custom UserAgent string.
function getUserAgent()
  osVersion = m.deviceInfo.GetOSVersion()
  versionBuild = substitute("{0}{1}", osVersion.revision, osVersion.build)
  return substitute("Roku/DVP-{0}.{1} ({2})", osVersion.major, osVersion.minor, versionBuild)
end function

' Return the device information such as manufacturer and Roku model.
function getDeviceInformation()
 return {
    manufacturer: m.deviceInfo.GetModelDetails().VendorName,
    model: m.deviceInfo.GetModel(),
    isTV: m.deviceInfo.GetModelType() = "TV"
 }
end function

' Create a new unique impression ID.
function createImpressionId()
  return lcase(m.deviceInfo.GetRandomUUID())
end function

' Return the impression ID of the current session.
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

' TODO: Error handling if the keys are invalid
sub sendAnalyticsRequestAndClearValues()
  m.AnalyticsDataTask.eventData = m.sample
  m.sample.sequenceNumber++

  sendAnalyticsRequest()
  clearSampleValues()
end sub

sub createTempMetadataSampleAndSendAnalyticsRequest(updatedSampleData)
  if updatedSampleData = invalid return

  sendOnceSample = createSendOnceSample(updatedSampleData)
  m.AnalyticsDataTask.eventData = sendOnceSample

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
  m.AnalyticsDataTask.sendData = true
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

' Extract valid analytics configuration fields from the config object.
' This metadata object will be merged with the sample! Make sure that fields are valid sample attributes.
' @return A valid analytics configuration which can be appended to analytics samples
function getMetadataFromAnalyticsConfig(config)
  if config = invalid then return {}

  metadata = {
    isLive: false
  }

  if config.DoesExist("cdnProvider")
    metadata.cdnProvider = config.cdnProvider
  end if
  if config.DoesExist("videoId")
    metadata.videoId = config.videoId
  end if
  if config.DoesExist("title")
    metadata.videoTitle = config.title
  end if
  if config.DoesExist("customUserId")
    metadata.customUserId = config.customUserId
  end if

  ' Check `customDataX` fields
  for i = 1 to 30
    customDataField = "customData" + i.ToStr()
    if config.DoesExist(customDataField)
      metadata[customDataField] = config[customDataField]
    end if
  end for

  if config.DoesExist("experimentName")
    metadata.experimentName = config.experimentName
  end if
  if config.DoesExist("isLive")
    metadata.isLive = config.isLive
  end if
  return metadata
end function

sub guardAgainstMissingVideoTitle(config)
  if config <> invalid and config.DoesExist("title") = true then return
  print m.tag; "The new analytics configuration does not contain the field `title`"
end sub

sub guardAgainstMissingIsLive(config)
  if config <> invalid and config.DoesExist("isLive") = true then return
  print m.tag; "The new analytics configuration does not contain the field `isLive`. It will default to `false` which might be unintended? Once stream playback information is available the type will be populated."
end sub

sub updateAnalyticsConfig(unsanitizedConfig)
  ' First check for missing fields and then extract metadata (renaming of fields happens here)
  guardAgainstMissingVideoTitle(unsanitizedConfig)
  guardAgainstMissingIsLive(unsanitizedConfig)

  config = getMetadataFromAnalyticsConfig(unsanitizedConfig)

  mergedConfig = {}
  mergedConfig.Append(m.analyticsConfig)
  mergedConfig.Append(config)
  m.analyticsConfig = mergedConfig

  updateSample(m.analyticsConfig)
end sub

function adBreakStart(adBreakMetadata = invalid)
  if m.ssaiState <> m.ssaiStates.IDLE then return

  m.ssaiState = m.ssaiStates.AD_BREAK_STARTED
  m.currentAdMetadata = adBreakMetadata
end function

funciton adStarted(adMetadata = invalid)
  if m.ssaiState = m.ssaiState.IDLE then return

  m.ssaiState = m.ssaiState.ACTIVE
  m.isFirstSampleOfAd = true

  sendAnalyticsRequestAndClearValues()

  m.adCustomData = extractCustomDataFieldsOnly(adMetadata.customData)

  if adMetadata <> invalid
    m.currentAdMetadata = {
      adPosition: m.currentAdMetadata.adPosition,
      adId: adMetadata.adId,
      adSystem: adMetadata.adSystem,
      customData: customData,
    };
  end if
end function