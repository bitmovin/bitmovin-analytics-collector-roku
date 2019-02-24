sub init()
  m.tag = "[analyticsDataTask]"
  m.config = getCollectorConfig()

  ' HACK use hardcoded data
  m.top.eventData = {
    ad: 0,
    analyticsVersion: "0.1.0",
    audioBitrate: 0,
    autoplay: false,
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
    drmLoadTime: invalid,
    drmType: invalid,
    droppedFrames: 0,
    duration: 0,
    errorCode: invalid,
    errorMessage: invalid,
    experimentName: "HACKATHON",
    impressionId: generateGuid(),
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
    player: "bitmovin",
    playerKey: "",
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
  m.top.url = m.config.serviceEndpoints.analyticsLicense
  m.top.licensingData = {
    key : "d1a494b6-cbc2-4ba1-9218-f6d5e29f7cc1",
    domain : "com.bitmovin.player.roku",
    analyticsVersion : "0.1.0"
  }
  m.licensingResponse = {}
  print m.tag; "In analyticsRequest()"
  m.top.functionName = "execute"
  m.top.control = "RUN"
end sub

sub execute()
  url = m.top.url

  http = createObject("roUrlTransfer")
  http.setCertificatesFile("common:/certs/ca-bundle.crt")
  port = createObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.addHeader("Origin", "https://com.bitmovin.player.roku")

  data = formatJson(m.top.licensingData)

  if http.asyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        m.licensingResponse = parseJson(msg.getString())
        if m.licensingResponse.status = "granted"
          m.licensingState = m.licensingResponse.status
        end if
      else
        print m.tag; "Analytics request failed: "; msg.getfailurereason(); " "; msg.getresponsecode(); " "; m.top.url
        m.licensingResponse = {}
      end if
      http.asyncCancel()
    else if msg = invalid
      print m.tag; "Analytics request failed"
      m.licensingResponse = {}
      http.asyncCancel()
    end if
  end if
  print m.tag; "response: "; m.licensingResponse

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
  print m.tag; "In sendAnalyticsData()"

  url = m.config.serviceEndpoints.analyticsData

  http = createObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = createObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.AddHeader("Origin", "https://com.bitmovin.player.roku")

  data = FormatJson(m.top.eventData)

  if http.asyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        print m.tag; "Event data request successful"
      else
        print m.tag; "Event data request failed: "; msg.getfailurereason();" "; msg.getresponsecode();" "; url
        ' TODO handle retry
      end if
      http.asyncCancel()
    else if msg = invalid
      print m.tag; "Event data request failed"
      http.asyncCancel()
    end if
  end if

  m.timer.mark()
end sub
