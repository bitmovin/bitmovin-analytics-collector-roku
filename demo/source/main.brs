sub main()
  m.port = createObject("roMessagePort")
	screen = createObject("roSGScreen")
	screen.setMessagePort(m.port)
	scene = screen.createScene("demo")
	screen.Show()

	while(true)
		msg = wait(0, m.port)
		msgType = type(msg)
		if msgType = "roSGScreenEvent"
			if msg.isScreenClosed() then return
		end if
  end while
end sub
