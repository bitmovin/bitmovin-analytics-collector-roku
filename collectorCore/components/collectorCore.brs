sub init()
  m.version = "0.1.0"
  clearSample()
  m.analyticsDataTask = m.top.findNode("analyticsDataTask")
end sub

function createSample()
  return {
    ad: 0,
    analyticsVersion: "",
    audioBitrate: 0,
    autoplay: "",
    buffered: 0,
    cdnProvider: "",
    customData1: "",
    customData2: "",
    customData3: "",
    customData4: "",
    customData5: "",
    customUserId: "",
    domain: "",
    drmLoadTime: 0,
    drmType: "",
    droppedFrames: 0,
    duration: 0,
    errorCode: "",
    errorMessage: "",
    experimentName: "",
    impressionId: "",
    isCasting: false,
    isLive: false,
    isMuted: false,
    key: "",
    language: "",
    m3u8Url: "",
    mpdUrl: "",
    pageLoadTime: 0,
    pageLoadType: 0,
    path: "",
    paused: 0,
    platform: "roku",
    played: 0,
    player: "",
    playerKey: "",
    playerStartupTime: 0,
    playerTech: "",
    progUrl: "",
    sequenceNumber: 0,
    screenHeight: 0,
    screenWidth: 0,
    seeked: 0,
    size: "",
    startupTime: 0,
    state: "",
    streamFormat: "",
    time: 0,
    userAgent: "",
    userId: "",
    version: "",
    videoBitrate: 0,
    videoDuration: 0,
    videoId: "",
    videoPlaybackWidth: 0,
    videoPlaybackHeight: 0,
    videoStartupTime: 0,
    videoTimeEnd: 0,
    videoTimeStart: 0,
    videoTitle: "",
    videoWindowHeight: 0,
    videoWindowWidth: 0
  }
end function

sub clearSample()
  m.sample = createSample()
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
end sub

' sub sendAnalyticsRequest(data)
sub sendAnalyticsRequest()
  m.analyticsDataTask.sendData = true
end sub
