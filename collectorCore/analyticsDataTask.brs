sub init()
  m.top.functionName = "monitor"

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

  m.AnalyticsDataTaskControlValues = getAnalyticsDataTaskControlValues()
  m.AnalyticsDataTaskFieldNames = getAnlyticsDataTaskFieldNames()
end sub

sub runTask(param = invalid)
  if isTaskRunning() then return

  m.port = CreateObject("roMessagePort")
  m.top.observeFieldScoped(m.AnalyticsDataTaskFieldNames.CHECK_LICENSE, m.port)
  m.top.observeFieldScoped(m.AnalyticsDataTaskFieldNames.SEND_DATA, m.port)
  m.top.observeFieldScoped(m.AnalyticsDataTaskFieldNames.EVENT_DATA, m.port)

  m.top.control = m.AnalyticsDataTaskControlValues.RUN
end sub

sub stopTask(param = invalid)
  m.top.control = m.AnalyticsDataTaskControlValues.STOP

  m.top.unobserveFieldScoped(m.AnalyticsDataTaskFieldNames.CHECK_LICENSE)
  m.top.unobserveFieldScoped(m.AnalyticsDataTaskFieldNames.SEND_DATA)
  m.top.unobserveFieldScoped(m.AnalyticsDataTaskFieldNames.EVENT_DATA)

  if not isInvalid(m.port) then m.port = invalid

end sub

function isTaskRunning(param = invalid)
  return m.top.state = m.AnalyticsDataTaskControlValues.RUN
end function

' Function called when control is set to "RUN" from the Bitmovin Analytics Collector.
sub monitor()
  m.heartbeatTimer.Mark()

  while true
    msg = wait(500, m.port)

    if type(msg) = "roSGNodeEvent"
      field = msg.GetField()
      data = msg.GetData()
      if field = m.AnalyticsDataTaskFieldNames.SEND_DATA and data = true
        if m.isLicensingCallDone = true and m.licensingState = "granted"
          sendAnalyticsEventsFromQueue()
        end if
      else if field = m.AnalyticsDataTaskFieldNames.SEND_DATA
        event = data
        pushToAnalyticsEventsQueue(event)
      else if field = m.AnalyticsDataTaskFieldNames.CHECK_LICENSE and data = true
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

sub destroy()
  clearAnalyticsEventsQueue()
  stopTask()
end sub

sub handleFailedLicensingRequest(responseMsg, status)
  m.licensingState = status

  if responseMsg <> invalid then
    print m.tag; "License Check for Bitmovin Analytics failed because of: "; responseMsg.getFailureReason()
  else
    print m.tag; "License Check for Bitmovin Analytics failed."
  end if

  clearLicensingResponseAndAnalyticsEventsQueue()
  stopTask()
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

sub clearAnalyticsEventsQueue()
  if m.analyticsEventsQueue.Count() = 0 then return
  m.analyticsEventsQueue.Clear()
end sub

sub pushToAnalyticsEventsQueue(event)
  if event = invalid then return

  m.analyticsEventsQueue.Push(event)
  m.heartbeatTimer.Mark()
end sub

sub clearLicensingResponseAndAnalyticsEventsQueue()
  m.licensingResponse = {}
  clearAnalyticsEventsQueue()
end sub
