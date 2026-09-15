function mediaFullscreenArtworkUrl(value as Dynamic) as String
    valueType = Type(value)
    if valueType <> "String" and valueType <> "roString" then return ""
    if value = "" or value.len() > 2048 then return ""
    lowered = LCase(value)
    if Left(lowered, 5) = "pkg:/" then return value
    if Left(lowered, 7) = "http://" then return value
    if Left(lowered, 8) = "https://" then return value
    return ""
end function

function mediaArtworkCanFillHero(bitmapWidth as Float, bitmapHeight as Float) as Boolean
    if bitmapWidth < 640 or bitmapHeight < 300 then return false
    aspectRatio = bitmapWidth / bitmapHeight
    return aspectRatio >= 1.45 and aspectRatio <= 2.4
end function