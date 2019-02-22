sub init()
  m.isVerified = false
  m.isFirstRequest = true
  m.top.url = "https://analytics-ingress-global.bitmovin.com/licensing"
  m.top.data = {
    key : "d1a494b6-cbc2-4ba1-9218-f6d5e29f7cc1",
    domain : "com.bitmovin.player.roku",
    analyticsVersion : "0.1.0"
  }
  m.top.response = ""
  print "in analyticsRequest"
  m.top.functionName = "doLicensingRequest"
  m.analyticsRequest.control = "RUN"
end sub

sub doLicensingRequest()
  print "in doLicensingRequest"

  if m.isFirstRequest
    m.isFirstRequest = false

    url = m.top.url

    http = createObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    port = createObject("roMessagePort")
    http.setPort(port)
    http.setUrl(url)
    http.AddHeader("Origin", "https://com.bitmovin.player.roku")

    data = FormatJson(m.top.data)

    if http.AsyncPostFromString(data)
      msg = wait(0, port)
      if type(msg) = "roUrlEvent"
        if msg.getResponseCode() > 0 and msg.getResponseCode() < 400
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
  end if

  if isVerified
    print "response: ";m.top.response
  end if
end sub
