sub main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    while true
        msg = Wait(0, port)
        if Type(msg) = "roSGScreenEvent" and msg.IsScreenClosed()
            return
        end if
    end while
end sub
