sub init()
  m.top.url = "https://analytics-ingress-global.bitmovin.com/licensing"
  m.top.data = {
    key : "",
    domain : "",
    analyticsVersion : ""
  }
  m.top.response = ""
  print "in analyticsRequest"
end sub

function doLicensingRequest()
  print "in doLicensingRequest"
  url = m.top.url

  http = createObject("roUrlTransfer")
  http.RetainBodyOnError(true)
  port = createObject("roMessagePort")
  http.setPort(port)
  http.setUrl(url)

  data = FormatJson(m.top.data)

  if http.AsyncPostFromString(data)
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getResponseCode() > 0 and msg.getResponseCode < 400
        m.top.response = msg.getString()
      else
        print "analytics request failed: "; msg.getfailurereason();" "; msg.getresponsecode();" "; m.top.url
        m.top.response = ""
      end if
      http.asyncCancel()
    else if msg = invalid
      print "analytics request failed"
      m.top.response = ""
      http.asyncCancel()
    end if
  end if
end function
