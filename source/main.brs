sub main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    scene.ObserveField("appExit", port)
    screen.Show()

    while true
        msg = Wait(0, port)
        if Type(msg) = "roSGScreenEvent" and msg.IsScreenClosed()
            return
        else if Type(msg) = "roSGNodeEvent" and msg.GetField() = "appExit" and msg.GetData()
            screen.Close()
            return
        end if
    end while
end sub
