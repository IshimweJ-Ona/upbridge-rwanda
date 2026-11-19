# Firestore contract (updated team integration baseline)

See [`firestore-erd.md`](firestore-erd.md) for the code-backed ERD draft and remaining open decisions.

This document describes the shared names in `Fs` and the finalized Firestore rules enforced in `firestore.rules`. All operations require an authenticated Firebase user with `email_verified == true`. Role privileges (`admin`, `mentor`) are trusted **only** from Firebase Auth custom claims (`request.auth.token.role`), never from mutable Firestore document fields.

| Collection | Purpose / document ID | Current known fields and rules status |
|---|---|---|
| `users` | User profile; Firebase UID | `role` (`youth` on client create), `accountStatus` (`active` on client create), `displayName`, `photoUrl`, `phone`, `interests`, `learningGoal`, `onboarded`, `updatedAt`; owner reads & edits safe profile fields; admin full access |
| `mentorProfiles` | Public & mentor-managed mentor profile; mentor UID | Confirmed with Boaz (`MentorFields` / `MentorProfileFields`): signed-in reads; admin create/delete; mentor (`role == 'mentor'`) updates only `meetingLink`, `menteeLimit`, `availabilityWindows`, `accepting`, `availability`, `openSlots`, `updatedAt` (cannot self-verify or forge counters) |
| `mentorSessions` | Mentorship session lifecycle; generated ID | Confirmed with Boaz (`SessionFields`, `MentorSessionStatus`): admin or participant (`requesterId` or `mentorId`) read; youth creates `requested`; youth cancels or deletes pending (`requested`); mentor confirms/declines/completes/cancels |
| `opportunities` | Opportunity catalog; feature-defined ID | Confirmed with Kellen (`OpportunityModel`): published records (`status == 'published'`) readable by verified users; admin writes |
| `applications` | Youth application; `{uid}_{opportunityId}` | Confirmed with Kellen (`ApplicationModel`): `userId`, `userName`, `opportunityId`, `projectIds` (>= 1), `note` (>= 60 chars), `status`, `ref`, `createdAt`, `updatedAt`; owner read/create/withdraw; admin manage |
| `notifications` | Per-user notification; feature-defined ID | `userId`, `title`, `body`, optional `route`, `createdAt`, `isRead`, `readAt`; owner reads and updates only `isRead: true` + `readAt`; client create/delete disabled even for admin |
| `checkIns` | Monthly outcome response; `{uid}_{YYYY-MM}` | `userId`, `monthKey`, `usefulness` (1-5), `applied`, `changeNote` (<= 500 chars), `createdAt`; owner create once; immutable (`update, delete` denied for all clients including admins) |
| `auditLogs` | Trusted administrative audit events | Admin reads; client writes denied |
| `appSettings` | Shared pilot settings | Signed-in reads; admin writes |
| `learningPaths`, `learningTasks` | Learning catalog | Published (`status == 'published'`) reads; admin writes |
| `taskProgress`, `submissions`, `reviews`, `projects` | Learning & portfolio records | Pending Lisa's data-layer persistence contract (`projects` top-level vs `users/{uid}/projects` still open); client writes stay closed in `firestore.rules` until finalized |

## Composite indexes (`firestore.indexes.json`)

- `projects`: `ownerId` ASC, `createdAt` DESC
- `submissions`: `userId` ASC, `submittedAt` DESC
- `opportunities`: `status` ASC, `deadline` ASC
- `notifications`: `userId` ASC, `createdAt` DESC
- `notifications`: `userId` ASC, `isRead` ASC, `createdAt` DESC
