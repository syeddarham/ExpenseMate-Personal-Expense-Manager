/**
 * Enforces the required dependency direction automatically:
 *   Controller -> Service -> Repository -> Database
 * by reading every require() in src/.
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, '..', '..', 'src');

function filesIn(dir) {
  return fs
    .readdirSync(path.join(SRC, dir), { recursive: true })
    .filter((f) => f.endsWith('.js'))
    .map((f) => path.join(dir, f));
}

function requiresOf(file) {
  const code = fs.readFileSync(path.join(SRC, file), 'utf8');
  return [...code.matchAll(/require\(['"]([^'"]+)['"]\)/g)].map((m) => m[1]);
}

function violations(dir, forbidden) {
  const found = [];
  for (const file of filesIn(dir)) {
    for (const dep of requiresOf(file)) {
      if (forbidden.some((re) => re.test(dep))) found.push(`${file} -> ${dep}`);
    }
  }
  return found;
}

test('controllers never touch repositories or the database', () => {
  assert.deepEqual(violations('controllers', [/repositories/, /database/, /config\/db/, /^mysql2/]), []);
});

test('services never touch the database directly or depend on controllers', () => {
  assert.deepEqual(violations('services', [/database/, /config\/db/, /^mysql2/, /controllers/]), []);
});

test('repositories depend on nothing above them', () => {
  assert.deepEqual(violations('repositories', [/services/, /controllers/, /routes/]), []);
});

test('only repositories (and the migration runner) contain SQL', () => {
  const sql = /\b(SELECT\s+[\w*]|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM)\b/;
  const offenders = [...filesIn('controllers'), ...filesIn('services'), ...filesIn('middleware')].filter((f) =>
    sql.test(fs.readFileSync(path.join(SRC, f), 'utf8')),
  );
  assert.deepEqual(offenders, []);
});
