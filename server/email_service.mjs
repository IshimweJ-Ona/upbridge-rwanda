/**
 * Server-side email rendering & delivery transport for SkillBridge / UpBridge
 * mentor lifecycle notifications.
 *
 * Credentials remain strictly on the backend via environment variables:
 *   - Resend API: `RESEND_API_KEY`, `MAIL_FROM`
 *   - Or SMTP relay: `SMTP_HOST`, `SMTP_PORT` (default 587), `SMTP_SECURE` ('true' for 465),
 *                    `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM`
 */

import net from 'node:net';
import tls from 'node:tls';

export const APPROVAL_EMAIL_SUBJECT =
  "You're Approved! Welcome to SkillBridge as a Mentor";

export function buildMentorApprovalEmail({ mentorName }) {
  const safeName =
    typeof mentorName === 'string' && mentorName.trim().length > 0
      ? mentorName.trim()
      : 'Mentor';

  const text = [
    `Hello ${safeName},`,
    '',
    'Congratulations!',
    '',
    'Your mentor application has been reviewed and approved.',
    '',
    'You are now officially authorized to join SkillBridge as a mentor.',
    '',
    'You can sign in to SkillBridge and access your dedicated Mentor Dashboard, manage mentorship requests, connect with mentees, and begin supporting young people.',
    '',
    'Thank you for sharing your knowledge, experience, and willingness to make a difference.',
    '',
    'Welcome to SkillBridge!',
    '',
    'The SkillBridge Team',
  ].join('\n');

  const escapedName = safeName
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

  const html = `
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #13294B; line-height: 1.6; max-width: 600px;">
  <p>Hello ${escapedName},</p>
  <p><strong>Congratulations!</strong></p>
  <p>Your mentor application has been reviewed and approved.</p>
  <p>You are now officially authorized to join SkillBridge as a mentor.</p>
  <p>You can sign in to SkillBridge and access your dedicated Mentor Dashboard, manage mentorship requests, connect with mentees, and begin supporting young people.</p>
  <p>Thank you for sharing your knowledge, experience, and willingness to make a difference.</p>
  <p>Welcome to SkillBridge!</p>
  <p>The SkillBridge Team</p>
</div>`.trim();

  return {
    subject: APPROVAL_EMAIL_SUBJECT,
    text,
    html,
  };
}

function encodeSmtpLine(line) {
  return `${line}\r\n`;
}

function sanitizeHeaderValue(value) {
  return String(value || '').replace(/[\r\n]+/g, ' ').trim();
}

function dotStuffSmtpBody(rawBody) {
  return String(rawBody || '').replace(/\r?\n/g, '\r\n').replace(/^\./gm, '..');
}

function readSmtpResponse(socket) {
  return new Promise((resolve, reject) => {
    let buffer = '';
    const onData = (chunk) => {
      buffer += chunk.toString('utf8');
      const lines = buffer.split(/\r?\n/);
      // Last line of multi-line SMTP response has space after 3-digit code.
      for (let i = 0; i < lines.length - 1; i += 1) {
        const line = lines[i];
        if (/^\d{3} /.test(line)) {
          cleanup();
          resolve({
            code: Number(line.slice(0, 3)),
            raw: buffer,
          });
          return;
        }
      }
    };
    const onError = (err) => {
      cleanup();
      reject(err);
    };
    const onTimeout = () => {
      cleanup();
      reject(new Error('SMTP socket timed out.'));
    };
    const onClose = () => {
      cleanup();
      reject(new Error('SMTP connection closed unexpectedly.'));
    };
    const cleanup = () => {
      socket.off('data', onData);
      socket.off('error', onError);
      socket.off('timeout', onTimeout);
      socket.off('close', onClose);
    };
    socket.on('data', onData);
    socket.on('error', onError);
    socket.on('timeout', onTimeout);
    socket.on('close', onClose);
  });
}

async function smtpCommand(socket, cmd, expectedCodes) {
  if (cmd !== null) {
    socket.write(encodeSmtpLine(cmd));
  }
  const resp = await readSmtpResponse(socket);
  if (!expectedCodes.includes(resp.code)) {
    throw new Error(`SMTP error (${resp.code}): ${resp.raw.trim()}`);
  }
  return resp;
}

