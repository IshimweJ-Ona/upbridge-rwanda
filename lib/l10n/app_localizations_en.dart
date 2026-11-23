// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'UpBridge Rwanda';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabLearn => 'Learn';

  @override
  String get tabMentors => 'Mentors';

  @override
  String get tabJobs => 'Opportunities';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabMentorDashboard => 'Dashboard';

  @override
  String get tabMentorCourses => 'Courses';

  @override
  String get tabMentorRequests => 'Requests';

  @override
  String get tabMentorSessions => 'Sessions';

  @override
  String get tabMentorMentees => 'Mentees';

  @override
  String get tabAdminOverview => 'Overview';

  @override
  String get tabAdminUsers => 'Users';

  @override
  String get tabAdminMentors => 'Mentors';

  @override
  String get tabAdminContent => 'Catalog';

  @override
  String get tabAdminSettings => 'Settings';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleMentor => 'Mentor';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get menteeLabel => 'Mentee';

  @override
  String get sessionLabel => 'Session';

  @override
  String get requestLabel => 'Request';

  @override
  String get welcomeTagline =>
      'Build practical IT and soft skills, connect with verified mentors, and showcase your verified portfolio.';

  @override
  String get createFreeAccount => 'Create free account';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get signIn => 'Log in';

  @override
  String get signOut => 'Log out';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get submit => 'Submit';

  @override
  String get loading => 'Loading…';

  @override
  String get emptyStateDefault => 'Nothing here yet.';

  @override
  String get offlineMessage => 'Check your internet connection and try again.';

  @override
  String get studentDashboardTitle => 'Student Dashboard';

  @override
  String get mentorDashboardTitle => 'Mentor Dashboard';

  @override
  String get adminDashboardTitle => 'Admin Console';

  @override
  String get nextActionLabel => 'Next Action';

  @override
  String get activeMentorshipLabel => 'Active Mentorship';

  @override
  String get upcomingSessionLabel => 'Upcoming Session';

  @override
  String get learningProgressLabel => 'Learning Progress';

  @override
  String get recommendedMentorsLabel => 'Recommended Mentors';

  @override
  String get opportunitiesLabel => 'Opportunities';

  @override
  String get pendingRequestsLabel => 'Pending Requests';

  @override
  String get myMenteesLabel => 'My Mentees';

  @override
  String get mentorPendingBannerTitle => 'Mentor application pending review';

  @override
  String get mentorPendingBannerBody =>
      'An administrator must approve your application before mentor tools unlock.';

  @override
  String get cvPortfolioTitle => 'CV & Portfolio';

  @override
  String get languageTitle => 'Language';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noCoursesYet => 'No courses published yet';

  @override
  String get noCoursesBody =>
      'Published IT and soft-skills courses will appear here once added by an administrator.';

  @override
  String get noOpportunitiesYet => 'No opportunities open right now';

  @override
  String get noOpportunitiesBody =>
      'Published internships, jobs, and paid gigs will appear here.';

  @override
  String get noMentorsYet => 'No verified mentors available yet';

  @override
  String get noMentorsBody =>
      'Approved mentors will appear here once verified by an administrator.';

  @override
  String get mentorCoursesTitle => 'My Courses';

  @override
  String get createCourseLabel => 'New course';

  @override
  String get publishLabel => 'Publish';

  @override
  String get saveDraftLabel => 'Save draft';

  @override
  String get archiveLabel => 'Archive';

  @override
  String get previewLabel => 'Preview';

  @override
  String get engagementLabel => 'Learner engagement';

  @override
  String get rescheduleLabel => 'Reschedule';

  @override
  String get revokeMentorLabel => 'Revoke mentor';

  @override
  String get mentorPendingMessage =>
      'Your mentor application is being reviewed by our administration team.';

  @override
  String get mentorApprovedMessage =>
      'Congratulations! Your mentor application has been approved.';

  @override
  String get mentorRevokedMessage =>
      'Your mentor privileges were revoked by an administrator.';

  @override
  String get searchHint => 'Search';

  @override
  String get errorLoadingTitle => 'Unable to load data';

  @override
  String get scheduleSessionLabel => 'Schedule session';

  @override
  String get auditLogsTitle => 'Audit logs';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get joinUpBridgeTitle => 'Join UpBridge Rwanda';

  @override
  String get joinUpBridgeBody =>
      'Build career-ready skills, verify real projects, and connect with vetted mentors across Rwanda.';

  @override
  String get joinAsYouthTitle => 'Join as Youth';

  @override
  String get joinAsYouthSubtitle =>
      'Learn skills, build proof & connect with mentors';

  @override
  String get applyAsMentorTitle => 'Apply as Mentor';

  @override
  String get applyAsMentorSubtitle =>
      'Guide rising talent (requires admin approval)';

  @override
  String get createYouthAccountCta => 'Create Youth Account';

  @override
  String get submitMentorApplicationCta => 'Submit Mentor Application';

  @override
  String get adminApprovalNoticeTitle =>
      'Admin approval required before mentor access';

  @override
  String get adminApprovalNoticeBody =>
      'Verifying your email does not grant mentor privileges. Your application stays pending until an administrator reviews your credentials.';

  @override
  String get welcomeBackTitle => 'Welcome back';

  @override
  String get welcomeBackBody => 'Log in with your email and password.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get forgotPasswordCta => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordHeading => 'Reset your password';

  @override
  String get resetPasswordBody =>
      'Enter the email address on your account. We\'ll send you a secure reset link.';

  @override
  String get sendResetEmailCta => 'Send reset email';

  @override
  String get resetEmailSentTitle => 'Reset email sent';

  @override
  String get resetEmailSentBody =>
      'Open the password-reset link in your email, choose a new password, and then log in again.';

  @override
  String get backToLoginCta => 'Back to log in';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailVerifiedHeading => 'Email verified';

  @override
  String get verifyEmailSettingUpBody =>
      'Your email is verified. Setting up your account…';

  @override
  String get iVerifiedMyEmailCta => 'I verified my email';

  @override
  String get checkingStatusLabel => 'Checking…';

  @override
  String get credentialUploadWarningTitle =>
      'Supporting credential image not uploaded';

  @override
  String get credentialUploadWarningBody =>
      'Your credential image failed to upload during sign-up. Tap Edit application details below to attach it before review.';

  @override
  String get mentorRevokedTitle => 'Your mentor privileges were revoked';

  @override
  String get mentorRevokedDefaultBody =>
      'An administrator removed your mentor privileges. Update your details below to apply for reinstatement.';

  @override
  String get mentorRejectedTitle =>
      'Your mentor application was not approved yet';

  @override
  String get mentorRejectedDefaultBody =>
      'Please review the feedback from our team, update your professional details, and resubmit your application.';

  @override
  String get mentorPendingVerifiedTitle =>
      'Your email is verified — application awaiting review';

  @override
  String get checkApplicationStatusCta => 'Check application status';

  @override
  String get editApplicationDetailsCta => 'Edit application details';

  @override
  String get updateResubmitApplicationCta => 'Update & resubmit application';

  @override
  String get approveMentorCta => 'Approve mentor';

  @override
  String get approveMentorApplicationCta => 'Approve mentor application';

  @override
  String get rejectWithReasonCta => 'Reject with reason';

  @override
  String get rejectApplicationCta => 'Reject application';

  @override
  String get verifiedEmailAccountBadge => 'Verified email account';

  @override
  String get languageSelectBody =>
      'Select the display language for your UpBridge workspace.';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account?';

  @override
  String get mentorPendingVerifiedBody =>
      'Your email has been verified successfully. Your mentor application is now awaiting review by the UpBridge Rwanda administration team. Verifying your email does not grant mentor access. You will receive an update once your application has been reviewed.';

  @override
  String get mentorReviewFollowsVerificationTitle =>
      'Mentor review follows verification';

  @override
  String get mentorReviewFollowsVerificationBody =>
      'Verifying your email confirms your address only — it does not approve mentor access. Once verified, your application enters admin review.';

  @override
  String get cvCompletenessTitle => 'CV Completeness';

  @override
  String cvCompletenessSubtitle(int percent) {
    return '$percent% completed';
  }

  @override
  String get cvCompletenessComplete =>
      'Your CV is complete and ready to share!';

  @override
  String get cvCompletenessGuidance =>
      'Complete missing sections to stand out to mentors and employers.';

  @override
  String cvMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections to complete',
      one: '1 section to complete',
    );
    return '$_temp0';
  }

  @override
  String get cvItemPhoto => 'Profile photo';

  @override
  String get cvItemHeadline => 'Professional headline';

  @override
  String get cvItemBio => 'About / Bio';

  @override
  String get cvItemSkills => 'Skills (at least 3)';

  @override
  String get cvItemEducation => 'Education';

  @override
  String get cvItemExperience => 'Experience';

  @override
  String get cvItemCvAsset => 'Attached CV file';

  @override
  String get cvMissingBadge => 'Missing';

  @override
  String get cvCompletedBadge => 'Completed';

  @override
  String get editProfileCta => 'Edit profile & CV';

  @override
  String get shareExportCvCta => 'Share / Export CV';

  @override
  String get aboutAndSkillsTitle => 'About & Skills';

  @override
  String get noSkillsYet => 'No skills added yet.';

  @override
  String get educationTitle => 'Education';

  @override
  String get noEducationYet => 'No education entries yet';

  @override
  String get addEducationCta => 'Add education';

  @override
  String get experienceTitle => 'Experience';

  @override
  String get noExperienceYet => 'No experience entries yet';

  @override
  String get addExperienceCta => 'Add experience';

  @override
  String get certificatesTitle => 'Certificates & evidence';

  @override
  String get noCertificatesYet => 'No certificates added yet';

  @override
  String get addCertificateCta => 'Add certificate';

  @override
  String get portfolioProjectsTitle => 'Portfolio projects';

  @override
  String get noProjectsYet => 'No portfolio projects yet';

  @override
  String get addProjectCta => 'Add project';
}
