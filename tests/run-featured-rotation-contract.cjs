const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'components/pages/MoviesPage.brs'), 'utf8');
const names = ['selectFeaturedMovieIndex', 'movieIsSpotlightEligible', 'movieHasPlayback', 'movieCardUrl', 'movieText', 'movieFlag', 'movieValue'];
const functions = names.map((name) => {
    const match = source.match(new RegExp('function ' + name + '\\([\\s\\S]*?end function', 'i'));
    if (!match) throw new Error('Missing featured helper: ' + name);
    return match[0];
}).join('\n\n');
const backendSource = fs.readFileSync(path.join(root, 'components/shared/BackendApi.brs'), 'utf8');
const target = path.join(root, 'build/featured-rotation-contract-harness.brs');
fs.writeFileSync(target, backendSource + '\n' + functions + '\n' + fs.readFileSync(path.join(__dirname, 'featured-rotation-contract.brs'), 'utf8'));
const result = spawnSync(process.execPath, [require.resolve('brs/bin/cli.js'), target], {encoding: 'utf8'});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status !== 0 || !/Featured rotation failures:\s*0/.test(result.stdout || '') || /^FAIL /m.test(result.stdout || '') ? 1 : 0);