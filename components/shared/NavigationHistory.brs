function navigationHistoryKeepsPageNode(target as String, currentName as String) as Boolean
    if target = "MovieDetailPage" or target = "SeriesDetailPage" or target = "PlayerPage" then return true
    if currentName = "SubscriptionPage" and target = "WelcomePage" then return true
    return false
end function

function navigationHistoryEntry(currentName as String, currentPage as Dynamic, target as String) as Object
    entry = { name: currentName, page: invalid }
    if navigationHistoryKeepsPageNode(target, currentName) then entry.page = currentPage
    return entry
end function

function navigationTrimHistory(entries as Object, maximum as Integer) as Object
    if Type(entries) <> "roArray" then return []
    if maximum < 1 then return []
    while entries.count() > maximum
        entries.shift()
    end while
    return entries
end function
