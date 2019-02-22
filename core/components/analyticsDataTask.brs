sub init()
  'HACK use hardcoded data'
  m.top.eventData = {
    ad: 0,
    analyticsVersion: "0.1.0",
    audioBitrate: 0,
    'autoplay: "",
    buffered: 0,
    cdnProvider: "",
    customData1: "",
    customData2: "",
    customData3: "",
    customData4: "",
    customData5: "",
    customUserId: "",
    domain: "com.bitmovin.player.roku",
    downloadSpeedInfo: {},
    'drmLoadTime: 0,
    'drmType: "",
    droppedFrames: 0,
    duration: 0,
    'errorCode: "",
    'errorMessage: "",
    experimentName: "HACKATHON",
    impressionId: "7c16cab6-f263-43b7-8001-256256be12e6",
    isCasting: false,
    isLive: false,
    isMuted: false,
    key: "d1a494b6-cbc2-4ba1-9218-f6d5e29f7cc1",
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
    'playerKey: "",
    playerStartupTime: 0,
    playerTech: "",
    progUrl: "",
    screenHeight: 0,
    screenWidth: 0,
    seeked: 0,
    sequenceNumber: 0,
    size: "",
    startupTime: 0,
    state: "",
    streamFormat: "",
    time: 0,
    title: "tears_of_steel",
    userAgent: "",
    userId: "",
    version: "",
    videoBitrate: 0,
    videoDuration: 0,
    videoId: "",
    videoPlaybackHeight: 0,
    videoPlaybackWidth: 0,
    videoStartupTime: 1,
    videoTimeEnd: 0,
    videoTimeStart: 0,
    videoTitle: "",
    videoWindowHeight: 0,
    videoWindowWidth: 0
  }
  m.licensingState = m.top.findNode("licensingState")
  m.timer = createObject("roTimespan")
  m.top.url = "https://analytics-ingress-global.bitmovin.com/licensing"
  m.top.licensingData = {
    key : "d1a494b6-cbc2-4ba1-9218-f6d5e29f7cc1",
    domain : "com.bitmovin.player.roku",
    analyticsVersion : "0.1.0"
  }
  m.licensingResponse = {}
  print "in analyticsRequest"
  m.top.functionName = "execute"
  m.top.control = "RUN"
end sub

sub execute()
  url = m.top.url

  http = createObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = createObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.AddHeader("Origin", "https://com.bitmovin.player.roku")

  data = FormatJson(m.top.licensingData)

  if http.AsyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        m.licensingResponse = ParseJson(msg.getString())
        if m.licensingResponse.status = "granted"
          m.licensingState = m.licensingResponse.status
        end if
      else
        print "analytics request failed: "; msg.getfailurereason();" "; msg.getresponsecode();" "; m.top.url
        m.licensingResponse = {}
      end if
      http.asyncCancel()
    else if msg = invalid
      print "analytics request failed"
      m.licensingResponse = {}
      http.asyncCancel()
    end if
  end if
  print "response: "; m.licensingResponse

  if m.licensingState <> "granted"
    return
  end if

  port = CreateObject("roMessagePort")
  m.top.observeField("sendData", port)

  m.timer.Mark()

  while true
    msg = wait(500, port)

    if type(msg) = "roSGNodeEvent"
      if msg.GetField() = "sendData"
        if msg.GetData() = true
          sendAnalyticsData()
        end if
      end if
    end if

    if m.timer.totalMilliseconds() > 10*1000
      sendAnalyticsData()
    end if

  end while
end sub

sub sendAnalyticsData()
  print "in send Analytics data"

  url = "https://analytics-ingress-global.bitmovin.com/analytics"

  http = createObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = createObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.AddHeader("Origin", "https://com.bitmovin.player.roku")

  data = FormatJson(m.top.eventData)

  if http.AsyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        print "Event Data request successful"
      else
        print "Event Data request failed: "; msg.getfailurereason();" "; msg.getresponsecode();" "; url
        'TODO handle retry'
      end if
      http.asyncCancel()
    else if msg = invalid
      print "Event Data request failed"
      http.asyncCancel()
    end if
  end if

  m.timer.Mark()
end sub
