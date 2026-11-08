/**
 * Minimal in-memory stand-ins for repositories, used by service unit tests
 * so business rules can be tested without MySQL.
 */

/** A Database double whose transaction() just runs the callback. */
function fakeDb() {
  const db = {
    transactions: 0,
    async transaction(work) {
      db.transactions++;
      return work(db);
    },
    async query() {
      throw new Error('Services must not run SQL directly');
    },
  };
  return db;
}

/** Wraps an object of async methods as a repository with withDb(). */
function fakeRepo(methods) {
  const calls = [];
  const repo = { calls };
  for (const [name, fn] of Object.entries(methods)) {
    repo[name] = async (...args) => {
      calls.push({ method: name, args });
      return fn(...args);
    };
  }
  repo.withDb = () => repo;
  repo.called = (name) => calls.filter((c) => c.method === name);
  return repo;
}

module.exports = { fakeDb, fakeRepo };
