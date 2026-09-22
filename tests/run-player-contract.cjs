// Exercise the player and backend helpers in the BrightScript interpreter.
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const inputs = ['components/shared/BackendApi.brs', 'components/pages/PlayerPage.brs'];
const source = inputs.map((file, index) => {
    const content = fs.readFileSync(path.join(root, file), 'utf8');
    return content.replace(/sub init\(\)/, `sub fixtureUnusedInit${index}()`);
}).join('\n');
const target = path.join(root, 'build/player-contract-harness.brs');
fs.mkdirSync(path.dirname(target), {recursive: true});
fs.writeFileSync(target, source + '\n' + fs.readFileSync(path.join(__dirname, 'player-contract.brs'), 'utf8'));
const result = spawnSync(process.execPath, [require.resolve('brs/bin/cli.js'), target], {encoding: 'utf8'});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status !== 0 || !/Player contract failures:\s*0/.test(result.stdout || '') || /^FAIL /m.test(result.stdout || '') ? 1 : 0);
