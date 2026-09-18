// Two workarounds bundled here:
// 1. `firebase emulators:exec "node --test tests/"` loses the --test flag
//    somewhere in its own shell-quoting — this wrapper gives emulators:exec
//    a single unquoted command to run instead.
// 2. `node --test <bare directory>` (e.g. `tests/`) fails to find any files
//    on this toolchain ("Cannot find module") even though Node's docs say
//    directories are supported — an explicit glob for the test files works
//    reliably, so that's what we pass instead.
import { spawnSync } from 'node:child_process';

const result = spawnSync('node', ['--test', 'tests/*.test.mjs'], { stdio: 'inherit' });
process.exit(result.status ?? 1);
