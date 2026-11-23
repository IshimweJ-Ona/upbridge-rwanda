/**
 * Trusted Node.js Admin & Approval Email Backend for UpBridge / SkillBridge.
 *
 * Run locally or host on a free Node service and set:
 *   flutter run --dart-define=ADMIN_API_BASE_URL=http://127.0.0.1:8787
 */

import http from 'node:http';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  HttpAuthError,
  deliverMentorApprovalEmail,
  reviewMentorApplicationTx,
  revokeMentorTx,
  setUserStatusTx,
  verifyAdminActor,
} from './admin_core.mjs';
import { createEmailSender } from './email_service.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function loadFirebaseAdmin() {
  const roots = [
    createRequire(import.meta.url),
    createRequire(path.resolve(__dirname, '../package.json')),
  ];
  for (const req of roots) {
    try {
      return {
        app: req('firebase-admin/app'),
        auth: req('firebase-admin/auth'),
        firestore: req('firebase-admin/firestore'),
      };
    } catch (_) {}
  }
  throw new Error('Unable to resolve firebase-admin. Run npm install at repo root.');
}

async function readJsonBody(req, maxBytes = 65_536) {
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    total += chunk.length;
    if (total > maxBytes) {
      throw new HttpAuthError(413, 'Request body exceeds 64 KB limit.');
    }
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch (_) {
    throw new HttpAuthError(400, 'Request body must be valid JSON.');
  }
}

function sendJson(res, statusCode, payload, allowOrigin) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  });
  res.end(JSON.stringify(payload));
}

export function createAdminServer({
  auth,
  db,
  FieldValue,
  emailSender,
  corsAllowOrigin = process.env.CORS_ALLOW_ORIGIN || '*',
}) {
  return http.createServer(async (req, res) => {
    const pathname = new URL(req.url || '/', 'http://localhost').pathname;

    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': corsAllowOrigin,
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      });
      res.end();
      return;
    }

    if (req.method === 'GET' && pathname === '/health') {
      sendJson(
        res,
        200,
        { ok: true, service: 'skillbridge-admin-backend' },
        corsAllowOrigin,
      );
      return;
    }

    if (req.method !== 'POST') {
      sendJson(res, 405, { error: 'Method not allowed.' }, corsAllowOrigin);
      return;
    }

    try {
      const authHeader = String(req.headers.authorization || '');
      const idToken = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length).trim()
        : '';
      const actor = await verifyAdminActor({ auth, db, idToken });
      const body = await readJsonBody(req);

      if (pathname === '/admin/review-mentor-application') {
        const result = await reviewMentorApplicationTx({
          auth,
          db,
          FieldValue,
          actor,
          applicantUid: String(body.applicantUid || '').trim(),
          decision: String(body.decision || '').trim(),
          reason: String(body.reason || ''),
          emailSender,
        });
        sendJson(res, 200, result, corsAllowOrigin);
        return;
      }

      if (pathname === '/admin/retry-approval-email') {
        const applicantUid = String(body.applicantUid || '').trim();
        if (!applicantUid) {
          throw new HttpAuthError(400, 'applicantUid is required.');
        }
        const appSnap = await db.collection('mentorApplications').doc(applicantUid).get();
        if (!appSnap.exists) {
          throw new HttpAuthError(404, 'Mentor application not found.');
        }
        const appData = appSnap.data() || {};
        const userSnap = await db.collection('users').doc(applicantUid).get();
        const userData = userSnap.exists ? userSnap.data() || {} : {};
        const emailDelivery = await deliverMentorApprovalEmail({
          db,
          FieldValue,
          applicantUid,
          recipientEmail: userData.email || appData.applicantEmail,
          mentorName: appData.applicantName || userData.displayName,
          actorUid: actor.uid,
          actorEmail: actor.email,
          emailSender,
        });
        sendJson(res, 200, { ok: true, emailDelivery }, corsAllowOrigin);
        return;
      }

      if (pathname === '/admin/revoke-mentor-role') {
        const result = await revokeMentorTx({
          auth,
          db,
          FieldValue,
          actor,
          targetUid: String(body.targetUid || '').trim(),
          reason: String(body.reason || ''),
        });
        sendJson(res, 200, result, corsAllowOrigin);
        return;
      }

      if (pathname === '/admin/set-user-status') {
        const result = await setUserStatusTx({
          auth,
          db,
          FieldValue,
          actor,
          targetUid: String(body.targetUid || '').trim(),
          status: String(body.status || '').trim(),
          reason: String(body.reason || ''),
        });
        sendJson(res, 200, result, corsAllowOrigin);
        return;
      }

      sendJson(res, 404, { error: 'Unknown admin endpoint.' }, corsAllowOrigin);
    } catch (err) {
      const status = err instanceof HttpAuthError ? err.statusCode : 500;
      sendJson(res, status, { error: String(err?.message || err) }, corsAllowOrigin);
    }
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  const { app, auth: authPkg, firestore: fsPkg } = loadFirebaseAdmin();
  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    'upridge-rwanda-dev';
  const usingEmulators = Boolean(
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||
      process.env.FIRESTORE_EMULATOR_HOST,
  );
  app.initializeApp(
    usingEmulators
      ? { projectId }
      : { projectId, credential: app.applicationDefault() },
  );
  const auth = authPkg.getAuth();
  const db = fsPkg.getFirestore();
  const { FieldValue } = fsPkg;
  const emailSender = createEmailSender(process.env);
  const host = process.env.HOST || '127.0.0.1';
  const port = Number(process.env.PORT || '8787');
  const server = createAdminServer({ auth, db, FieldValue, emailSender });
  server.listen(port, host, () => {
    console.log(
      `SkillBridge Admin Backend listening on http://${host}:${port} (project=${projectId})`,
    );
  });
}
