const nodemailer = require('nodemailer');
const env = require('../config/env');

function getTransporter() {
  if (!env.smtp.host) return null;
  return nodemailer.createTransport({
    host: env.smtp.host,
    port: Number(env.smtp.port) || 587,
    secure: Number(env.smtp.port) === 465,
    auth: env.smtp.user ? { user: env.smtp.user, pass: env.smtp.pass } : undefined,
  });
}

/**
 * Sends a one-time code by e-mail with a modern, responsive HTML layout.
 */
async function sendCodeEmail(to, purpose, code) {
  const isReset = purpose === 'password_reset';
  const subject = isReset ? 'Reset your ExpenseMate password' : 'Verify your ExpenseMate email';
  const title = isReset ? 'Password Reset Verification' : 'Verify Your Email Address';
  const description = isReset
    ? 'We received a request to reset the password for your ExpenseMate account. Use the 6-digit code below to set a new password:'
    : 'Welcome to ExpenseMate! Use the 6-digit verification code below to activate your account and start tracking smarter:';

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f5f7; margin: 0; padding: 24px; color: #1f2937; }
    .card { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 14px rgba(0,0,0,0.06); }
    .header { background: linear-gradient(135deg, #059669 0%, #047857 100%); padding: 32px 24px; text-align: center; color: white; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { margin: 6px 0 0; opacity: 0.9; font-size: 14px; }
    .body { padding: 32px 28px; }
    .title { font-size: 18px; font-weight: 700; color: #111827; margin: 0 0 12px; }
    .text { font-size: 14px; line-height: 1.6; color: #4b5563; margin: 0 0 24px; }
    .code-box { background: #f0fdf4; border: 2px dashed #059669; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }
    .code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #059669; font-family: 'Courier New', monospace; }
    .notice { font-size: 12px; color: #9ca3af; text-align: center; margin-top: 24px; }
    .footer { background: #f9fafb; padding: 18px 24px; text-align: center; font-size: 12px; color: #9ca3af; border-top: 1px solid #e5e7eb; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>ExpenseMate</h1>
      <p>Personal Finance & Expense Manager</p>
    </div>
    <div class="body">
      <div class="title">${title}</div>
      <div class="text">${description}</div>
      <div class="code-box">
        <div class="code">${code}</div>
      </div>
      <div class="text" style="font-size: 13px; color: #6b7280; text-align: center;">
        This code is valid for <strong>10 minutes</strong>. If you did not request this, please disregard this email.
      </div>
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} ExpenseMate. Track smarter. Spend better.
    </div>
  </div>
</body>
</html>
  `;

  const text = `Your ExpenseMate ${isReset ? 'password reset' : 'verification'} code is ${code}. It expires in 10 minutes.`;

  const transporter = getTransporter();
  if (!transporter) {
    console.log(`\n[SMTP Disabled/Empty] To: ${to}\nSubject: ${subject}\nCode: ${code}\n`);
    return;
  }
  await transporter.sendMail({
    from: env.smtp.from || 'ExpenseMate <no-reply@expensemate.app>',
    to,
    subject,
    text,
    html,
  });
}

/**
 * Sends transaction export (CSV / PDF) as an email attachment.
 */
async function sendExportEmail(to, { format, buffer, filename, count, currencySymbol }) {
  const isPdf = format.toLowerCase() === 'pdf';
  const subject = `Your ExpenseMate Transaction Export (${format.toUpperCase()})`;
  const mimeType = isPdf ? 'application/pdf' : 'text/csv';

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f5f7; margin: 0; padding: 24px; color: #1f2937; }
    .card { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 14px rgba(0,0,0,0.06); }
    .header { background: linear-gradient(135deg, #059669 0%, #047857 100%); padding: 32px 24px; text-align: center; color: white; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
    .body { padding: 32px 28px; }
    .title { font-size: 18px; font-weight: 700; color: #111827; margin: 0 0 12px; }
    .text { font-size: 14px; line-height: 1.6; color: #4b5563; margin: 0 0 20px; }
    .info-box { background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; margin: 20px 0; }
    .info-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
    .footer { background: #f9fafb; padding: 18px 24px; text-align: center; font-size: 12px; color: #9ca3af; border-top: 1px solid #e5e7eb; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>ExpenseMate</h1>
      <p>Financial Data Export</p>
    </div>
    <div class="body">
      <div class="title">Your Export is Ready</div>
      <div class="text">
        We have generated your transaction export report in <strong>${format.toUpperCase()}</strong> format.
        Please find your file attached to this email.
      </div>
      <div class="info-box">
        <p style="margin: 0 0 8px; font-weight: 600; font-size: 14px;">Summary:</p>
        <p style="margin: 0; font-size: 13px; color: #4b5563;">• Total Records: <strong>${count}</strong></p>
        <p style="margin: 4px 0 0; font-size: 13px; color: #4b5563;">• File Name: <strong>${filename}</strong></p>
      </div>
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} ExpenseMate. All rights reserved.
    </div>
  </div>
</body>
</html>
  `;

  const transporter = getTransporter();
  if (!transporter) {
    console.log(`\n[SMTP Disabled/Empty] Export email to ${to} with attachment ${filename} (${buffer.length} bytes)\n`);
    return false;
  }

  await transporter.sendMail({
    from: env.smtp.from || 'ExpenseMate <no-reply@expensemate.app>',
    to,
    subject,
    text: `Your ExpenseMate transaction export is attached (${filename}).`,
    html,
    attachments: [
      {
        filename,
        content: buffer,
        contentType: mimeType,
      },
    ],
  });
  return true;
}

module.exports = { sendCodeEmail, sendExportEmail };

