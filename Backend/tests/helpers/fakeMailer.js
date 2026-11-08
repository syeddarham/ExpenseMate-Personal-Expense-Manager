/** Records e-mails instead of sending them, so tests can read OTP codes. */
function createFakeMailer() {
  const sent = [];
  return {
    sent,
    async sendCodeEmail(to, purpose, code) {
      sent.push({ kind: 'code', to, purpose, code });
    },
    async sendExportEmail(to, payload) {
      sent.push({ kind: 'export', to, ...payload });
      return true;
    },
    lastCode(to, purpose) {
      const match = [...sent].reverse().find((m) => m.kind === 'code' && m.to === to && (!purpose || m.purpose === purpose));
      return match ? match.code : null;
    },
  };
}

module.exports = { createFakeMailer };
