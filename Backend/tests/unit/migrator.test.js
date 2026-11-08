const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { Migrator, checksum } = require('../../src/database/migrator');

function tempDir(files) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'migrations-'));
  for (const [name, sql] of Object.entries(files)) fs.writeFileSync(path.join(dir, name), sql);
  return dir;
}

test('loadMigrations: pairs up/down files, sorts by version and ignores other files', () => {
  const dir = tempDir({
    '002_second.up.sql': 'SELECT 2;',
    '001_first.up.sql': 'SELECT 1;',
    '001_first.down.sql': 'SELECT -1;',
    'README.md': 'ignored',
  });
  const migrations = new Migrator({ db: { name: 'x' }, dir }).loadMigrations();
  assert.deepEqual(
    migrations.map((m) => [m.version, m.name, !!m.down]),
    [
      ['001', 'first', true],
      ['002', 'second', false],
    ],
  );
});

test('loadMigrations: a down file without an up file is an error', () => {
  const dir = tempDir({ '003_orphan.down.sql': 'SELECT 1;' });
  assert.throws(() => new Migrator({ db: { name: 'x' }, dir }).loadMigrations(), /no \.up\.sql/);
});

test('checksum: line endings do not matter, content does', () => {
  assert.equal(checksum('a\r\nb'), checksum('a\nb'));
  assert.notEqual(checksum('a\nb'), checksum('a\nc'));
});

test('the real migrations directory is well formed', () => {
  const migrations = new Migrator({ db: { name: 'x' } }).loadMigrations();
  assert.deepEqual(
    migrations.map((m) => m.version),
    ['001', '002'],
  );
  assert.ok(migrations.find((m) => m.version === '002').down, '002 must be reversible');
});
