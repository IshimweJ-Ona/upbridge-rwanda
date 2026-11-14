# Firestore contract (current shared baseline)

This document describes the shared names in `Fs` and the operations currently implemented by `UpBridgeRepository`. It is an integration baseline; feature owners must confirm their fields and status transitions before writing production records. Documents are created by writes; collection constants do not create collections.

| Collection | Purpose / document ID | Current known fields and ownership |
|---|---|---|
| `users` | User profile; Firebase UID | `role`, `accountStatus`, profile fields, `updatedAt`; user owns safe profile edits; admin is custom-claim controlled |
| `mentorProfiles` | Public mentor directory; feature-defined ID | Feature owner must confirm fields; verified records are readable by signed-in users |
| `learningPaths`, `learningTasks` | Published learning catalog; feature-defined ID | Lisa to confirm fields, publication states, and authoring permissions |
| `taskProgress` | One user's task progress; `{uid}_{taskId}` | `userId`, `taskId`, `status`, `updatedAt`; learner-owned |
| `submissions` | Work submitted for review; generated ID | `userId`, `status`, `submittedAt`, `updatedAt`, feature submission fields; learner-owned, mentor access contract pending |
| `reviews` | Review feedback; feature-defined ID | Boaz/Lisa to confirm reviewer and submission linkage and immutable status rules |
| `projects` | Portfolio project; generated ID | `ownerId`, `visibility`, `createdAt`, `updatedAt`, project fields; owner-controlled |
| `mentorshipRequests`, `mentorSessions` | Mentorship lifecycle; feature-defined ID | Boaz to confirm requester/mentor IDs, allowed transitions, and access |
| `opportunities` | Published opportunities; feature-defined ID | Kellen to confirm publisher, moderation state, fields, and admin operations |
| `applications` | Youth application; feature-defined ID | Kellen to confirm applicant ownership and status transitions |
| `notifications` | Per-user notification; feature-defined ID | `userId`, `title`, `body`, optional `route`, `createdAt`, `isRead`, and `readAt`; the recipient can only mark a notification read |
| `checkIns` | One monthly response; document ID `{uid}_{YYYY-MM}` | `userId`, `monthKey`, `usefulness` (1-5), `applied`, `changeNote` (up to 500 chars), and `createdAt`; immutable after creation |
| `auditLogs` | Trusted administrative audit events | Server-written only; clients cannot write |
| `appSettings` | Shared platform settings | Admin writes; signed-in reads |

Use Firebase Auth UID as identity, ISO-independent Firestore `Timestamp` values for dates, camelCase field names, and bounded documents. Client-supplied role fields never establish privileges. The rules currently permit user creation only with `role: youth` and `accountStatus: active`; assign mentor/admin claims through a trusted administrative process.

`firestore.indexes.json` contains only the three composite indexes required by the current shared repository queries: projects by owner and descending creation time, submissions by user and descending submission time, and published opportunities by deadline. Other feature queries may require additional indexes, which their owners should document and coordinate before changing the shared index file.

The initial `firestore.rules` is intentionally restrictive: every Firestore operation requires an authenticated Firebase user with `email_verified == true`; user profile creation is limited to a youth account; published catalogs are readable only by verified users; and feature collection writes require an admin claim until per-feature field and transition rules are reviewed. Mentor access, feature-specific validation, state transitions, and complete admin audit logging remain dependent on the contracts above. Test those rules in the emulator before any deployment.

Lisa's current portfolio data-source note describes `users/{uid}/projects`, while the shared `UpBridgeRepository` uses the top-level `projects` collection with `ownerId`. Lisa and Jonathan must agree on one path before portfolio writes are enabled. No portfolio files were changed.
