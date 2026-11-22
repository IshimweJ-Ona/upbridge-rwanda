/// Single source of truth for Cloud Firestore collection names and public configuration constants.
abstract final class Fs {
  static const users = 'users';
  static const profiles = 'profiles';
  static const projects = 'projects';
  static const mentorApplications = 'mentorApplications';
  static const mentorRequests = 'mentorRequests';
  static const mentorships = 'mentorships';
  static const sessions = 'sessions';
  static const courses = 'courses';
  static const courseProgress = 'courseProgress';
  static const opportunities = 'opportunities';
  static const applications = 'applications';
  static const notifications = 'notifications';
  static const auditLogs = 'auditLogs';
}

/// Public Cloudinary configuration for direct frontend unsigned image uploads.
/// Only public non-secret identifiers live here; API secrets are never shipped to the client.
abstract final class CloudinaryDefaults {
  static const _viteCloudName = String.fromEnvironment(
    'VITE_CLOUDINARY_CLOUD_NAME',
  );
  static const _legacyCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const cloudName = _viteCloudName != ''
      ? _viteCloudName
      : (_legacyCloudName != '' ? _legacyCloudName : 'vbzq5ssu');

  static const _vitePreset = String.fromEnvironment(
    'VITE_CLOUDINARY_UPLOAD_PRESET',
  );
  static const _legacyPreset = String.fromEnvironment(
    'CLOUDINARY_UNSIGNED_IMAGE_PRESET',
  );
  static const unsignedImagePreset = _vitePreset != ''
      ? _vitePreset
      : (_legacyPreset != '' ? _legacyPreset : 'upbridge_public_images');
}
