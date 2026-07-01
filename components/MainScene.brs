sub init()
    m.colors = appColors()
    m.currentPage = invalid
    m.currentPageName = ""
    m.pendingPlayback = invalid
    m.pendingDetail = invalid
    m.pageStack = []
    m.pageHost = m.top.findNode("pageHost")
    m.top.backgroundColor = m.colors.bg
    m.top.setFocus(true)

    m.timer = CreateObject("roSGNode", "Timer")
    m.timer.repeat = true
    m.timer.duration = 10
    m.timer.observeField("fire", "onClockTick")
    m.timer.control = "start"

    if onboardingShouldShow() then
        showPage("WelcomePage")
    else
        showPage("HomePage")
    end if
end sub

sub onClockTick()
    if m.currentPage <> invalid then
        m.currentPage.callFunc("refreshClock")
    end if
end sub

sub showPage(componentName as String)
    if componentName = "HomePage" and onboardingShouldShow() then componentName = "WelcomePage"
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
        if m.currentPage.hasField("detailPlaylistId") then m.currentPage.detailPlaylistId = m.pendingDetail.playlistId
        if m.currentPage.hasField("detailMediaType") then m.currentPage.detailMediaType = m.pendingDetail.mediaType
        if m.currentPage.hasField("detailEpisodeNames") then m.currentPage.detailEpisodeNames = m.pendingDetail.episodeNames
        if m.currentPage.hasField("detailSeasonNames") then m.currentPage.detailSeasonNames = m.pendingDetail.seasonNames
        if m.currentPage.hasField("detailEpisodeDurations") then m.currentPage.detailEpisodeDurations = m.pendingDetail.episodeDurations
        if m.currentPage.hasField("detailActiveEpisodeTitle") then m.currentPage.detailActiveEpisodeTitle = m.pendingDetail.activeEpisodeTitle
        m.currentPage.detailReturnPage = m.pendingDetail.returnPage
        m.currentPage.callFunc("syncDetail")
    end if
    m.pageHost.appendChild(m.currentPage)
    m.currentPage.setFocus(true)
end sub

sub restorePage(history as Object)
    if history = invalid or history.page = invalid then return
    uiClear(m.pageHost)
    m.currentPageName = history.name
    m.currentPage = history.page
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
                playlistId: detailPendingText(m.currentPage, "detailPlaylistId"),
                mediaType: detailPendingText(m.currentPage, "detailMediaType"),
                episodeNames: detailPendingText(m.currentPage, "detailEpisodeNames"),
                seasonNames: detailPendingText(m.currentPage, "detailSeasonNames"),
                episodeDurations: detailPendingText(m.currentPage, "detailEpisodeDurations"),
                activeEpisodeTitle: detailPendingText(m.currentPage, "detailActiveEpisodeTitle"),
                returnPage: m.currentPage.detailReturnPage
            }
        end if
        if m.pageStack.count() > 0 then
            previous = m.pageStack[m.pageStack.count() - 1]
            if previous.name = target then
                restored = m.pageStack.pop()
                restorePage(restored)
                return
            end if
        end if

        if shouldPreservePageForTarget(target) then
            m.pageStack.push({ name: m.currentPageName, page: m.currentPage })
        else
            m.pageStack = []
        end if
        showPage(target)
    end if
end sub

function shouldPreservePageForTarget(target as String) as Boolean
    return target = "MovieDetailPage" or target = "SeriesDetailPage" or target = "PlayerPage"
end function

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

function detailPendingText(page as Object, fieldName as String) as String
    if page = invalid then return ""
    if fieldName = "detailPlaylistId" and page.hasField(fieldName) then return page.detailPlaylistId
    if fieldName = "detailMediaType" and page.hasField(fieldName) then return page.detailMediaType
    if fieldName = "detailEpisodeNames" and page.hasField(fieldName) then return page.detailEpisodeNames
    if fieldName = "detailSeasonNames" and page.hasField(fieldName) then return page.detailSeasonNames
    if fieldName = "detailEpisodeDurations" and page.hasField(fieldName) then return page.detailEpisodeDurations
    if fieldName = "detailActiveEpisodeTitle" and page.hasField(fieldName) then return page.detailActiveEpisodeTitle
    return ""
end function
