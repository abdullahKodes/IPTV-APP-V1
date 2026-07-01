function onboardingShouldShow() as Boolean
    section = CreateObject("roRegistrySection", "iptvmax_onboarding")
    return section.Read("completed") <> "1"
end function

sub onboardingComplete(path as String)
    section = CreateObject("roRegistrySection", "iptvmax_onboarding")
    section.Write("completed", "1")
    section.Write("path", path)
    section.Write("completedAt", onboardingNowSeconds())
    section.Flush()
end sub

sub onboardingCompleteWithPlaylist()
    onboardingComplete("playlist")
    settings = CreateObject("roRegistrySection", "iptvmax_settings")
    settings.Write("subscription", "Free")
    settings.Write("signedIn", "0")
    settings.Write("userName", "IPTV Viewer")
    settings.Write("userEmail", "Playlist access")
    settings.Flush()
end sub

sub onboardingActivateTrial()
    playlistStoreSetActive(playlistStoreDemoId())

    onboarding = CreateObject("roRegistrySection", "iptvmax_onboarding")
    onboarding.Write("trialStartedAt", onboardingNowSeconds())
    onboarding.Write("trialLengthDays", "7")
    onboarding.Flush()

    settings = CreateObject("roRegistrySection", "iptvmax_settings")
    settings.Write("subscription", "7-Day Trial")
    settings.Write("signedIn", "0")
    settings.Write("userName", "Trial Viewer")
    settings.Write("userEmail", "7-day trial access")
    settings.Flush()

    onboardingComplete("trial")
end sub

sub onboardingRecordPurchaseIntent()
    section = CreateObject("roRegistrySection", "iptvmax_onboarding")
    section.Write("purchaseRequested", "1")
    section.Write("purchaseRequestedAt", onboardingNowSeconds())
    section.Flush()
end sub

function onboardingNowSeconds() as String
    now = CreateObject("roDateTime")
    return now.AsSeconds().toStr()
end function
