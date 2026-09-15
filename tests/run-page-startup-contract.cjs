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
const movieDetailSource = fs.readFileSync(path.join(root, 'components/pages/MovieDetailPage.brs'), 'utf8');
const seriesDetailSource = fs.readFileSync(path.join(root, 'components/pages/SeriesDetailPage.brs'), 'utf8');
const backendTaskSource = fs.readFileSync(path.join(root, 'components/tasks/BackendApiTask.brs'), 'utf8');
for (const [label, source, collection] of [['Movies', moviesSource, 'movies'], ['Series', seriesSource, 'series']]) {
    const schedule = source.match(/sub scheduleBackendQuery\(\)([\s\S]*?)end sub/i)?.[1] ?? '';
    const reload = source.match(/sub reloadBackendQuery\(\)([\s\S]*?)end sub/i)?.[1] ?? '';
    check(schedule.includes('m.backendLoading = true') && schedule.includes(`m.${collection} = []`), `${label} clears stale category rows before showing its loader`);
    check(reload.includes('render()'), `${label} keeps the loader visible while the replacement catalogue loads`);
}
check(moviesSource.includes('uiPosterFit(parent, artUrl') && moviesSource.includes('cardDisplayMode'), 'Movies fits backend poster and logo cards without cropping');
check(moviesSource.includes('backendApiMapMovieChannelItems(items, m.activePlaylistId, (pageNumber - 1) * 50, true)'), 'single-purpose Movies page treats generic M3U channel rows as movie entries');
check(!moviesSource.includes('movieListHeroArtworkUrl') && moviesSource.includes('heroUrl = movieHeroArtworkUrl(movie)'), 'Movies list uses only mapped hero or backdrop artwork as its full-screen background');
check(moviesSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && moviesSource.includes('uiPosterZoom(m.canvas, heroUrl, 0, 0, 1280, 720'), 'Movies list fits logo fallback on the right and fills real hero artwork');
check(movieDetailSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && movieDetailSource.includes('uiPosterZoom(m.canvas, posterUrl, 0, 0, 1280, 720'), 'Movie Detail follows the same logo-fallback and real-hero display modes');
check(!/uiPoster\([^\n]+\)\r?\n\s*\w+\.loadDisplayMode\s*=/.test(movieDetailSource), 'Movie Detail sets display mode before assigning artwork URI');
check(backendTaskSource.includes('"poster_url", "hero_url", "backdrop_url", "background_url", "fanart_url"'), 'Movie artwork fields survive the SceneGraph task boundary');

check(seriesSource.includes('uiPosterFit(parent, artUrl') && seriesSource.includes('drawSeriesFallbackPosterAnchor(posterUrl)'), 'Series cards and default-background artwork use uncropped fit rendering');
const continuePoster = seriesSource.match(/sub drawContinuePoster\(series as Object[\s\S]*?end sub/i)?.[0] ?? '';
check(continuePoster.includes('uiPosterFit(parent, posterUrl') && !continuePoster.includes('uiPosterZoom'), 'Continue Watching Series thumbnail fits the complete card artwork');
check(seriesSource.includes('observeField("loadStatus", "onSeriesHeroProbeStatusChanged")') && seriesSource.includes('bitmapWidth') && seriesSource.includes('bitmapHeight'), 'Series hero eligibility uses loaded bitmap dimensions');
check((seriesSource.match(/m\.seriesHeroEligibility = \{\}/g) || []).length === 2, 'Series hero eligibility cache initializes once and has one defensive callback recovery');
check(seriesSource.includes('sub disposePage()\n    clearSeriesHeroProbe()') || seriesSource.includes('sub disposePage()\r\n    clearSeriesHeroProbe()'), 'Series page disposes its active artwork probe');
check(seriesDetailSource.includes('uiPosterFit(m.canvas, posterUrl, x, y, w, h') && seriesDetailSource.includes('uiPosterZoom(m.canvas, posterUrl, 0, 0, 1280, 720'), 'Series Detail fits fallback artwork and fills available hero artwork');
check(!/uiPoster\([^\n]+\)\r?\n\s*\w+\.loadDisplayMode\s*=/.test(seriesDetailSource), 'Series Detail sets display mode before assigning artwork URI');
check(!seriesSource.includes('Press OK for more'), 'Series empty state never hijacks OK for manual pagination');
check(seriesSource.includes('playlistStoreEffectiveContentProfile(m.activePlaylist) = "backend_series"'), 'Series channel fallback runs only for an actual Series profile');
check(seriesSource.includes('nextSeriesPage = m.backendNextCursor') && seriesSource.includes('startBackendSeriesLoad(nextSeriesPage)'), 'Series fallback skips empty channel pages automatically without changing focus');
console.log(`Page startup contract failures: ${failures}`);
process.exit(failures === 0 ? 0 : 1);
