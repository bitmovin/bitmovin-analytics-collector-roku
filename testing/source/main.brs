sub Main(args as dynamic)
    ? "Launching with args "
    ? args
    m.args = args

    if (type(Rooibos__Init) = "Function") then Rooibos__Init()

    InitScreen()
end sub


function InitScreen() as void
    'this will be where you setup your typical roku app
    'it will not be launched when running unit tests
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    rootScene = screen.CreateScene("MainScene")
    rootScene.id = "ROOT"

    screen.show()

    SetupGlobals(screen)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                return
            end if
        end if
    end while
end function
