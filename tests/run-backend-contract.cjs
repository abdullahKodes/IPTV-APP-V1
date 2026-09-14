// Run actual BrightScript helpers in the optional local brs interpreter.
// Setup: npm.cmd install --prefix build/contract-runtime --no-audit --no-fund --ignore-scripts brs
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const inputs = ['components/shared/BackendApi.brs', 'components/tasks/BackendApiTask.brs', 'components/pages/SeriesDetailPage.brs'];
const source = inputs.map((file, i) => fs.readFileSync(path.join(root, file), 'utf8').replace(/sub init\(\)/, `sub fixtureUnusedInit${i}()`)).join('\n');
const target = path.join(root, 'build/backend-contract-harness.brs');
fs.writeFileSync(target, source + '\n' + fs.readFileSync(path.join(__dirname, 'backend-contract.brs'), 'utf8'));
const result = spawnSync(process.execPath, [path.join(root, 'build/contract-runtime/node_modules/brs/bin/cli.js'), target], {encoding: 'utf8'});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
process.exit(result.status !== 0 || !/Contract failures:\s*0/.test(result.stdout || '') || /^FAIL /m.test(result.stdout || '') ? 1 : 0);