async function sendViaSmtp({
  host,
  port,
  secure,
  user,
  pass,
  from,
  to,
  subject,
  text,
  html,
}) {
  let socket = secure
    ? tls.connect({ host, port, servername: host })
    : net.connect({ host, port });

  try {
    socket.setTimeout(15_000);
    await new Promise((resolve, reject) => {
      socket.once('connect', resolve);
      socket.once('secureConnect', resolve);
      socket.once('timeout', () => reject(new Error('SMTP connection timed out.')));
      socket.once('error', reject);
    });

    await smtpCommand(socket, null, [220]);
    const ehloHost = 'skillbridge.local';
    await smtpCommand(socket, `EHLO ${ehloHost}`, [250]);

    if (!secure) {
      await smtpCommand(socket, 'STARTTLS', [220]);
      socket = await new Promise((resolve, reject) => {
        const tlsSock = tls.connect(
          { socket, servername: host },
          () => resolve(tlsSock),
        );
        tlsSock.setTimeout(15_000);
        tlsSock.once('timeout', () => reject(new Error('SMTP STARTTLS timed out.')));
        tlsSock.once('error', reject);
      });
      await smtpCommand(socket, `EHLO ${ehloHost}`, [250]);
    }

    if (user && pass) {
      await smtpCommand(socket, 'AUTH LOGIN', [334]);
      await smtpCommand(
        socket,
        Buffer.from(user, 'utf8').toString('base64'),
        [334],
      );
      await smtpCommand(
        socket,
        Buffer.from(pass, 'utf8').toString('base64'),
        [235],
      );
    }

    const cleanFrom = sanitizeHeaderValue(from);
    const cleanTo = sanitizeHeaderValue(to);
    const cleanSubject = sanitizeHeaderValue(subject);
    const fromAddress = sanitizeHeaderValue(cleanFrom.match(/<([^>]+)>/)?.[1] ?? cleanFrom);
    await smtpCommand(socket, `MAIL FROM:<${fromAddress}>`, [250]);
    await smtpCommand(socket, `RCPT TO:<${cleanTo}>`, [250, 251]);
    await smtpCommand(socket, 'DATA', [354]);

    const boundary = `sb_${Date.now().toString(36)}`;
    const messageId = `<mentor-approval-${Date.now()}@${ehloHost}>`;
    const body = [
      `From: ${cleanFrom}`,
      `To: ${cleanTo}`,
      `Subject: ${cleanSubject}`,
      `Message-ID: ${messageId}`,
      'MIME-Version: 1.0',
      `Content-Type: multipart/alternative; boundary="${boundary}"`,
      '',
      `--${boundary}`,
      'Content-Type: text/plain; charset=utf-8',
      'Content-Transfer-Encoding: 8bit',
      '',
      dotStuffSmtpBody(text),
      '',
      `--${boundary}`,
      'Content-Type: text/html; charset=utf-8',
      'Content-Transfer-Encoding: 8bit',
      '',
      dotStuffSmtpBody(html),
      '',
      `--${boundary}--`,
      '.',
    ]
      .join('\r\n');

    await smtpCommand(socket, body, [250]);
    await smtpCommand(socket, 'QUIT', [221, 250]).catch(() => {});
    return {
      configured: true,
      delivered: true,
      provider: 'smtp',
      messageId,
    };
  } finally {
    socket.destroy();
  }
}

async function sendViaResend({ apiKey, from, to, subject, text, html, fetchImpl }) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15_000);
  try {
    const response = await fetchImpl('https://api.resend.com/emails', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: sanitizeHeaderValue(from),
        to: [sanitizeHeaderValue(to)],
        subject: sanitizeHeaderValue(subject),
        text,
        html,
      }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(
        payload?.message || payload?.error || `Resend HTTP ${response.status}`,
      );
    }
    return {
      configured: true,
      delivered: true,
      provider: 'resend',
      messageId: payload?.id || '',
    };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Resolves a real email transport from environment variables.
 * Never returns a fake-success sender when credentials are missing.
 */
export function createEmailSender(env = process.env, fetchImpl = globalThis.fetch) {
  const resendApiKey = (env.RESEND_API_KEY || '').trim();
  const smtpHost = (env.SMTP_HOST || '').trim();
  const mailFrom = (
    env.MAIL_FROM ||
    env.SMTP_FROM ||
    'SkillBridge Team <no-reply@skillbridge.rw>'
  ).trim();

  if (resendApiKey) {
    return async ({ to, subject, text, html }) =>
      sendViaResend({
        apiKey: resendApiKey,
        from: mailFrom,
        to,
        subject,
        text,
        html,
        fetchImpl,
      });
  }

  if (smtpHost) {
    const port = Number(env.SMTP_PORT || '587');
    const secure = String(env.SMTP_SECURE || '').toLowerCase() === 'true' || port === 465;
    const user = (env.SMTP_USER || '').trim();
    const pass = (env.SMTP_PASS || '').trim();
    return async ({ to, subject, text, html }) =>
      sendViaSmtp({
        host: smtpHost,
        port,
        secure,
        user,
        pass,
        from: mailFrom,
        to,
        subject,
        text,
        html,
      });
  }

  return async () => ({
    configured: false,
    delivered: false,
    provider: 'none',
    error:
      'Approval email transport is not configured (set RESEND_API_KEY or SMTP_HOST/SMTP_USER/SMTP_PASS).',
  });
}
