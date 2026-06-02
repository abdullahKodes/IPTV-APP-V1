sub init()
    m.colors = appColors()
    m.currentPage = invalid
    m.currentPageName = ""
    m.pageHost = m.top.findNode("pageHost")
    m.top.backgroundColor = m.colors.bg
    m.top.setFocus(true)

    m.timer = CreateObject("roSGNode", "Timer")
    m.timer.repeat = true
    m.timer.duration = 10
    m.timer.observeField("fire", "onClockTick")
    m.timer.control = "start"

    showPage("HomePage")
end sub

sub onClockTick()
    if m.currentPage <> invalid then
        m.currentPage.callFunc("refreshClock")
    end if
end sub

sub showPage(componentName as String)
    uiClear(m.pageHost)
    m.currentPageName = componentName
    m.currentPage = CreateObject("roSGNode", componentName)
    m.currentPage.observeField("navigateTo", "onPageNavigation")
    m.pageHost.appendChild(m.currentPage)
    m.currentPage.setFocus(true)
end sub

sub onPageNavigation()
    target = m.currentPage.navigateTo
    if target <> invalid and target <> "" then
        showPage(target)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        if m.currentPage <> invalid and m.currentPageName <> "HomePage" then
            showPage("HomePage")
            return true
        end if
    end if

    if m.currentPage <> invalid then
        return m.currentPage.callFunc("handleKey", key)
    end if

    return false
end function
