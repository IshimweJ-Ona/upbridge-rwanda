// Default interface copy shared by error, loading, and retry components.
abstract final class AppCopy {
  static const retry = 'Try again';
  static const genericError = 'Something went wrong. Please try again.';
  static const offlineError = 'Check your internet connection and try again.';
  static const loading = 'Loading…';
  static const empty = 'Nothing here yet.';
  static const imageSizeHint =
      'Choose a clear photo in JPG, PNG, or HEIC format.';
}
