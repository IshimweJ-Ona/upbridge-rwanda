# Cloudinary setup for public images

The app has a shared Cloudinary adapter for public JPEG, PNG, and WebP images.
It returns Cloudinary's HTTPS URL and asset metadata so a feature repository can
store the URL in Firestore. No feature currently calls the adapter, so this is
an integration point until the relevant feature owner wires it in.

## Configure a free account

1. Create or sign in to a Cloudinary account and open the Console dashboard.
2. Copy the **Cloud name** from the dashboard.
3. Open **Settings → Upload → Upload presets** and create an **unsigned** preset
   named `upbridge_public_images`.
4. Restrict the preset to image uploads and JPEG, PNG, and WebP formats. Use a
   dedicated folder such as `upbridge/public-images`, and configure any upload
   size or transformation limits the current account UI offers.
5. Do not put the API secret in Flutter, a `--dart-define`, source control, or a
   screenshot. Anyone who obtains an unsigned preset name can use it to upload,
   so keep this preset narrow and monitor usage in Cloudinary.

Run the Flutter app with the two public values:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UNSIGNED_IMAGE_PRESET=upbridge_public_images
```

PowerShell form:

```powershell
flutter run `
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name `
  --dart-define=CLOUDINARY_UNSIGNED_IMAGE_PRESET=upbridge_public_images
```

Replace `your_cloud_name` with the dashboard value. After creating the account
and preset, give Jonathan only the cloud name and preset name so the feature
owners can wire their upload flows. Never send the API secret.

## Certificates and private files

Do not upload certificates or private documents with this unsigned client
service. Unsigned presets are public capabilities and must not expose private
records. A trusted signing endpoint or equivalent server-side authorization is
required before those file flows can be implemented safely. This project has
not provisioned that backend, so certificate uploads remain a known gap.
