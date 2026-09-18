// Firebase CLI refuses a rules path outside the emulator's project
// directory, so this harness can't reference ../firestore.rules directly.
// Copy it in fresh before every run instead — firestore.rules at the repo
// root stays the single source of truth.
import { copyFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
copyFileSync(
  resolve(__dirname, '../../firestore.rules'),
  resolve(__dirname, '../firestore.test.rules'),
);
