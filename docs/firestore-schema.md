# Firestore Schema & Status Lifecycle Contract

All Firestore documents include `ownerUid`, `status`, `createdAt`, and `updatedAt`.
Cloudinary attachments store only `{ url, publicId, resourceType, size, ownerUid, createdAt }`.
Administrator privileges rely strictly on Firebase Auth custom claims (`request.auth.token.role == 'admin'`). Mentor privileges on Firebase Spark are granted/revoked in `users/{uid}` (`role: 'mentor'`, `isApproved: true`) and optionally mirrored via `scripts/review_mentor.mjs` (`role: 'mentor'` claim + refresh token revocation).

## Collections

| Collection | Document ID | Key Fields | Access Summary |
|---|---|---|---|
| `users` | `{uid}` | `ownerUid`, `email`, `displayName`, `phone`, `role` (`student\|mentor\|admin`), `isApproved`, `status` (`active\|deactivated`), `onboarded`, `preferredLocale`, `photoAsset`, `createdAt`, `updatedAt` | Owner reads even when deactivated; active owner updates safe profile fields; self-create locked to `role='student'`, `isApproved=false`, `status='active'`; admin/Admin SDK controls privileged role & status |
| `profiles` | `{uid}` | `ownerUid`, `displayName`, `headline`, `location`, `about`, `photoAsset`, `cvAsset`, `skills`, `interests`, `learningGoal`, `professionalLinks[]`, `education[]`, `experience[]`, `certificates[]`, `isMentorPublic`, `mentorExpertise[]`, `mentorExperienceYears`, `mentorAvailability`, `mentorMaxMentees`, `mentorBio`, `status` (`active\|archived`), `createdAt`, `updatedAt` | Active signed-in read when `status='active'`; owner updates CV/portfolio/links; only approved mentors/admin can set `isMentorPublic=true` and mentor fields |
| `projects` | Auto ID | `ownerUid`, `title`, `description`, `skills[]`, `projectUrl`, `repoUrl`, `images[]`, `attachments[]`, `courseId`, `isPublic`, `status` (`draft\|published\|archived`), `createdAt`, `updatedAt` | Active owner CRUD (validated keys/media limits); active signed-in read when `isPublic=true && status='published'`; admin read |
| `mentorApplications` | `{uid}` | `ownerUid`, `applicantName`, `applicantEmail`, `headline`, `bio`, `expertise[]`, `experienceYears`, `availability`, `cvAsset`, `supportingLinks[]`, `status` (`pending\|approved\|rejected\|revoked`), `rejectionReason`, `reviewedBy`, `reviewedAt`, `createdAt`, `updatedAt` | Owner read/create `pending` or resubmit from `rejected`/`revoked`; admin reviews `pending -> approved \| rejected` and revokes `approved -> revoked` |
| `mentorRequests` | Auto ID | `ownerUid`, `studentUid`, `studentName`, `studentPhotoUrl`, `mentorUid`, `mentorName`, `mentorPhotoUrl`, `message`, `goals`, `status` (`pending\|accepted\|declined\|cancelled`), `responseNote`, `respondedAt`, `createdAt`, `updatedAt` | Student participant reads & creates/cancels `pending`; approved mentor (`isApprovedMentor()`) reads & accepts/declines `pending` |
| `mentorships` | `{requestId}` | `ownerUid`, `studentUid`, `studentName`, `mentorUid`, `mentorName`, `requestId`, `goalSummary`, `status` (`active\|completed\|ended`), `feedbackRating`, `feedbackComment`, `endedByUid`, `endedAt`, `createdAt`, `updatedAt` | Active student participant or approved mentor reads; mentor creates atomically when accepting `mentorRequests/{requestId}`; participants end/complete and student submits `1..5` feedback |
| `sessions` | Auto ID | `ownerUid`, `mentorshipId`, `studentUid`, `studentName`, `mentorUid`, `mentorName`, `topic`, `notes`, `meetingMode`, `meetingLink`, `scheduledAt`, `durationMinutes`, `status` (`scheduled\|completed\|cancelled`), `cancelReason`, `completedAt`, `createdAt`, `updatedAt` | Active participants read; participants schedule `scheduled`; approved mentor completes, updates `notes`, and reschedules `scheduled`; either participant cancels `scheduled` |
| `courses` | Auto ID | `ownerUid`, `ownerName`, `title`, `summary`, `category` (`it\|softSkills\|career\|...`), `customCategory`, `level`, `estimatedMinutes`, `learningObjectives[]`, `resources[]`, `modules[]`, `skills[]`, `coverAsset`, `status` (`draft\|published\|archived`), `createdAt`, `updatedAt` | Signed-in users read `published`; approved mentor reads/creates/edits/transitions own courses (`ownerUid`) & deletes own `draft`; admin manages all |
| `courseProgress` | `{uid}_{courseId}` | `ownerUid`, `courseId`, `courseTitle`, `courseOwnerUid`, `completedModuleIds[]`, `progressPercent`, `evidenceUrl`, `evidenceAsset`, `status` (`notStarted\|inProgress\|completed`), `completedAt`, `createdAt`, `updatedAt` | Owner student read/write; owning approved mentor (`courseOwnerUid`) & admin read engagement |
| `opportunities` | Auto ID | `ownerUid`, `title`, `organization`, `location`, `type` (`internship\|job\|gig\|training\|scholarship\|custom`), `customType`, `workMode`, `compensation`, `coverAsset`, `description`, `requirements[]`, `skills[]`, `applyUrl`, `deadline`, `status` (`draft\|published\|closed\|archived`), `createdAt`, `updatedAt` | Signed-in active users read when `status='published'`; admin write |
| `applications` | `{uid}_{oppId}` | `ownerUid`, `opportunityId`, `opportunityTitle`, `organization`, `studentName`, `projectIds[]`, `coverNote`, `cvAsset`, `status` (`submitted\|underReview\|accepted\|rejected\|withdrawn`), `createdAt`, `updatedAt` | Owner read/create `submitted` (when opportunity `published`)/withdraw/resubmit; admin review transitions |
| `notifications` | Auto ID | `ownerUid`, `title`, `body`, `type`, `route`, `sourceCollection`, `sourceId`, `isRead`, `readAt`, `status` (`unread\|read`), `createdAt`, `updatedAt` | Active owner reads & marks read; created by verified admin OR verified participant linked via `getAfter` to `mentorRequests`/`mentorships`/`sessions` for counterpart |
| `auditLogs` | Auto ID | `ownerUid`, `actorUid`, `actorEmail`, `action`, `targetCollection`, `targetId`, `details`, `status` (`recorded`), `createdAt`, `updatedAt` | Admin read & append-only `create` with validated schema (`actorUid == request.auth.uid`); `update` and `delete` denied for all users |

## Allowed Status Transitions (`StatusTransitions`)

- `mentorApplications`: `pending -> approved | rejected`; `approved -> revoked`; `rejected -> pending`; `revoked -> pending`
- `mentorRequests`: `pending -> accepted | declined | cancelled`
- `mentorships`: `active -> completed | ended`
- `sessions`: `scheduled -> completed | cancelled`
- `courses`: `draft <-> published`, `draft | published -> archived`, `archived -> draft`
- `courseProgress`: `notStarted -> inProgress | completed`, `inProgress -> completed`
- `opportunities`: `draft <-> published`, `published -> closed | archived`, `closed -> published | archived`, `archived -> draft`
- `applications`: `submitted -> underReview | withdrawn`, `underReview -> accepted | rejected | withdrawn`, `withdrawn -> submitted`
- `projects`: `draft <-> published <-> archived`
- `users.status`: `active <-> deactivated`
