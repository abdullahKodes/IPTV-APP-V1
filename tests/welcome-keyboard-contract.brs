sub main()
    m.restoreKeys = welcomeRestoreKeyboardKeys()
    failures = 0

    failures += keyboardCheck(m.restoreKeys.count() = 40, "restore keyboard has four complete rows")
    expectedLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    for each letter in expectedLetters
        failures += keyboardCheck(keyboardCount(m.restoreKeys, letter) = 1, "restore keyboard contains " + letter + " exactly once")
    end for

    failures += keyboardCheck(m.restoreKeys[24] = "O", "O keeps alphabetical grid position")
    failures += keyboardCheck(m.restoreKeys[35] = "Z", "Z keeps alphabetical grid position")
    failures += keyboardCheck(restoreKeyboardMoveIndex(25, "down") = 35, "down reaches Z")
    failures += keyboardCheck(restoreKeyboardMoveIndex(35, "up") = 25, "up returns from Z")
    failures += keyboardCheck(restoreKeyboardMoveIndex(34, "right") = 35, "right reaches Z")
    failures += keyboardCheck(restoreKeyboardMoveIndex(35, "right") = 36, "right leaves Z for hyphen")
    failures += keyboardCheck(uiPosterIsRemoteUri("https://provider.invalid/oversized-cover.jpg"), "HTTPS provider artwork receives load bounds")
    failures += keyboardCheck(uiPosterIsRemoteUri("http://provider.invalid/logo.png"), "HTTP provider artwork receives load bounds")
    failures += keyboardCheck(not uiPosterIsRemoteUri("pkg:/images/local.jpg"), "packaged artwork keeps its native loading path")

    print "Keyboard contract failures: "; failures
end sub

function keyboardCount(keys as Object, target as String) as Integer
    count = 0
    for each key in keys
        if key = target then count++
    end for
    return count
end function

function keyboardCheck(condition as Boolean, description as String) as Integer
    if condition then
        print "PASS "; description
        return 0
    end if
    print "FAIL "; description
    return 1
end function
