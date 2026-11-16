# Cloudinary setup for public images

The app has a shared Cloudinary adapter for public JPEG, PNG, and WebP images.
It returns Cloudinary's HTTPS URL and asset metadata so a feature repository can
store the URL in Firestore. No feature currently calls the adapter, so this is
an integration point until the relevant feature owner wires it in.

The shared demo defaults are cloud name `vbzq5ssu` and preset
`upbridge_public_images`. Once that preset is created in this account, teammates
can run the app without adding Cloudinary flags. These are public configuration
values, not credentials.

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

The app is preconfigured for these values. Run it normally:

```powershell
flutter run
```

To override the defaults for another account or preset, pass public values:

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

Replace the example cloud name with the dashboard value. Never put or send the
API secret. After creating the preset, teammates can use the same account by
running `flutter run` without the override flags.

## Certificates and private files

Do not upload certificates or private documents with this unsigned client
service. Unsigned presets are public capabilities and must not expose private
records. A trusted signing endpoint or equivalent server-side authorization is
required before those file flows can be implemented safely. This project has
not provisioned that backend, so certificate uploads remain a known gap.
