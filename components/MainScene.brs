sub init()
    m.colors = appColors()
    m.currentPage = invalid
    m.currentPageName = ""
    m.pendingPlayback = invalid
    m.pendingDetail = invalid
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
    if componentName = "PlayerPage" and m.pendingPlayback <> invalid then
        m.currentPage.playbackTitle = m.pendingPlayback.title
        m.currentPage.playbackSubtitle = m.pendingPlayback.subtitle
        m.currentPage.playbackUrl = m.pendingPlayback.url
        m.currentPage.playbackFormat = m.pendingPlayback.streamFormat
        m.currentPage.playbackPosterUrl = m.pendingPlayback.posterUrl
        m.currentPage.returnPage = m.pendingPlayback.returnPage
    else if (componentName = "MovieDetailPage" or componentName = "SeriesDetailPage") and m.pendingDetail <> invalid then
        m.currentPage.detailId = m.pendingDetail.id
        m.currentPage.detailTitle = m.pendingDetail.title
        m.currentPage.detailSubtitle = m.pendingDetail.subtitle
        m.currentPage.detailMeta = m.pendingDetail.meta
        m.currentPage.detailDescription = m.pendingDetail.description
        m.currentPage.detailPosterUrl = m.pendingDetail.posterUrl
        if m.currentPage.hasField("detailHeroUrl") then m.currentPage.detailHeroUrl = m.pendingDetail.heroUrl
        m.currentPage.detailBackdropUrl = m.pendingDetail.backdropUrl
        m.currentPage.detailPlaybackUrl = m.pendingDetail.playbackUrl
        m.currentPage.detailPlaybackFormat = m.pendingDetail.playbackFormat
        m.currentPage.detailReturnPage = m.pendingDetail.returnPage
        m.currentPage.callFunc("syncDetail")
    end if
    m.pageHost.appendChild(m.currentPage)
    m.currentPage.setFocus(true)
end sub

sub onPageNavigation()
    target = m.currentPage.navigateTo
    if target <> invalid and target <> "" then
        if target = "PlayerPage" and m.currentPage.hasField("playbackUrl") then
            m.pendingPlayback = {
                title: m.currentPage.playbackTitle,
                subtitle: m.currentPage.playbackSubtitle,
                url: m.currentPage.playbackUrl,
                streamFormat: m.currentPage.playbackFormat,
                posterUrl: m.currentPage.playbackPosterUrl,
                returnPage: m.currentPage.returnPage
            }
        else if (target = "MovieDetailPage" or target = "SeriesDetailPage") and m.currentPage.hasField("detailTitle") then
            m.pendingDetail = {
                id: m.currentPage.detailId,
                title: m.currentPage.detailTitle,
                subtitle: m.currentPage.detailSubtitle,
                meta: m.currentPage.detailMeta,
                description: m.currentPage.detailDescription,
                posterUrl: m.currentPage.detailPosterUrl,
                heroUrl: m.currentPage.detailHeroUrl,
                backdropUrl: m.currentPage.detailBackdropUrl,
                playbackUrl: m.currentPage.detailPlaybackUrl,
                playbackFormat: m.currentPage.detailPlaybackFormat,
                returnPage: m.currentPage.detailReturnPage
            }
        end if
        showPage(target)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" then
        if m.currentPage <> invalid and m.currentPage.callFunc("handleKey", key) then return true
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
