const test = require('node:test');
const assert = require('node:assert/strict');
const { VerificationCodeService } = require('../../src/services/verificationCode.service');
const { hashCode } = require('../../src/utils/otp');
const { fakeRepo } = require('../helpers/fakes');
const { createFakeMailer } = require('../helpers/fakeMailer');

const USER = { id: 7, email: 'a@example.com' };

function makeService({ age = null, active = null } = {}) {
  const codeRepository = fakeRepo({
    secondsSinceLatest: () => age,
    invalidateAll: () => {},
    create: () => {},
    findLatestActive: () => active,
    incrementAttempts: () => {},
    markConsumed: () => {},
  });
  const mailer = createFakeMailer();
  return { service: new VerificationCodeService({ codeRepository, mailer }), codeRepository, mailer };
}

test('issue: e-mails a 6-digit code and stores only its hash', async () => {
  const { service, codeRepository, mailer } = makeService();
  const code = await service.issue(USER, 'email_verification');
  assert.match(code, /^\d{6}$/);
  assert.equal(mailer.lastCode(USER.email), code);
  assert.equal(codeRepository.called('create')[0].args[2], hashCode(code));
});

test('issue: refuses a new code during the 30 s cooldown', async () => {
  const { service } = makeService({ age: 10 });
  await assert.rejects(service.issue(USER, 'password_reset'), { status: 429, message: /wait 20s/ });
});

test('consume: wrong code counts an attempt; right code is consumed', async () => {
  const active = { id: 1, codeHash: hashCode('123456'), attempts: 0, expired: false };
  const { service, codeRepository } = makeService({ active });
  await assert.rejects(service.consume(7, 'email_verification', '000000'), { code: 'CODE_INVALID' });
  assert.equal(codeRepository.called('incrementAttempts').length, 1);
  await service.consume(7, 'email_verification', '123456');
  assert.equal(codeRepository.called('markConsumed').length, 1);
});

test('consume: expired, locked and missing codes are rejected', async () => {
  const expired = makeService({ active: { id: 1, codeHash: 'x', attempts: 0, expired: true } });
  await assert.rejects(expired.service.consume(7, 'email_verification', '1'), { code: 'CODE_EXPIRED' });
  const locked = makeService({ active: { id: 1, codeHash: 'x', attempts: 5, expired: false } });
  await assert.rejects(locked.service.consume(7, 'email_verification', '1'), { code: 'CODE_LOCKED' });
  const none = makeService();
  await assert.rejects(none.service.consume(7, 'email_verification', '1'), { code: 'CODE_INVALID' });
});
