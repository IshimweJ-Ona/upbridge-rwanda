import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'UpBridge Rwanda'**
  String get appTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get tabLearn;

  /// No description provided for @tabMentors.
  ///
  /// In en, this message translates to:
  /// **'Mentors'**
  String get tabMentors;

  /// No description provided for @tabJobs.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get tabJobs;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabMentorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabMentorDashboard;

  /// No description provided for @tabMentorCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get tabMentorCourses;

  /// No description provided for @tabMentorRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tabMentorRequests;

  /// No description provided for @tabMentorSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get tabMentorSessions;

  /// No description provided for @tabMentorMentees.
  ///
  /// In en, this message translates to:
  /// **'Mentees'**
  String get tabMentorMentees;

  /// No description provided for @tabAdminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabAdminOverview;

  /// No description provided for @tabAdminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabAdminUsers;

  /// No description provided for @tabAdminMentors.
  ///
  /// In en, this message translates to:
  /// **'Mentors'**
  String get tabAdminMentors;

  /// No description provided for @tabAdminContent.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get tabAdminContent;

  /// No description provided for @tabAdminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabAdminSettings;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleMentor.
  ///
  /// In en, this message translates to:
  /// **'Mentor'**
  String get roleMentor;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @menteeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mentee'**
  String get menteeLabel;

  /// No description provided for @sessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionLabel;

  /// No description provided for @requestLabel.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestLabel;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Build practical IT and soft skills, connect with verified mentors, and showcase your verified portfolio.'**
  String get welcomeTagline;

  /// No description provided for @createFreeAccount.
  ///
  /// In en, this message translates to:
  /// **'Create free account'**
  String get createFreeAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get signOut;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @emptyStateDefault.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyStateDefault;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get offlineMessage;

  /// No description provided for @studentDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get studentDashboardTitle;

  /// No description provided for @mentorDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentor Dashboard'**
  String get mentorDashboardTitle;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Console'**
  String get adminDashboardTitle;

  /// No description provided for @nextActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Action'**
  String get nextActionLabel;

  /// No description provided for @activeMentorshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Mentorship'**
  String get activeMentorshipLabel;

  /// No description provided for @upcomingSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Session'**
  String get upcomingSessionLabel;

  /// No description provided for @learningProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get learningProgressLabel;

  /// No description provided for @recommendedMentorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended Mentors'**
  String get recommendedMentorsLabel;

  /// No description provided for @opportunitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get opportunitiesLabel;

  /// No description provided for @pendingRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequestsLabel;

  /// No description provided for @myMenteesLabel.
  ///
  /// In en, this message translates to:
  /// **'My Mentees'**
  String get myMenteesLabel;

  /// No description provided for @mentorPendingBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentor application pending review'**
  String get mentorPendingBannerTitle;

  /// No description provided for @mentorPendingBannerBody.
  ///
  /// In en, this message translates to:
  /// **'An administrator must approve your application before mentor tools unlock.'**
  String get mentorPendingBannerBody;

  /// No description provided for @cvPortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'CV & Portfolio'**
  String get cvPortfolioTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No courses published yet'**
  String get noCoursesYet;

  /// No description provided for @noCoursesBody.
  ///
  /// In en, this message translates to:
  /// **'Published IT and soft-skills courses will appear here once added by an administrator.'**
  String get noCoursesBody;

  /// No description provided for @noOpportunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No opportunities open right now'**
  String get noOpportunitiesYet;

  /// No description provided for @noOpportunitiesBody.
  ///
  /// In en, this message translates to:
  /// **'Published internships, jobs, and paid gigs will appear here.'**
  String get noOpportunitiesBody;

  /// No description provided for @noMentorsYet.
  ///
  /// In en, this message translates to:
  /// **'No verified mentors available yet'**
  String get noMentorsYet;

  /// No description provided for @noMentorsBody.
  ///
  /// In en, this message translates to:
  /// **'Approved mentors will appear here once verified by an administrator.'**
  String get noMentorsBody;

  /// No description provided for @mentorCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get mentorCoursesTitle;

  /// No description provided for @createCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'New course'**
  String get createCourseLabel;

  /// No description provided for @publishLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishLabel;

  /// No description provided for @saveDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraftLabel;

  /// No description provided for @archiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @engagementLabel.
  ///
  /// In en, this message translates to:
  /// **'Learner engagement'**
  String get engagementLabel;

  /// No description provided for @rescheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleLabel;

  /// No description provided for @revokeMentorLabel.
  ///
  /// In en, this message translates to:
  /// **'Revoke mentor'**
  String get revokeMentorLabel;

  /// No description provided for @mentorPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your mentor application is being reviewed by our administration team.'**
  String get mentorPendingMessage;

  /// No description provided for @mentorApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your mentor application has been approved.'**
  String get mentorApprovedMessage;

  /// No description provided for @mentorRevokedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your mentor privileges were revoked by an administrator.'**
  String get mentorRevokedMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @errorLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get errorLoadingTitle;

  /// No description provided for @scheduleSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule session'**
  String get scheduleSessionLabel;

  /// No description provided for @auditLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit logs'**
  String get auditLogsTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @joinUpBridgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join UpBridge Rwanda'**
  String get joinUpBridgeTitle;

  /// No description provided for @joinUpBridgeBody.
  ///
  /// In en, this message translates to:
  /// **'Build career-ready skills, verify real projects, and connect with vetted mentors across Rwanda.'**
  String get joinUpBridgeBody;

  /// No description provided for @joinAsYouthTitle.
  ///
  /// In en, this message translates to:
  /// **'Join as Youth'**
  String get joinAsYouthTitle;

  /// No description provided for @joinAsYouthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn skills, build proof & connect with mentors'**
  String get joinAsYouthSubtitle;

  /// No description provided for @applyAsMentorTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply as Mentor'**
  String get applyAsMentorTitle;

  /// No description provided for @applyAsMentorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guide rising talent (requires admin approval)'**
  String get applyAsMentorSubtitle;

  /// No description provided for @createYouthAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Create Youth Account'**
  String get createYouthAccountCta;

  /// No description provided for @submitMentorApplicationCta.
  ///
  /// In en, this message translates to:
  /// **'Submit Mentor Application'**
  String get submitMentorApplicationCta;

  /// No description provided for @adminApprovalNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin approval required before mentor access'**
  String get adminApprovalNoticeTitle;

  /// No description provided for @adminApprovalNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email does not grant mentor privileges. Your application stays pending until an administrator reviews your credentials.'**
  String get adminApprovalNoticeBody;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackBody.
  ///
  /// In en, this message translates to:
  /// **'Log in with your email and password.'**
  String get welcomeBackBody;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @forgotPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordCta;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordHeading;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address on your account. We\'ll send you a secure reset link.'**
  String get resetPasswordBody;

  /// No description provided for @sendResetEmailCta.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmailCta;

  /// No description provided for @resetEmailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent'**
  String get resetEmailSentTitle;

  /// No description provided for @resetEmailSentBody.
  ///
  /// In en, this message translates to:
  /// **'Open the password-reset link in your email, choose a new password, and then log in again.'**
  String get resetEmailSentBody;

  /// No description provided for @backToLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get backToLoginCta;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailVerifiedHeading.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get verifyEmailVerifiedHeading;

  /// No description provided for @verifyEmailSettingUpBody.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified. Setting up your account…'**
  String get verifyEmailSettingUpBody;

  /// No description provided for @iVerifiedMyEmailCta.
  ///
  /// In en, this message translates to:
  /// **'I verified my email'**
  String get iVerifiedMyEmailCta;

  /// No description provided for @checkingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingStatusLabel;

  /// No description provided for @credentialUploadWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Supporting credential image not uploaded'**
  String get credentialUploadWarningTitle;

  /// No description provided for @credentialUploadWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Your credential image failed to upload during sign-up. Tap Edit application details below to attach it before review.'**
  String get credentialUploadWarningBody;

  /// No description provided for @mentorRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mentor privileges were revoked'**
  String get mentorRevokedTitle;

  /// No description provided for @mentorRevokedDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'An administrator removed your mentor privileges. Update your details below to apply for reinstatement.'**
  String get mentorRevokedDefaultBody;

  /// No description provided for @mentorRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mentor application was not approved yet'**
  String get mentorRejectedTitle;

  /// No description provided for @mentorRejectedDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Please review the feedback from our team, update your professional details, and resubmit your application.'**
  String get mentorRejectedDefaultBody;

  /// No description provided for @mentorPendingVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified — application awaiting review'**
  String get mentorPendingVerifiedTitle;

  /// No description provided for @checkApplicationStatusCta.
  ///
  /// In en, this message translates to:
  /// **'Check application status'**
  String get checkApplicationStatusCta;

  /// No description provided for @editApplicationDetailsCta.
  ///
  /// In en, this message translates to:
  /// **'Edit application details'**
  String get editApplicationDetailsCta;

  /// No description provided for @updateResubmitApplicationCta.
  ///
  /// In en, this message translates to:
  /// **'Update & resubmit application'**
  String get updateResubmitApplicationCta;

  /// No description provided for @approveMentorCta.
  ///
  /// In en, this message translates to:
  /// **'Approve mentor'**
  String get approveMentorCta;

  /// No description provided for @approveMentorApplicationCta.
  ///
  /// In en, this message translates to:
  /// **'Approve mentor application'**
  String get approveMentorApplicationCta;

  /// No description provided for @rejectWithReasonCta.
  ///
  /// In en, this message translates to:
  /// **'Reject with reason'**
  String get rejectWithReasonCta;

  /// No description provided for @rejectApplicationCta.
  ///
  /// In en, this message translates to:
  /// **'Reject application'**
  String get rejectApplicationCta;

  /// No description provided for @verifiedEmailAccountBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified email account'**
  String get verifiedEmailAccountBadge;

  /// No description provided for @languageSelectBody.
  ///
  /// In en, this message translates to:
  /// **'Select the display language for your UpBridge workspace.'**
  String get languageSelectBody;

  /// No description provided for @alreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountPrompt;

  /// No description provided for @mentorPendingVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Your email has been verified successfully. Your mentor application is now awaiting review by the UpBridge Rwanda administration team. Verifying your email does not grant mentor access. You will receive an update once your application has been reviewed.'**
  String get mentorPendingVerifiedBody;

  /// No description provided for @mentorReviewFollowsVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentor review follows verification'**
  String get mentorReviewFollowsVerificationTitle;

  /// No description provided for @mentorReviewFollowsVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email confirms your address only — it does not approve mentor access. Once verified, your application enters admin review.'**
  String get mentorReviewFollowsVerificationBody;

  /// No description provided for @cvCompletenessTitle.
  ///
  /// In en, this message translates to:
  /// **'CV Completeness'**
  String get cvCompletenessTitle;

  /// No description provided for @cvCompletenessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String cvCompletenessSubtitle(int percent);

  /// No description provided for @cvCompletenessComplete.
  ///
  /// In en, this message translates to:
  /// **'Your CV is complete and ready to share!'**
  String get cvCompletenessComplete;

  /// No description provided for @cvCompletenessGuidance.
  ///
  /// In en, this message translates to:
  /// **'Complete missing sections to stand out to mentors and employers.'**
  String get cvCompletenessGuidance;

  /// No description provided for @cvMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 section to complete} other{{count} sections to complete}}'**
  String cvMissingCount(int count);

  /// No description provided for @cvItemPhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get cvItemPhoto;

  /// No description provided for @cvItemHeadline.
  ///
  /// In en, this message translates to:
  /// **'Professional headline'**
  String get cvItemHeadline;

  /// No description provided for @cvItemBio.
  ///
  /// In en, this message translates to:
  /// **'About / Bio'**
  String get cvItemBio;

  /// No description provided for @cvItemSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills (at least 3)'**
  String get cvItemSkills;

  /// No description provided for @cvItemEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get cvItemEducation;

  /// No description provided for @cvItemExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get cvItemExperience;

  /// No description provided for @cvItemCvAsset.
  ///
  /// In en, this message translates to:
  /// **'Attached CV file'**
  String get cvItemCvAsset;

  /// No description provided for @cvMissingBadge.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get cvMissingBadge;

  /// No description provided for @cvCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get cvCompletedBadge;

  /// No description provided for @editProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Edit profile & CV'**
  String get editProfileCta;

  /// No description provided for @shareExportCvCta.
  ///
  /// In en, this message translates to:
  /// **'Share / Export CV'**
  String get shareExportCvCta;

  /// No description provided for @aboutAndSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'About & Skills'**
  String get aboutAndSkillsTitle;

  /// No description provided for @noSkillsYet.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet.'**
  String get noSkillsYet;

  /// No description provided for @educationTitle.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationTitle;

  /// No description provided for @noEducationYet.
  ///
  /// In en, this message translates to:
  /// **'No education entries yet'**
  String get noEducationYet;

  /// No description provided for @addEducationCta.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get addEducationCta;

  /// No description provided for @experienceTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceTitle;

  /// No description provided for @noExperienceYet.
  ///
  /// In en, this message translates to:
  /// **'No experience entries yet'**
  String get noExperienceYet;

  /// No description provided for @addExperienceCta.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get addExperienceCta;

  /// No description provided for @certificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates & evidence'**
  String get certificatesTitle;

  /// No description provided for @noCertificatesYet.
  ///
  /// In en, this message translates to:
  /// **'No certificates added yet'**
  String get noCertificatesYet;

  /// No description provided for @addCertificateCta.
  ///
  /// In en, this message translates to:
  /// **'Add certificate'**
  String get addCertificateCta;

  /// No description provided for @portfolioProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio projects'**
  String get portfolioProjectsTitle;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No portfolio projects yet'**
  String get noProjectsYet;

  /// No description provided for @addProjectCta.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProjectCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'rw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'rw':
      return AppLocalizationsRw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
