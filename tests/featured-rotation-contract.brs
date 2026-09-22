sub main()
    m.failures = 0
    movies = [
        {id: "a", title: "A Complete Film", duration: "1 hour 42 minutes", posterUrl: "pkg:/a.jpg", backendChannelId: "a", artworkRole: "poster"},
        {id: "no-title", title: "Movie", duration: "1 hour", posterUrl: "pkg:/b.jpg", backendChannelId: "b", artworkRole: "poster"},
        {id: "no-runtime", title: "Missing Runtime", posterUrl: "pkg:/c.jpg", backendChannelId: "c", artworkRole: "poster"},
        {id: "logo", title: "Logo Only", duration: "90 min", posterUrl: "pkg:/logo.jpg", backendChannelId: "d", artworkRole: "logo"},
        {id: "e", title: "Another Complete Film", duration: "2h 10m", cardUrl: "pkg:/e.jpg", streamUrl: "https://example.invalid/e.mp4"},
        {id: "no-art", title: "Missing Poster", duration: "1 hour", backendChannelId: "f"},
        {title: "Missing ID", duration: "1 hour", posterUrl: "pkg:/g.jpg", streamUrl: "https://example.invalid/g.mp4"}
    ]
    check(selectFeaturedMovieIndex(movies, "") = 0, "backend movie with poster title and runtime qualifies without a catalog stream URL")
    check(selectFeaturedMovieIndex(movies, "a") = 4, "next visit skips incomplete movies")
    check(selectFeaturedMovieIndex(movies, "e") = 0, "last complete movie wraps to the first")
    check(selectFeaturedMovieIndex(movies, "no-title") = 0, "ineligible previous movie starts at the first complete card")
    check(selectFeaturedMovieIndex([], "a") = -1, "empty catalog has no featured selection")
    logoOnly = {id: "logo-only", title: "Logo Film", duration: "1 hour", logoUrl: "pkg:/logo.png", backendChannelId: "logo-only"}
    check(movieCardUrl(logoOnly) = "pkg:/logo.png", "movie cards preserve logo artwork")
    check(selectFeaturedMovieIndex([logoOnly], "") = -1, "logo-only movies do not replace verified featured posters")
    check(selectFeaturedMovieIndex([{id: "x", title: "Incomplete Film", posterUrl: "pkg:/x.jpg", backendChannelId: "x"}], "") = -1, "runtime is required before showing a featured card")
    rotationPool = []
    for i = 1 to 7
        rotationPool.push({id: i.toStr(), title: "Film " + i.toStr(), duration: "1 hour", posterUrl: "pkg:/poster.jpg", backendChannelId: i.toStr(), artworkRole: "poster"})
    end for
    check(selectFeaturedMovieIndex(rotationPool, "5") = 0, "rotation is limited to five qualifying movies")
    check(selectFeaturedMovieIndex(rotationPool, "4") = 4, "fifth qualifying movie remains in the rotation")
    print "Featured rotation failures: "; m.failures
end sub

sub check(condition as Boolean, label as String)
    if condition then
        print "PASS "; label
    else
        m.failures += 1
        print "FAIL "; label
    end if
end sub