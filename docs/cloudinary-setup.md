# Cloudinary Setup (`vbzq5ssu`) — Unsigned Free-Tier Architecture

All user-uploaded images in UpBridge Rwanda (profile avatars, portfolio project images, course evidence images, certificate screenshots, CV/opportunity screenshots, and mentor application images) upload **directly from the Flutter app to Cloudinary** (`cloud_name = vbzq5ssu`) via an **unsigned upload preset** (`upbridge_public_images`), without Firebase Cloud Functions or Google Cloud Secret Manager.

Firestore persists only the resulting image metadata: `{ url, publicId, resourceType, size, ownerUid, createdAt }`.

---

## Public Configuration (Safe for Frontend)

```env
VITE_CLOUDINARY_CLOUD_NAME=vbzq5ssu
VITE_CLOUDINARY_UPLOAD_PRESET=upbridge_public_images
```

Override at build/run time if targeting a test Cloudinary account:

```bash
flutter run \
  --dart-define=VITE_CLOUDINARY_CLOUD_NAME=vbzq5ssu \
  --dart-define=VITE_CLOUDINARY_UPLOAD_PRESET=upbridge_public_images
```

> Both `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UNSIGNED_IMAGE_PRESET` aliases remain supported in `lib/core/constants/firestore_schema.dart`. Never add `CLOUDINARY_API_KEY` or `CLOUDINARY_API_SECRET` to `.env`, `.dart`, or `--dart-define`.

---

## Direct Upload Endpoint & Client Validation

`CloudinaryMediaService` (`lib/core/services/cloudinary_service.dart`) uploads directly to:

```text
POST https://api.cloudinary.com/v1_1/vbzq5ssu/image/upload
```

Before sending an HTTP request, `CloudinaryMediaService.uploadImage` enforces:
- **Allowed image formats**: `jpg`, `jpeg`, `png`, `webp` (`image/jpeg`, `image/png`, `image/webp`)
- **Maximum size**: `10 MB` (`10 * 1024 * 1024` bytes)
- **Non-empty file bytes** and valid public configuration
- **Upload UX**: Progress callbacks (`onProgress`), cancellation (`UploadCancelToken`), and exponential-backoff retries on transient `5xx` / timeout errors (up to `maxRetries`), failing fast on `4xx` responses
- **Security Rules (`firestore.rules`)**: `validOptionalAsset` requires `https://res.cloudinary.com/vbzq5ssu/image/upload/...`, `resourceType == 'image'`, `ownerUid == request.auth.uid`, and `size <= 10485760`.

### Replace & Delete Behavior on Spark

- **Upload / Replace**: `replaceFile` uploads the new image first and returns the new `MediaAsset`. Only if upload succeeds does the caller persist the new `MediaAsset` to Firestore.
- **Delete / Unlink**: Removing an image unlinks the `MediaAsset` reference from the Firestore document immediately.
- **Trade-off**: Permanent asset destruction (`POST /v1_1/vbzq5ssu/image/destroy`) requires `CLOUDINARY_API_SECRET`, so unsigned client builds cannot call Cloudinary's destroy endpoint directly. If you later connect an optional external server (`onDeleteRemoteAsset` hook), remote cleanup works without changing UI callers; otherwise orphaned images can be cleaned from the Cloudinary Media Library console.

---

## Cloudinary Console Setup & Abuse Prevention (Required)

Because unsigned presets are public by design, configure strict guardrails in Cloudinary Console (**`vbzq5ssu`**):

1. Open **Settings -> Upload -> Upload presets -> Add upload preset**.
2. Set:
   - **Upload preset name**: `upbridge_public_images`
   - **Signing Mode**: **Unsigned**
3. **Restrict formats & asset type**:
   - Allowed resource type: **Image**
   - Allowed formats: `jpg, jpeg, png, webp` (reject PDF, SVG, HTML, executables server-side in Cloudinary)
4. **Restrict folder & size**:
   - Folder / Asset folder: `upbridge/public-images` (enforced server-side by the preset itself; the client sends only `upload_preset` + `file`)
   - Max image file size: `10 MB` (or lower per tier)
   - Incoming transformation (optional cost/quota saver): limit max dimensions (e.g., `c_limit,w_2048,h_2048,q_auto:good`) and strip EXIF metadata if desired.
5. **Prevent unauthorized overwriting / abuse**:
   - Enable **Unique filename** / prevent overwriting existing `public_id`s by disabling **Use filename** or keeping **Overwrite = false**.
   - Monitor Cloudinary free-plan bandwidth/credit alerts in **Dashboard -> Settings -> Notification emails**.
