// Run the Restore Account keyboard and navigation helpers in the local brs interpreter.
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

const root = path.resolve(__dirname, '..');
const inputs = ['components/shared/AppUi.brs', 'components/pages/WelcomePage.brs'];
const source = inputs
    .map((file, index) => fs.readFileSync(path.join(root, file), 'utf8').replace(/sub init\(\)/, `sub keyboardFixtureUnusedInit${index}()`))
    .join('\n');
const target = path.join(root, 'build/welcome-keyboard-contract-harness.brs');
fs.mkdirSync(path.dirname(target), {recursive: true});
fs.writeFileSync(target, source + '\n' + fs.readFileSync(path.join(__dirname, 'welcome-keyboard-contract.brs'), 'utf8'));

const runtime = path.join(root, 'build/contract-runtime/node_modules/brs/bin/cli.js');
const result = spawnSync(process.execPath, [runtime, target], {encoding: 'utf8'});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
const output = result.stdout || '';
process.exit(result.status !== 0 || !/Keyboard contract failures:\s*0/.test(output) || /^FAIL /m.test(output) ? 1 : 0);
