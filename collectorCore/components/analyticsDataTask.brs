sub init()
  m.tag = "[analyticsDataTask] "
  m.config = getCollectorCoreConfig()
  m.deviceinfo = CreateObject("roDeviceInfo")
  m.licensingState = m.top.findNode("licensingState")
  m.timer = CreateObject("roTimespan")
  m.top.url = m.config.serviceEndpoints.analyticsLicense
  m.top.licensingData = {
    key : "d1a494b6-cbc2-4ba1-9218-f6d5e29f7cc1",
    domain : "com.bitmovin.player.roku",
    analyticsVersion : "0.1.0"
  }
  m.licensingResponse = {}
  m.top.functionName = "execute"
  m.top.control = "RUN"
end sub

sub execute()
  url = m.top.url

  http = CreateObject("roUrlTransfer")
  http.setCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
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
        m.licensingResponse = {}
      end if
      http.asyncCancel()
    else if msg = invalid
      m.licensingResponse = {}
      http.asyncCancel()
    end if
  end if

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
  url = m.config.serviceEndpoints.analyticsData

  http = CreateObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.AddHeader("Origin", "https://com.bitmovin.player.roku")

  data = FormatJson(m.top.eventData)

  if http.asyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        ' Event data request successful!
      else
        ' Event data request failed
        ' TODO handle retry
      end if
      http.asyncCancel()
    else if msg = invalid
      ' Event data request failed
      http.asyncCancel()
    end if
  end if

  m.timer.mark()
end sub
