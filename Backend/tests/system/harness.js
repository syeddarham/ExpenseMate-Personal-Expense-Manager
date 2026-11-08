/**
 * Runs the ExpenseMate API for black-box system tests, in one of two modes:
 *
 *  - in-process (default): the current code, wired through buildContainer()
 *    with a fake mailer. Used for normal test runs and coverage.
 *  - external (SYSTEM_TARGET=<path to a Backend folder>): starts that
 *    folder's `node server.js` as a child process and reads OTP codes from
 *    its console output (the mailer prints them when SMTP is not configured).
 *    This lets the SAME tests run against the Assignment 01 baseline for
 *    regression testing (see scripts/run-regression.sh).
 *
 * Both modes use a throwaway MySQL server; nothing touches a real database.
 */
const { spawn } = require('child_process');
const net = require('net');
const path = require('path');
const { startMysql } = require('../helpers/mysql');

const JWT_SECRET = 'system-test-secret-not-for-production';

async function startHarness() {
  const mysql = await startMysql();
  const target = process.env.SYSTEM_TARGET;
  const harness = target ? await startExternal(mysql, path.resolve(target)) : await startInProcess(mysql);
  return {
    ...harness,
    async stop() {
      await harness.close();
      await mysql.stop();
    },
  };
}

async function startInProcess(mysql) {
  process.env.NODE_ENV = 'test';
  const { Migrator } = require('../../src/database/migrator');
  const { buildContainer } = require('../../src/container');
  const { createApp } = require('../../src/app');
  const { createFakeMailer } = require('../helpers/fakeMailer');

  const db = await mysql.createDatabase('system');
  await new Migrator({ db, log: () => {} }).up();
  const mailer = createFakeMailer();
  const container = buildContainer({ env: { nodeEnv: 'test', db, jwt: { secret: JWT_SECRET, expiresIn: '1h' } }, mailer });
  const server = await new Promise((resolve) => {
    const s = createApp(container).listen(0, '127.0.0.1', () => resolve(s));
  });

  return {
    label: 'current code (in-process)',
    baseUrl: `http://127.0.0.1:${server.address().port}/api`,
    async lastCode(email, purpose) {
      return mailer.lastCode(email, purpose);
    },
    async close() {
      await new Promise((resolve) => server.close(resolve));
      await container.pool.end();
    },
  };
}

async function startExternal(mysql, backendDir) {
  const port = await freePort();
  // Build the child environment from scratch so nothing from a real .env or
  // the developer's shell (e.g. SMTP credentials) can leak into the run.
  const env = {
    PATH: process.env.PATH,
    HOME: process.env.HOME,
    NODE_ENV: 'development',
    PORT: String(port),
    DB_HOST: mysql.base.host,
    DB_PORT: String(mysql.base.port),
    DB_USER: mysql.base.user,
    DB_PASSWORD: '',
    DB_NAME: 'expensemate_db', // the Assignment 01 schema.sql hard-codes this name
    AUTO_INIT_DB: 'true',
    JWT_SECRET,
    JWT_EXPIRES_IN: '1h',
    SMTP_HOST: '',
    SMTP_PORT: '',
    SMTP_USER: '',
    SMTP_PASS: '',
    SMTP_FROM: '',
  };
  const child = spawn(process.execPath, ['server.js'], { cwd: backendDir, env, stdio: ['ignore', 'pipe', 'pipe'] });
  let output = '';
  child.stdout.on('data', (d) => (output += d));
  child.stderr.on('data', (d) => (output += d));

  await waitFor(() => output.includes('Backend running'), 60_000, () => `server did not start:\n${output}`);

  return {
    label: `external server in ${backendDir}`,
    baseUrl: `http://127.0.0.1:${port}/api`,
    async lastCode(email, purpose) {
      const find = () => {
        const re = /To: (\S+)\nSubject: ([^\n]*)\nCode: (\d{6})/g;
        let code = null;
        for (const m of output.matchAll(re)) {
          const p = /reset/i.test(m[2]) ? 'password_reset' : 'email_verification';
          if (m[1] === email && (!purpose || p === purpose)) code = m[3];
        }
        return code;
      };
      await waitFor(() => find() !== null, 3000, () => `no code for ${email} in server output`);
      return find();
    },
    async close() {
      child.kill('SIGTERM');
      await new Promise((resolve) => child.once('exit', resolve));
    },
  };
}

function freePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.listen(0, '127.0.0.1', () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
    srv.on('error', reject);
  });
}

async function waitFor(check, timeoutMs, describe) {
  const deadline = Date.now() + timeoutMs;
  while (!check()) {
    if (Date.now() > deadline) throw new Error(describe());
    await new Promise((r) => setTimeout(r, 50));
  }
}

/** Small JSON client used by the tests. */
function createClient(baseUrl) {
  return async function api(method, route, { body, token } = {}) {
    const res = await fetch(`${baseUrl}${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch (_) {
      json = { raw: text };
    }
    return { status: res.status, body: json };
  };
}

module.exports = { startHarness, createClient };
