sub init()
  m.sample = setupSample()
  m.backendUrl = ""
  m.analyticsRequest = m.top.findNode("AnalyticsRequest")
end sub

function setupSample()
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
  m.sample.drmType = invalid
  m.sample.drmLoadTime = invalid
end sub

sub createImpressionId()
 m.sample.impressionId = Lcase(GenerateGuid())
end sub

'TODO: Errorhandling if the keys are invalid. Accepted ones are customdata 1 to 5 and experimentName'
sub setCustomData(values)
  for each v in values
    m.sample.append(values)
  end for
end sub

'TODO: add option for opitional fields as well as error handling'
sub setConfigParameters(config)
  m.backendUrl = config.backendUrl
  m.sample.key = config.key
  m.sample.playerKey = config.playerKey
  m.sample.player = config.player
end sub

function getCurrentImpressionId()
  return m.sample.impressionId
end function

function setDuration(duration)
  m.sample.duration = duration
end function

function setState(state)
  m.sample.state = state
end function

'TODO'
function createBackend()

end function

function setPlayerInformation(values)
  'TODO'
  for each v in values
    m.sample.append(values)
  end for
end function

function getVersion()
  'TODO'
end function

'sub sendAnalyticsRequest(data)
sub sendAnalyticsRequest()
  print "in sendAnalyticsRequest"
  'm.sample.append(data)
  m.analyticsRequest.callFunc("doLicensingRequest")
end sub
