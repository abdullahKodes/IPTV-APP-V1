sub init()
    m.colors = appColors()
    m.canvas = m.top.findNode("feedbackCanvas")
    m.focusItems = []
    m.focusIndex = 0
    m.previousFocusIndex = 0
    m.settings = settingsStoreLoad()
    m.categories = [
        { id: "feedback", label: "Suggestion" },
        { id: "issue", label: "Playback" },
        { id: "bug", label: "App Bug" },
        { id: "complaint", label: "Complaint" },
        { id: "other", label: "Other" }
    ]
    m.categoryIndex = 0
    m.message = ""
    m.feedbackMessage = ""
    m.feedbackSuccess = true
    m.submitTask = invalid
    m.editing = false
    m.keyboardIndex = 0
    m.keyboardUpper = true
    m.keyboardKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L", ".", "Z", "X", "C", "V", "B", "N", "M", ",", "?", "!", "-", "'", "CASE", "SPACE", "DEL", "CLEAR", "DONE"]
    render()
end sub

sub refreshClock()
    if m.clock <> invalid then
        now = uiNowStrings()
        m.clock.text = now.time
        m.date.text = now.date
    end if
end sub

function handleKey(key as String) as Boolean
    if m.submitTask <> invalid then return true
    if m.editing then return handleKeyboardKey(key)
    if key = "back" then return false
    if key = "left" then move(-1, 0) : return true
    if key = "right" then move(1, 0) : return true
    if key = "up" then move(0, -1) : return true
    if key = "down" then move(0, 1) : return true
    if key = "OK" then activate() : return true
    return false
end function

sub move(dx as Integer, dy as Integer)
    oldFocusIndex = m.focusIndex
    m.focusIndex = uiMoveFocus(m.focusItems, m.focusIndex, dx, dy)
    m.previousFocusIndex = oldFocusIndex
    render()
end sub

sub activate()
    if m.focusIndex < 0 or m.focusIndex >= m.focusItems.count() then return
    item = m.focusItems[m.focusIndex]
    if item.page <> invalid and item.page <> "" then m.top.navigateTo = item.page : return
    if item.action = "category" then
        m.categoryIndex = item.categoryIndex
        render()
        return
    end if
    if item.action = "message" then openKeyboard() : return
    if item.action = "submit" then submitFeedback()
end sub

sub submitFeedback()
    message = cleanFeedbackInput(m.message)
    if message.len() < 10 then
        m.feedbackSuccess = false
        m.feedbackMessage = "Please enter at least 10 characters."
        render()
        return
    end if

    task = CreateObject("roSGNode", "BackendApiTask")
    if task = invalid then
        m.feedbackSuccess = false
        m.feedbackMessage = "Message service is unavailable."
        render()
        return
    end if

    m.message = message
    m.feedbackSuccess = true
    m.feedbackMessage = ""
    task.observeField("response", "onFeedbackSubmitted")
    task.request = backendApiCreateSupportReportRequest(currentCategoryId(), message, feedbackContext())
    m.submitTask = task
    render()
    task.control = "RUN"
end sub

sub onFeedbackSubmitted()
    if m.submitTask = invalid then return
    response = m.submitTask.response
    m.submitTask = invalid

    if backendApiResponseOk(response) then
        m.message = ""
        m.feedbackSuccess = true
        m.feedbackMessage = "Message sent. Thank you."
    else
        m.feedbackSuccess = false
        m.feedbackMessage = backendApiUserMessage(response, "Message could not be sent.")
    end if
    render()
end sub

sub render()
    uiClear(m.canvas)
    m.focusItems = []
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg)
    uiRect(m.canvas, 0, 86, 1280, 634, m.colors.bg, 0.96)
    clockParts = uiTopBar(m.canvas, m.colors)
    m.clock = clockParts.clock
    m.date = clockParts.date
    refreshClock()

    drawFeedbackHeader()
    drawFeedbackPanel()
    drawFeedbackStatus()
    uiApplyFocus(m.canvas, m.focusItems, m.focusIndex)
    if m.editing then drawKeyboardOverlay()
