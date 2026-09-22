// Run actual BrightScript helpers with the project's local dev dependency.
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const inputs = ['components/shared/BackendApi.brs', 'components/tasks/BackendApiTask.brs', 'components/shared/PlaylistStore.brs', 'components/shared/MediaData.brs', 'components/shared/FavoriteStore.brs', 'components/shared/ProgressStore.brs', 'components/shared/NavigationHistory.brs', 'components/shared/MediaArtwork.brs', 'components/pages/SeriesDetailPage.brs'];
const source = inputs.map((file, i) => {
    let content = fs.readFileSync(path.join(root, file), 'utf8').replace(/sub init\(\)/, `sub fixtureUnusedInit${i}()`);
    // The optional brs interpreter predates Roku OS 9.4 TRY/CATCH support.
    // Contract tests call the Task's pure helpers, so remove only its guarded entrypoint.
    if (file.endsWith('BackendApiTask.brs')) {
        content = content.replace(/sub runBackendApiRequest\(\)[\s\S]*?end sub/, 'sub fixtureUnusedGuardedTaskEntry()\nend sub');
    }
    return content;
}).join('\n');
const target = path.join(root, 'build/backend-contract-harness.brs');
fs.writeFileSync(target, source + '\n' + fs.readFileSync(path.join(__dirname, 'backend-contract.brs'), 'utf8'));
const result = spawnSync(process.execPath, [require.resolve('brs/bin/cli.js'), target], {encoding: 'utf8'});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status !== 0 || !/Contract failures:\s*0/.test(result.stdout || '') || /^FAIL /m.test(result.stdout || '') ? 1 : 0);
