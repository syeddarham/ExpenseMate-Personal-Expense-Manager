const nodemailer = require('nodemailer');
const env = require('../config/env');

let transporter = null;
if (env.smtp.host) {
  transporter = nodemailer.createTransport({
    host: env.smtp.host,
    port: env.smtp.port,
    secure: env.smtp.port === 465,
    auth: env.smtp.user ? { user: env.smtp.user, pass: env.smtp.pass } : undefined,
  });
}

/**
 * Sends a one-time code by e-mail. When SMTP is not configured the code is
 * printed to the server console so the flow can still be completed locally.
 */
async function sendCodeEmail(to, purpose, code) {
  const subject = purpose === 'password_reset' ? 'Reset your ExpenseMate password' : 'Verify your ExpenseMate email';
  const text = `Your ExpenseMate ${purpose === 'password_reset' ? 'password reset' : 'verification'} code is ${code}. It expires in 10 minutes.`;

  if (!transporter) {
    console.log(`\n[mail] To: ${to}\n[mail] Subject: ${subject}\n[mail] ${text}\n`);
    return;
  }
  await transporter.sendMail({ from: env.smtp.from, to, subject, text });
}

module.exports = { sendCodeEmail };
