// Shared limits and durations used by the application shell and workflows.
abstract final class AppConstants {
  static const splashDuration = Duration(seconds: 25);
  static const otpLength = 6;
  static const otpResendDelay = Duration(seconds: 40);
  static const reviewResponseWindow = Duration(hours: 48);
  static const minimumReviewNoteLength = 60;
  static const maximumMenteesPerMentor = 12;
  static const reportEscalationThreshold = 3;
  static const mentorSessionDuration = Duration(minutes: 30);
}