end sub

sub drawFeedbackHeader()
    title = uiLabel(m.canvas, "Feedback", 128, 108, 420, 46, 32, m.colors.text)
    title.font.size = 32
end sub

sub drawFeedbackPanel()
    x = 128
    y = 176
    w = 1024
    h = 438
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", x, y, w, h, 0.88)
    uiLabel(m.canvas, "Category", x + 34, y + 24, 260, 34, 22, m.colors.text)
    drawCategoryButtons(x + 34, y + 72)

    uiLabel(m.canvas, "Message", x + 34, y + 146, 260, 34, 22, m.colors.text)
    drawMessageField(x + 34, y + 194, w - 68, 152)
    drawSubmitButton(x + 34, y + 368, 190, 44)
end sub

sub drawCategoryButtons(x as Integer, y as Integer)
    buttonX = x
    for i = 0 to m.categories.count() - 1
        label = m.categories[i].label
        buttonW = feedbackCategoryButtonWidth(label)
        buttonH = feedbackCategoryButtonHeight(buttonW)
        itemIndex = m.focusItems.count()
        focused = itemIndex = m.focusIndex
        selected = i = m.categoryIndex
        textColor = m.colors.textPurple
        opacity = 0.54
        if selected then
            textColor = m.colors.text
            opacity = 0.78
        end if
        if focused then
            textColor = m.colors.text
            opacity = 0.86
        end if
        buttonY = y
        buttonCanvas = CreateObject("roSGNode", "Group")
        buttonCanvas.id = "feedbackCategoryButton" + itemIndex.toStr()
        buttonCanvas.translation = [buttonX, buttonY]
        m.canvas.appendChild(buttonCanvas)
        uiPoster(buttonCanvas, feedbackCategoryBaseUri(buttonW, selected), 0, 0, buttonW, buttonH, opacity)
        if focused then
            focusOpacity = 0.86
            if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
            focusSurface = uiPoster(buttonCanvas, feedbackCategoryFocusUri(buttonW), 0, 0, buttonW, buttonH, focusOpacity)
            focusSurface.id = "feedbackCategoryFocus" + itemIndex.toStr()
            if m.previousFocusIndex <> itemIndex then animateFeedbackButtonFocus(m.canvas, focusSurface, 0.86)
        end if
        uiScaledLabel(buttonCanvas, label, 8, 0, buttonW - 16, buttonH, 12, textColor, "center", 0.70)
        m.focusItems.push({ x: buttonX, y: buttonY, w: buttonW, h: buttonH, row: 1, col: i + 1, page: "", action: "category", categoryIndex: i, mode: "manual", noFocusShift: true })
        buttonX += buttonW + 22
    end for
end sub

function feedbackCategoryButtonWidth(label as String) as Integer
    if label = invalid then return 108
    if label.len() <= 3 then return 86
    if label.len() <= 5 then return 108
    if label.len() <= 8 then return 130
    return 156
end function

function feedbackCategoryButtonHeight(w as Integer) as Integer
    return 34
end function

function feedbackCategoryBaseUri(w as Integer, selected as Boolean) as String
    suffix = feedbackCategoryAssetWidth(w)
    if selected then return "pkg:/images/ui/feedback_category_" + suffix + "x34_selected.png"
    return "pkg:/images/ui/feedback_category_" + suffix + "x34_base.png"
end function

function feedbackCategoryFocusUri(w as Integer) as String
    return "pkg:/images/ui/feedback_category_" + feedbackCategoryAssetWidth(w) + "x34_focus.png"
end function

function feedbackCategoryAssetWidth(w as Integer) as String
    if w <= 90 then return "86"
    if w <= 112 then return "108"
    if w <= 134 then return "130"
    return "156"
