sub init()
  m.tag = "Bitmovin Analytics Collector [analyticsDataTask] "
  m.config = getCollectorCoreConfig()
  m.licensingState = m.top.findNode("licensingState")
  m.isLicensingCallDone = false
  m.analyticsEventsQueue = []
  m.heartbeatTimer = CreateObject("roTimespan")
  m.appInfo = CreateObject("roAppInfo")
  m.licensingUrl = m.config.serviceEndpoints.analyticsLicense
  m.dataUrl = m.config.serviceEndpoints.analyticsData
  m.licensingResponse = {}
  m.analyticsDataTaskPort = CreateObject("roMessagePort")
  m.top.observeFieldScoped("checkLicenseKey", m.analyticsDataTaskPort)
  m.top.observeFieldScoped("sendData", m.analyticsDataTaskPort)
  m.top.observeFieldScoped("eventData", m.analyticsDataTaskPort)
  m.runExecuteLoop = true
  m.top.functionName = "execute"
  m.top.control = "RUN"
end sub

sub execute()
  m.heartbeatTimer.Mark()

  while m.runExecuteLoop
    msg = wait(500, m.analyticsDataTaskPort)

    if type(msg) = "roSGNodeEvent"
      field = msg.GetField()
      data = msg.GetData()
      if field = "sendData" and data = true
        if m.isLicensingCallDone = true and m.licensingState = "granted"
          sendAnalyticsEventsFromQueue()
        end if
      else if field = "eventData"
        event = data
        pushToAnalyticsEventsQueue(event)
      else if field = "checkLicenseKey" and data = true
        ' Get licensing data from collectorCore
        sendAnalyticsLicensingRequest(m.top.licensingData)
      end if
    end if

    if m.top.playerState = "playing" and m.heartbeatTimer.totalMilliseconds() > 59*1000
      parent = m.top.getParent()
      if parent.fireHeartbeat <> invalid
        parent.fireHeartbeat = true
        m.heartbeatTimer.Mark()
      end if
    end if

  end while
end sub

sub handleFailedLicensingRequest(responseMsg, status)
  m.licensingState = status

  if responseMsg <> invalid then
    print m.tag; "License Check for Bitmovin Analytics failed because of: "; responseMsg.getFailureReason()
  else
    print m.tag; "License Check for Bitmovin Analytics failed."
  end if

  clearLicensingResponseAndAnalyticsEventsQueue()
  stopExecuteLoop()
end sub

sub sendAnalyticsLicensingRequest(licensingData)
  http = CreateObject("roUrlTransfer")
  http.setCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
  http.setPort(port)
  http.setUrl(m.licensingUrl)
  http.addHeader("Origin", licensingData.domain)

  data = formatJson(licensingData)

  if http.asyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      responseCode = msg.getResponseCode()
      if responseCode >= 200 and responseCode < 300
        m.licensingResponse = parseJson(msg.getString())
        if m.licensingResponse.status = "granted"
          m.licensingState = m.licensingResponse.status
        else
          handleFailedLicensingRequest(msg, m.licensingResponse.status)
        end if
      else
        handleFailedLicensingRequest(msg, "denied")
      end if
      m.isLicensingCallDone = true
      http.asyncCancel()
    else if msg = invalid
      handleFailedLicensingRequest(invalid, "denied")
      http.asyncCancel()
    end if
  end if

  m.heartbeatTimer.Mark()
end sub

sub sendAnalyticsData(eventData)
  http = CreateObject("roUrlTransfer")
  http.SetCertificatesFile("common:/certs/ca-bundle.crt")
  port = CreateObject("roMessagePort")
  http.setPort(port)
  http.setUrl(m.dataUrl)
  http.AddHeader("Origin", m.top.licensingData.domain)

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
end sub

sub sendAnalyticsEventsFromQueue()
  if m.analyticsEventsQueue.Count() = 0 then return

  m.heartbeatTimer.Mark()
  for each event in m.analyticsEventsQueue
    sendAnalyticsData(event)
  end for
  clearAnalyticsEventsQueue()
end sub

function clearAnalyticsEventsQueue()
  if m.analyticsEventsQueue.Count() = 0 then return false
  m.analyticsEventsQueue.Clear()

  return true
end function

sub pushToAnalyticsEventsQueue(event)
  if event = invalid then return

  m.analyticsEventsQueue.Push(event)
  m.heartbeatTimer.Mark()
end sub

sub clearLicensingResponseAndAnalyticsEventsQueue()
  m.licensingResponse = {}
  clearAnalyticsEventsQueue()
end sub

sub stopExecuteLoop()
  m.runExecuteLoop = false
end sub
