const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const cases = [
    ['components/pages/LiveTvPage.brs', 'initializeLiveTvPage', 'startBackendLiveLoad', 'No live channels in this playlist.'],
    ['components/pages/MoviesPage.brs', 'initializeMoviesPage', 'startBackendMoviesLoad', 'No movies in this playlist.'],
    ['components/pages/SeriesPage.brs', 'initializeSeriesPage', 'startBackendSeriesLoad', 'No series in this playlist.']
];

let failures = 0;
function check(passed, message) {
    console.log(`${passed ? 'PASS' : 'FAIL'}  ${message}`);
    if (!passed) failures++;
}

for (const [file, initializer, starter, emptyMessage] of cases) {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    const match = source.match(new RegExp(`sub ${initializer}\\(\\)([\\s\\S]*?)\\nend sub`, 'i'));
    const body = match?.[1] ?? '';
    const renderAt = body.lastIndexOf('render()');
    const startAt = body.lastIndexOf(`if startBackendAfterRender then ${starter}()`);
    check(renderAt >= 0 && startAt > renderAt, `${file} renders initialized state before starting its backend Task`);
    check(source.includes('m.recoveringStartup = true') && body.includes('m.recoveringStartup = true and startBackendAfterRender'), `${file} retries the normal page without restarting the backend Task after a startup exception`);
    check((source.match(new RegExp(emptyMessage.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\$&'), 'g')) || []).length >= 3, `${file} uses its section-specific empty message for every playlist profile`);
    check(!/uiPoster\\([^\\n]+\\)\\r?\\n\\s*\\w+\\.loadDisplayMode\\s*=/.test(source), `${file} sets Poster display mode before assigning artwork URI`);
}

const seriesSource = fs.readFileSync(path.join(root, 'components/pages/SeriesPage.brs'), 'utf8');
const moviesSource = fs.readFileSync(path.join(root, 'components/pages/MoviesPage.brs'), 'utf8');
const moviesXmlSource = fs.readFileSync(path.join(root, 'components/pages/MoviesPage.xml'), 'utf8');
const movieDetailSource = fs.readFileSync(path.join(root, 'components/pages/MovieDetailPage.brs'), 'utf8');
const seriesDetailSource = fs.readFileSync(path.join(root, 'components/pages/SeriesDetailPage.brs'), 'utf8');
const backendTaskSource = fs.readFileSync(path.join(root, 'components/tasks/BackendApiTask.brs'), 'utf8');
const backendApiSource = fs.readFileSync(path.join(root, 'components/shared/BackendApi.brs'), 'utf8');
const appUiSource = fs.readFileSync(path.join(root, 'components/shared/AppUi.brs'), 'utf8');
const liveMapperSource = backendApiSource.match(/function backendApiMapLiveItem\(item as Object[\s\S]*?end function/i)?.[0] ?? '';
for (const [label, source, collection] of [['Movies', moviesSource, 'movies'], ['Series', seriesSource, 'series']]) {
    const schedule = source.match(/sub scheduleBackendQuery\(\)([\s\S]*?)end sub/i)?.[1] ?? '';
    const reload = source.match(/sub reloadBackendQuery\(\)([\s\S]*?)end sub/i)?.[1] ?? '';
    check(schedule.includes('m.backendLoading = true') && schedule.includes(`m.${collection} = []`), `${label} clears stale category rows before showing its loader`);
    check(reload.includes('render()'), `${label} keeps the loader visible while the replacement catalogue loads`);
}
check(moviesSource.includes('uiPosterFit(parent, artUrl') && moviesSource.includes('cardDisplayMode'), 'Movies fits backend poster and logo cards without cropping');
check(moviesSource.includes('backendApiMapMovieChannelItems(items, m.activePlaylistId, (pageNumber - 1) * 50, true)'), 'single-purpose Movies page treats generic M3U channel rows as movie entries');
check(moviesSource.includes('candidate = movieHeroCandidateUrl(movie)') && moviesSource.includes('return mediaFullscreenArtworkUrl(movieCardUrl(movie))'), 'Movies uses explicit background artwork first and can evaluate a non-logo card as a hero fallback');
check(moviesSource.includes('observeField("loadStatus", "onMovieHeroProbeStatusChanged")') && moviesSource.includes('bitmapWidth') && moviesSource.includes('bitmapHeight'), 'Movies hero fallback uses loaded bitmap dimensions');
check(moviesSource.includes('explicitHero = movieExplicitHeroArtworkUrl(movie)') && moviesSource.includes('if explicitHero <> "" then return explicitHero'), 'Movies renders explicit backend hero artwork without the card-dimension probe');
check(moviesSource.includes('moviePreviewTimer.duration = 0.25') && moviesSource.includes('task.request = backendApiGetChannelRequest(channelId)') && moviesSource.includes('onFocusedMoviePreviewLoaded'), 'Movies debounces focused-item detail enrichment for missing title and hero fields');
check((moviesSource.match(/m\.moviePreviewTimer = CreateObject\("roSGNode", "Timer"\)/g) || []).length === 1, 'Movies creates its preview timer once and hero-probe cleanup cannot reset active preview work');
const focusedPreviewLoader = moviesSource.match(/sub loadFocusedMoviePreview\(\)[\s\S]*?end sub/i)?.[0] ?? '';
check(!focusedPreviewLoader.includes('detailPreviewAttempted = true'), 'cancelled focused-movie detail loads remain retryable');
check(moviesXmlSource.includes('pkg:/components/shared/MediaArtwork.brs'), 'Movies page loads the shared artwork eligibility helpers');
check((moviesSource.match(/m\.movieHeroEligibility = \{\}/g) || []).length === 2, 'Movies hero eligibility cache initializes once and has one defensive callback recovery');
check(moviesSource.includes('sub disposePage()\n    clearMovieHeroProbe()') || moviesSource.includes('sub disposePage()\r\n    clearMovieHeroProbe()'), 'Movies page disposes its active artwork probe');
check(moviesSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && moviesSource.includes('uiPosterZoom(m.canvas, heroUrl, 0, 0, 1280, 720'), 'Movies list fits logo fallback on the right and fills real hero artwork');
check(movieDetailSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && movieDetailSource.includes('uiPosterZoom(m.canvas, posterUrl, 0, 0, 1280, 720'), 'Movie Detail follows the same logo-fallback and real-hero display modes');
check(!/uiPoster\([^\n]+\)\r?\n\s*\w+\.loadDisplayMode\s*=/.test(movieDetailSource), 'Movie Detail sets display mode before assigning artwork URI');
check(backendTaskSource.includes('"poster_url", "hero_url", "backdrop_url", "background_url", "fanart_url"'), 'Movie artwork fields survive the SceneGraph task boundary');

check(seriesSource.includes('uiPosterFit(parent, artUrl') && !seriesSource.includes('uiPosterZoom(parent, artUrl') && seriesSource.includes('drawSeriesFallbackPosterAnchor(posterUrl)'), 'Series cards always fit complete artwork without cropping');
const featuredMoviePoster = moviesSource.match(/sub drawFeaturedPoster\(movie as Object[\s\S]*?end sub/i)?.[0] ?? '';
check(featuredMoviePoster.includes('uiPosterFit(parent, posterUrl') && !featuredMoviePoster.includes('uiPosterZoom'), 'Movies featured mini-poster fits the complete artwork without cropping');
const continuePoster = seriesSource.match(/sub drawContinuePoster\(series as Object[\s\S]*?end sub/i)?.[0] ?? '';
check(continuePoster.includes('uiPosterFit(parent, posterUrl') && !continuePoster.includes('uiPosterZoom'), 'Continue Watching Series thumbnail fits the complete card artwork');
check(seriesSource.includes('observeField("loadStatus", "onSeriesHeroProbeStatusChanged")') && seriesSource.includes('bitmapWidth') && seriesSource.includes('bitmapHeight'), 'Series hero eligibility uses loaded bitmap dimensions');
check(seriesSource.includes('explicitHero = mediaFullscreenArtworkUrl(seriesText(series, "heroUrl"))') && seriesSource.includes('if explicitHero <> "" then return explicitHero'), 'Series renders explicit backend hero artwork without the card-dimension probe');
check(seriesSource.includes('seriesPreviewTimer.duration = 0.25') && seriesSource.includes('task.request = backendApiGetSeriesRequest(seriesId)') && seriesSource.includes('onFocusedSeriesPreviewLoaded'), 'Series debounces focused-item detail enrichment when list artwork is missing');
check((seriesSource.match(/m\.seriesPreviewTimer = CreateObject\("roSGNode", "Timer"\)/g) || []).length === 1, 'Series creates its preview timer exactly once');
const focusedSeriesPreviewLoader = seriesSource.match(/sub loadFocusedSeriesPreview\(\)[\s\S]*?end sub/i)?.[0] ?? '';
check(!focusedSeriesPreviewLoader.includes('detailPreviewAttempted = true'), 'cancelled focused-Series detail loads remain retryable');
check((seriesSource.match(/m\.seriesHeroEligibility = \{\}/g) || []).length === 2, 'Series hero eligibility cache initializes once and has one defensive callback recovery');
check(seriesSource.includes('sub disposePage()\n    clearSeriesHeroProbe()') || seriesSource.includes('sub disposePage()\r\n    clearSeriesHeroProbe()'), 'Series page disposes its active artwork probe');
check(seriesDetailSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && seriesDetailSource.includes('uiPosterZoom(m.canvas, posterUrl, 0, 0, 1280, 720'), 'Series Detail fits fallback artwork and fills available hero artwork');
const seriesDetailBackdrop = seriesDetailSource.match(/sub drawBackdrop\(\)[\s\S]*?end sub/i)?.[0] ?? '';
check(seriesDetailBackdrop.indexOf('movies_series_fallback_backdrop_v6.jpg') >= 0 && seriesDetailBackdrop.indexOf('movies_series_fallback_backdrop_v6.jpg') < seriesDetailBackdrop.indexOf('if heroUrl'), 'Series Detail keeps packaged fallback behind slow or failed remote hero artwork');
const zoomPosterHelper = appUiSource.match(/function uiPosterZoom\([\s\S]*?end function/i)?.[0] ?? '';
check(zoomPosterHelper.includes('node.loadingBitmapUri = fallbackUri') && zoomPosterHelper.includes('node.failedBitmapUri = fallbackUri') && zoomPosterHelper.indexOf('node.failedBitmapUri = fallbackUri') < zoomPosterHelper.indexOf('node.uri = uri'), 'Zoom posters assign loading and failed artwork before starting the remote request');
check(seriesSource.includes('seriesListBackdropOpacity(), "pkg:/images/demo/backgrounds/movies_series_fallback_backdrop_v6.jpg")') && seriesDetailSource.includes('1.0, "pkg:/images/demo/backgrounds/movies_series_fallback_backdrop_v6.jpg")'), 'Series list and detail remote heroes use the packaged default while loading or failed');
const prefetchHelper = appUiSource.match(/function uiPrefetchRemoteArtwork\([\s\S]*?end function/i)?.[0] ?? '';
check(prefetchHelper.includes('node.loadWidth = loadW') && prefetchHelper.includes('node.loadHeight = loadH') && prefetchHelper.includes('node.opacity = 0.0'), 'Hero prefetch decodes one hidden remote image at bounded dimensions');
check(moviesSource.includes('prefetchMovieHeroArtwork(dx)') && moviesSource.includes('uiPrefetchRemoteArtwork(m.top, url, 1280, 720)') && moviesSource.includes('clearMovieHeroPrefetch()'), 'Movies prefetches one directional adjacent hero and clears it on lifecycle changes');
check(seriesSource.includes('prefetchSeriesHeroArtwork(dx)') && seriesSource.includes('uiPrefetchRemoteArtwork(m.top, url, 1280, 720)') && seriesSource.includes('clearSeriesHeroPrefetch()'), 'Series prefetches one directional adjacent hero and clears it on lifecycle changes');
check(!/uiPoster\([^\n]+\)\r?\n\s*\w+\.loadDisplayMode\s*=/.test(seriesDetailSource), 'Series Detail sets display mode before assigning artwork URI');
const livePlaybackLoad = fs.readFileSync(path.join(root, 'components/pages/LiveTvPage.brs'), 'utf8').match(/sub startBackendLivePlaybackLoad\(channel as Object[\s\S]*?end sub/i)?.[0] ?? '';
check(/task\.control = "RUN"\s*\r?\nend sub/i.test(livePlaybackLoad), 'Live playback URL lookup preserves already-loaded logo nodes');
check(fs.readFileSync(path.join(root, 'components/pages/LiveTvPage.brs'), 'utf8').includes('uiPosterFit(cardCanvas, posterUrl'), 'Live TV fits provider poster artwork without cropping');
check(liveMapperSource.includes('logoUrl: logoUrl') && liveMapperSource.includes('posterUrl: posterUrl') && liveMapperSource.includes('cardBackgroundUrl: backdropUrl'), 'Live TV mapper retains logo, poster, and backdrop artwork independently');
check(!seriesSource.includes('Press OK for more'), 'Series empty state never hijacks OK for manual pagination');
check(seriesSource.includes('playlistStoreEffectiveContentProfile(m.activePlaylist) = "backend_series"'), 'Series channel fallback runs only for an actual Series profile');
check(seriesSource.includes('nextSeriesPage = m.backendNextCursor') && seriesSource.includes('startBackendSeriesLoad(nextSeriesPage)'), 'Series fallback skips empty channel pages automatically without changing focus');
console.log(`Page startup contract failures: ${failures}`);
process.exit(failures === 0 ? 0 : 1);