end function

sub drawMessageField(x as Integer, y as Integer, w as Integer, h as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    fieldUri = "pkg:/images/ui/feedback_message_base_956x152.png"
    opacity = 0.94
    if focused then
        fieldUri = "pkg:/images/ui/feedback_message_focus_956x152.png"
        opacity = 0.98
    end if
    uiPoster(m.canvas, fieldUri, x, y, w, h, opacity)
    text = feedbackPreview(m.message, "Select to type your message.")
    textColor = m.colors.text
    if m.message = "" then textColor = m.colors.textDim
    uiScaledLabel(m.canvas, text, x + 22, y + 12, w - 44, 56, 15, textColor, "left", 0.74)
    countText = m.message.len().toStr() + " / 400"
    uiScaledLabel(m.canvas, countText, x + w - 116, y + h - 34, 90, 22, 10, m.colors.textDim, "right", 0.66)
    m.focusItems.push({ x: x, y: y, w: w, h: h, row: 2, col: 1, page: "", action: "message", mode: "manual", noFocusShift: true })
end sub

sub drawSubmitButton(x as Integer, y as Integer, w as Integer, h as Integer)
    itemIndex = m.focusItems.count()
    focused = itemIndex = m.focusIndex
    textColor = m.colors.text
    buttonCanvas = CreateObject("roSGNode", "Group")
    buttonCanvas.id = "feedbackSubmitButton" + itemIndex.toStr()
    buttonCanvas.translation = [x, y]
    m.canvas.appendChild(buttonCanvas)
    uiPoster(buttonCanvas, "pkg:/images/ui/feedback_submit_base_190x44.png", 0, 0, w, h, 0.96)
    if focused then
        textColor = m.colors.text
        focusOpacity = 0.82
        if m.previousFocusIndex <> itemIndex then focusOpacity = 0.0
        focusSurface = uiPoster(buttonCanvas, "pkg:/images/ui/feedback_submit_focus_190x44.png", 0, 0, w, h, focusOpacity)
        focusSurface.id = "feedbackSubmitFocus" + itemIndex.toStr()
        if m.previousFocusIndex <> itemIndex then animateFeedbackButtonFocus(m.canvas, focusSurface, 0.82)
    end if
    uiScaledLabel(buttonCanvas, "Send Message", 16, 0, w - 32, h, 14, textColor, "center", 0.74)
    m.focusItems.push({ x: x, y: y, w: w, h: h, row: 3, col: 1, page: "", action: "submit", mode: "manual", noFocusShift: true })
end sub

sub animateFeedbackButtonFocus(parent as Object, focusSurface as Object, finalOpacity as Float)
    animation = CreateObject("roSGNode", "Animation")
    animation.duration = 0.14
    animation.easeFunction = "outQuad"

    opacityAnimation = animation.createChild("FloatFieldInterpolator")
    opacityAnimation.key = [0.0, 1.0]
    opacityAnimation.keyValue = [0.0, finalOpacity]
    opacityAnimation.fieldToInterp = focusSurface.id + ".opacity"

    parent.appendChild(animation)
    animation.control = "start"
end sub

sub drawFeedbackStatus()
    if m.feedbackMessage = "" then return
    color = m.colors.textGreen
    if not m.feedbackSuccess then color = "0xFFB2A8FF"
    uiScaledLabel(m.canvas, m.feedbackMessage, 180, 628, 920, 28, 12, color, "left", 0.72)
end sub

sub openKeyboard()
    m.editing = true
    m.keyboardIndex = 0
    m.feedbackMessage = ""
    render()
end sub

sub closeKeyboard()
    m.editing = false
    render()
end sub

function handleKeyboardKey(key as String) as Boolean
    cols = 10
    if key = "back" then closeKeyboard() : return true
    nextIndex = uiKeyboardMoveIndex(m.keyboardKeys, m.keyboardIndex, key, cols)
    if nextIndex <> m.keyboardIndex then m.keyboardIndex = nextIndex : render() : return true
    if key = "OK" then pressKeyboardKey() : return true
    return true
end function

sub pressKeyboardKey()
    selected = m.keyboardKeys[m.keyboardIndex]
    if selected = "DONE" then closeKeyboard() : return
    if selected = "CASE" then
        m.keyboardUpper = not m.keyboardUpper
        render()
        return
    end if
    if selected = "CLEAR" then
        m.message = ""
    else if selected = "DEL" then
        if m.message.len() > 0 then m.message = Left(m.message, m.message.len() - 1)
    else if selected = "SPACE" then
        if m.message.len() < 400 then m.message += " "
    else
        if m.message.len() < 400 then m.message += uiKeyboardInputText(selected, m.keyboardUpper)
    end if
    render()
end sub

sub drawKeyboardOverlay()
    uiRect(m.canvas, 0, 0, 1280, 720, m.colors.bg, 0.88)
    x = 220
    y = 104
    w = 840
    h = 524
    uiPoster(m.canvas, "pkg:/images/ui/rr_840x524_panel_purpleLine.png", x, y, w, h, 0.98)
    titleLabel = uiLabel(m.canvas, "Feedback Message", x + 40, y + 30, w - 80, 38, 24, m.colors.textGreen, "center")
    titleLabel.font.size = 24
    uiPoster(m.canvas, "pkg:/images/ui/rr_680x168_panel_whiteLine.png", x + 80, y + 96, 680, 92, 0.90)
    displayText = feedbackPreview(m.message, "Type your message")
    codeColor = m.colors.text
    if m.message = "" then codeColor = m.colors.textDim
    uiScaledLabel(m.canvas, displayText, x + 104, y + 108, 632, 52, 15, codeColor, "left", 0.74)
    uiScaledLabel(m.canvas, m.message.len().toStr() + " / 400", x + 620, y + 158, 116, 22, 10, m.colors.textDim, "right", 0.66)
    drawFeedbackKeyboard(x + 58, y + 236)
end sub

sub drawFeedbackKeyboard(startX as Integer, startY as Integer)
    keyW = 70
    keyH = 36
    gap = 7
    for i = 0 to m.keyboardKeys.count() - 1
        keyLabel = m.keyboardKeys[i]
        keyRect = uiKeyboardKeyRect(m.keyboardKeys, i, startX, startY, keyW, keyH, gap)
        uiDrawKeyboardKey(m.canvas, keyLabel, uiKeyboardDisplayText(keyLabel, m.keyboardUpper), keyRect.x, keyRect.y, keyRect.w, keyRect.h, i = m.keyboardIndex, m.colors)
    end for
end sub

function currentCategoryId() as String
    if m.categoryIndex < 0 or m.categoryIndex >= m.categories.count() then return "feedback"
    return m.categories[m.categoryIndex].id
end function

function feedbackContext() as Object
    active = playlistStoreActive()
    return {
        screen: "feedback",
        category_label: m.categories[m.categoryIndex].label,
        active_playlist_id: playlistStoreText(active, "id"),
        active_playlist_title: playlistStoreText(active, "title"),
        subscription: settingsStoreText(m.settings, "subscription", "Preview")
    }
end function

function feedbackPreview(value as String, fallback as String) as String
    text = cleanFeedbackInput(value)
    if text = "" then return fallback
    if text.len() <= 150 then return text
    return Left(text, 147) + "..."
end function

function cleanFeedbackInput(value as Dynamic) as String
    if value = invalid then return ""
    if Type(value) <> "String" and Type(value) <> "roString" then return ""
    text = value
    while text.len() > 0 and Left(text, 1) = " "
        text = Right(text, text.len() - 1)
    end while
    while text.len() > 0 and Right(text, 1) = " "
        text = Left(text, text.len() - 1)
    end while
    return text
end function
