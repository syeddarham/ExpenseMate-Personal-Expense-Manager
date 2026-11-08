#!/usr/bin/env node
/**
 * Before/after maintainability measurements for Assignment 02.
 *
 *   node Assignment02/metrics/measure.js            (from the repository root)
 *
 * Checks out the Assignment 01 baseline (tag a01-baseline) into a temporary
 * git worktree and measures it and the current working tree with the same
 * tools:
 *   - cyclomatic complexity per function: ESLint 9 `complexity` rule
 *   - duplicated code: jscpd (min 50 tokens)
 *   - size: non-blank lines, functions per file
 *   - dependency separation: files outside the repository layer that run
 *     SQL or import the database pool
 * Results: Assignment02/evidence/metrics.json and metrics.txt
 */
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const REPO = path.resolve(__dirname, '..', '..');
const OUT = path.join(REPO, 'Assignment02', 'evidence');
const ESLINT = 'eslint@9.39.5';
const JSCPD = 'jscpd@4.0.5';

function sh(cmd, args, opts = {}) {
  try {
    return execFileSync(cmd, args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'], ...opts });
  } catch (err) {
    if (opts.allowFail) return err.stdout || '';
    throw err;
  }
}

function jsFiles(dir) {
  return fs
    .readdirSync(dir, { recursive: true })
    .filter((f) => f.endsWith('.js'))
    .map((f) => path.join(dir, f));
}

function nonBlankLines(file) {
  return fs.readFileSync(file, 'utf8').split('\n').filter((l) => l.trim() !== '').length;
}

/** ESLint complexity rule with threshold 0 reports every function's complexity. */
function complexity(srcDir) {
  const raw = sh(
    'npx',
    ['-y', ESLINT, '--no-config-lookup', '--format', 'json', '--rule', '{"complexity":["warn",0]}', '.'],
    { allowFail: true, cwd: srcDir }, // ESLint 9 ignores files outside its cwd
  );
  const results = JSON.parse(raw);
  const functions = [];
  for (const file of results) {
    for (const m of file.messages) {
      const match = /complexity of (\d+)/.exec(m.message);
      if (!match) continue;
      const name = (/^(.*?) has a complexity/.exec(m.message) || [])[1] || 'function';
      functions.push({ file: path.relative(fs.realpathSync(srcDir), file.filePath), line: m.line, name, complexity: Number(match[1]) });
    }
  }
  functions.sort((a, b) => b.complexity - a.complexity);
  const values = functions.map((f) => f.complexity);
  const avg = values.reduce((s, v) => s + v, 0) / values.length;
  return {
    functions: values.length,
    average: Number(avg.toFixed(2)),
    max: values[0],
    over10: values.filter((v) => v > 10).length,
    top5: functions.slice(0, 5).map((f) => `${f.file}:${f.line} ${f.name} (${f.complexity})`),
  };
}

/** jscpd duplicated-code percentage for one directory or file list. */
function duplication(paths, format) {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'jscpd-'));
  sh(
    'npx',
    ['-y', JSCPD, '--silent', '--min-tokens', '50', '--format', format, '--reporters', 'json', '--output', out, ...paths],
    { allowFail: true, cwd: os.tmpdir() },
  );
  const report = JSON.parse(fs.readFileSync(path.join(out, 'jscpd-report.json'), 'utf8'));
  const total = report.statistics.total;
  return { clones: total.clones, duplicatedLines: total.duplicatedLines, lines: total.lines, percentage: Number(total.percentage.toFixed(2)) };
}

/**
 * Files outside repositories/database/config that run SQL or import the pool.
 * container.js (composition root, Assignment 02) is excluded: it only creates
 * the pool and passes it to the repositories; it runs no queries.
 */
function directDbAccess(srcDir) {
  const allowed = /^(repositories\/|database\/|config\/|container\.js$)/;
  const sql = /\b(SELECT\s+[\w*]|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM)\b/;
  return jsFiles(srcDir)
    .map((f) => path.relative(srcDir, f))
    .filter((rel) => !allowed.test(rel))
    .filter((rel) => {
      const code = fs.readFileSync(path.join(srcDir, rel), 'utf8');
      return sql.test(code) || /require\([^)]*config\/db['"]\)/.test(code);
    });
}

function backendMetrics(backendDir) {
  const src = path.join(backendDir, 'src');
  const files = jsFiles(src);
  const controllers = files.filter((f) => f.includes(`${path.sep}controllers${path.sep}`));
  return {
    files: files.length,
    nonBlankLines: files.reduce((s, f) => s + nonBlankLines(f), 0),
    controllerLines: controllers.reduce((s, f) => s + nonBlankLines(f), 0),
    complexity: complexity(src),
    duplication: duplication([src], 'javascript'),
    filesWithDirectDbAccess: directDbAccess(src),
  };
}

function apiServiceMetrics(file) {
  const code = fs.readFileSync(file, 'utf8');
  return {
    nonBlankLines: nonBlankLines(file),
    tryCatchBlocks: (code.match(/\btry\s*\{/g) || []).length,
    jsonDecodeCalls: (code.match(/jsonDecode\(/g) || []).length,
    directHttpCalls: (code.match(/\bhttp\.(get|post|put|delete)\(/g) || []).length,
    duplication: duplication([file], 'dart'),
  };
}

function main() {
  const worktree = fs.mkdtempSync(path.join(os.tmpdir(), 'a01-metrics-'));
  sh('git', ['-C', REPO, 'worktree', 'add', '--detach', worktree, 'a01-baseline']);
  try {
    fs.rmSync(path.join(worktree, 'Backend', '.env'), { force: true });
    const result = {
      measuredAt: new Date().toISOString(),
      tools: { eslint: ESLINT, jscpd: JSCPD },
      backend: {
        before: backendMetrics(path.join(worktree, 'Backend')),
        after: backendMetrics(path.join(REPO, 'Backend')),
      },
      flutterApiService: {
        before: apiServiceMetrics(path.join(worktree, 'Frontend', 'lib', 'services', 'api_service.dart')),
        after: apiServiceMetrics(path.join(REPO, 'Frontend', 'lib', 'services', 'api_service.dart')),
      },
    };
    fs.mkdirSync(OUT, { recursive: true });
    fs.writeFileSync(path.join(OUT, 'metrics.json'), JSON.stringify(result, null, 2));
    const text = JSON.stringify(result, null, 2);
    fs.writeFileSync(path.join(OUT, 'metrics.txt'), text);
    console.log(text);
  } finally {
    sh('git', ['-C', REPO, 'worktree', 'remove', '--force', worktree], { allowFail: true });
  }
}

main();
