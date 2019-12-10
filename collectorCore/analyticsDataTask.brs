sub init()
  m.tag = "[analyticsDataTask] "
  m.config = getCollectorCoreConfig()
  m.deviceinfo = CreateObject("roDeviceInfo")
  m.licensingState = m.top.findNode("licensingState")
  m.isLicensingCallDone = false
  m.unsentAnalyticEvents = []
  m.timer = CreateObject("roTimespan")
  m.appInfo = CreateObject("roAppInfo")
  m.top.url = m.config.serviceEndpoints.analyticsLicense
  m.licensingResponse = {}
  m.top.functionName = "execute"
  m.top.control = "RUN"
end sub

sub execute()
  url = m.top.url

  analyticsDataTaskPort = CreateObject("roMessagePort")
  m.top.observeFieldScoped("sendData", analyticsDataTaskPort)
  m.top.observeFieldScoped("eventData", analyticsDataTaskPort)

  http = CreateObject("roUrlTransfer")
  http.setCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.addHeader("Origin", m.appInfo.getID())

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
        m.unsentAnalyticEvents.Clear()
      end if
      m.isLicensingCallDone = true
      http.asyncCancel()
    else if msg = invalid
      m.licensingResponse = {}
      http.asyncCancel()
    end if
  end if

  if m.licensingState <> "granted"
    m.unsentAnalyticEvents.Clear()
    return
  end if

  m.timer.Mark()

  while true
    msg = wait(500, analyticsDataTaskPort)

    if type(msg) = "roSGNodeEvent"
      if msg.GetField() = "sendData"
        if msg.GetData() = true
          if m.isLicensingCallDone = false
            m.unsentAnalyticEvents.Push(m.top.eventData)
          else
            sendUnsentAnalyticEvents()
          end if
        end if
      else if msg.GetField() = "eventData"
        event = msg.GetData()
        m.unsentAnalyticEvents.Push(event)
      end if
    end if

    if m.top.playerState = "playing" and m.timer.totalMilliseconds() > 59*1000
      parent = m.top.getParent()
      if parent.fireHeartbeat <> invalid
        parent.fireHeartbeat = true
      end if
    end if

  end while
end sub

sub sendAnalyticsData(eventData)
  url = m.config.serviceEndpoints.analyticsData
  http = CreateObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)
  http.AddHeader("Origin", m.appInfo.getID())

  data = FormatJson(eventData)

  if http.asyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() >= 200 and msg.getResponseCode() < 300
        ' Event data request successful!
      else
        ' Event data request failed
      end if
      http.asyncCancel()
    else if msg = invalid
      ' Event data request failed
      http.asyncCancel()
    end if
  end if

  m.timer.mark()
end sub

sub sendUnsentAnalyticEvents()
  if m.unsentAnalyticEvents.Count() = 0 then return
  for each event in m.unsentAnalyticEvents
    sendAnalyticsData(event)
  end for
  m.unsentAnalyticEvents.Clear()
end sub
