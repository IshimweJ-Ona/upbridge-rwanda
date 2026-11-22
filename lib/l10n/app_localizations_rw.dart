// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String get appTitle => 'UpBridge Rwanda';

  @override
  String greeting(String name) {
    return 'Muraho, $name';
  }

  @override
  String get tabHome => 'Ahabanza';

  @override
  String get tabLearn => 'Kwiga';

  @override
  String get tabMentors => 'Abajyanama';

  @override
  String get tabJobs => 'Amahirwe';

  @override
  String get tabProfile => 'Umwirondoro';

  @override
  String get tabMentorDashboard => 'Incamake';

  @override
  String get tabMentorCourses => 'Amasomo';

  @override
  String get tabMentorRequests => 'Ubusabe';

  @override
  String get tabMentorSessions => 'Ibiganiro';

  @override
  String get tabMentorMentees => 'Abo nyobora';

  @override
  String get tabAdminOverview => 'Incamake';

  @override
  String get tabAdminUsers => 'Abakoresha';

  @override
  String get tabAdminMentors => 'Abajyanama';

  @override
  String get tabAdminContent => 'Ibikubiyemo';

  @override
  String get tabAdminSettings => 'Igenamiterere';

  @override
  String get roleStudent => 'Umunyeshuri';

  @override
  String get roleMentor => 'Umujyanama';

  @override
  String get roleAdmin => 'Umuyobozi';

  @override
  String get menteeLabel => 'Uwigishwa';

  @override
  String get sessionLabel => 'Ikiganiro';

  @override
  String get requestLabel => 'Ubusabe';

  @override
  String get welcomeTagline =>
      'Iga ubumenyi ngiro mu ikoranabuhanga, uhure n\'abajyanama bemewe, kandi wubake dosiye y\'akazi.';

  @override
  String get createFreeAccount => 'Fungura konti ku buntu';

  @override
  String get alreadyHaveAccount => 'Nsanzwe mfite konti';

  @override
  String get signIn => 'Injira';

  @override
  String get signOut => 'Sohoka';

  @override
  String get retry => 'Ongera ugerageze';

  @override
  String get save => 'Bika';

  @override
  String get cancel => 'Hagarika';

  @override
  String get delete => 'Siba';

  @override
  String get edit => 'Hindura';

  @override
  String get submit => 'Ohereza';

  @override
  String get loading => 'Birimo gutunganywa…';

  @override
  String get emptyStateDefault => 'Nta birimo kugeza ubu.';

  @override
  String get offlineMessage => 'Reba murandasi yawe maze wongere ugerageze.';

  @override
  String get studentDashboardTitle => 'Ikibaho cy\'umunyeshuri';

  @override
  String get mentorDashboardTitle => 'Ikibaho cy\'umujyanama';

  @override
  String get adminDashboardTitle => 'Ubuyobozi';

  @override
  String get nextActionLabel => 'Igikorwa gikurikira';

  @override
  String get activeMentorshipLabel => 'Ubujyanama bukora';

  @override
  String get upcomingSessionLabel => 'Ikiganiro gikurikira';

  @override
  String get learningProgressLabel => 'Aho ugeze wiga';

  @override
  String get recommendedMentorsLabel => 'Abajyanama bagukwiriye';

  @override
  String get opportunitiesLabel => 'Amahirwe y\'akazi';

  @override
  String get pendingRequestsLabel => 'Ubusabe butegereje';

  @override
  String get myMenteesLabel => 'Abo nyobora';

  @override
  String get mentorPendingBannerTitle =>
      'Ubusabe bw\'ubujyanama buracyasuzumwa';

  @override
  String get mentorPendingBannerBody =>
      'Umuyobozi agomba kwemeza ubusabe bwawe mbere y\'uko ukoresha ibikoresho by\'abajyanama.';

  @override
  String get cvPortfolioTitle => 'CV n\'imishinga';

  @override
  String get languageTitle => 'Ururimi';

  @override
  String get appearanceTitle => 'Imigaragarire';

  @override
  String get darkModeLabel => 'Uburyo bw\'ijoro';

  @override
  String get notificationsTitle => 'Amakuru';

  @override
  String get noCoursesYet => 'Nta masomo arasohoka';

  @override
  String get noCoursesBody =>
      'Amasomo y\'ikoranabuhanga n\'ubumenyi ngiro azagaragara hano namara gushyirwaho.';

  @override
  String get noOpportunitiesYet => 'Nta mahirwe afunguye ubu';

  @override
  String get noOpportunitiesBody =>
      'Imyanya y\'akazi n\'iyimenyerezamwuga izagaragara hano.';

  @override
  String get noMentorsYet => 'Nta bajyanama bemewe baraboneka';

  @override
  String get noMentorsBody => 'Abajyanama bemewe bazagaragara hano.';

  @override
  String get mentorCoursesTitle => 'Amasomo yanjye';

  @override
  String get createCourseLabel => 'Isomo rishya';

  @override
  String get publishLabel => 'Tangaza';

  @override
  String get saveDraftLabel => 'Bika nk\'inyandiko';

  @override
  String get archiveLabel => 'Shyingura';

  @override
  String get previewLabel => 'Reba mbere';

  @override
  String get engagementLabel => 'Imikoreshereze y\'abanyeshuri';

  @override
  String get rescheduleLabel => 'Hindura itariki';

  @override
  String get revokeMentorLabel => 'Kura uburenganzira';

  @override
  String get mentorPendingMessage =>
      'Ubusabe bwawe bw\'ubujyanama burimo gusuzumwa n\'itsinda ryacu ry\'ubuyobozi.';

  @override
  String get mentorApprovedMessage =>
      'Turakwishimiye! Ubusabe bwawe bw\'ubujyanama bwemejwe.';

  @override
  String get mentorRevokedMessage =>
      'Uburenganzira bwawe bw\'ubujyanama bwahagaritswe n\'umuyobozi.';

  @override
  String get searchHint => 'Shakisha';

  @override
  String get errorLoadingTitle => 'Ntibyashobotse kubona amakuru';

  @override
  String get scheduleSessionLabel => 'Tegura ikiganiro';

  @override
  String get auditLogsTitle => 'Ibyakozwe n\'ubuyobozi';

  @override
  String get createAccountTitle => 'Fungura konti';

  @override
  String get joinUpBridgeTitle => 'Injira muri UpBridge Rwanda';

  @override
  String get joinUpBridgeBody =>
      'Iga ubumenyi bw\'akazi, wubake imishinga yemewe, kandi uhure n\'abajyanama bemewe mu Rwanda.';

  @override
  String get joinAsYouthTitle => 'Injira nk\'urubyiruko';

  @override
  String get joinAsYouthSubtitle =>
      'Iga ubumenyi, wubake dosiye kandi uhure n\'abajyanama';

  @override
  String get applyAsMentorTitle => 'Saba kuba umujyanama';

  @override
  String get applyAsMentorSubtitle =>
      'Yobora impano nshya (bisaba kwemezwa n\'ubuyobozi)';

  @override
  String get createYouthAccountCta => 'Fungura konti y\'urubyiruko';

  @override
  String get submitMentorApplicationCta => 'Ohereza ubusabe bw\'ubujyanama';

  @override
  String get adminApprovalNoticeTitle =>
      'Ubujyanama bwemezwa n\'ubuyobozi mbere yo gutangira';

  @override
  String get adminApprovalNoticeBody =>
      'Kwemeza imeli yawe ntibihita bitanga uburenganzira bw\'ubujyanama. Ubusabe bwawe butegereza isuzumwa ry\'ubuyobozi.';

  @override
  String get welcomeBackTitle => 'Murakaza neza nanone';

  @override
  String get welcomeBackBody => 'Injira ukoresheje imeli n\'ijambobanga ryawe.';

  @override
  String get emailLabel => 'Imeli';

  @override
  String get passwordLabel => 'Ijambobanga';

  @override
  String get confirmPasswordLabel => 'Emeza ijambobanga';

  @override
  String get fullNameLabel => 'Amazina yose';

  @override
  String get phoneNumberLabel => 'Nomero ya telefoni';

  @override
  String get forgotPasswordCta => 'Wibagiwe ijambobanga?';

  @override
  String get resetPasswordTitle => 'Hindura ijambobanga';

  @override
  String get resetPasswordHeading => 'Hindura ijambobanga ryawe';

  @override
  String get resetPasswordBody =>
      'Andika imeli ikoreshwa kuri konti yawe. Turakoherereza ihuza ryo guhindura ijambobanga.';

  @override
  String get sendResetEmailCta => 'Ohereza imeli yo guhindura';

  @override
  String get resetEmailSentTitle => 'Imeli yo guhindura yoherejwe';

  @override
  String get resetEmailSentBody =>
      'Fungura ihuza mu imeli yawe, uhitemo ijambobanga rishya, hanyuma wongere winjire.';

  @override
  String get backToLoginCta => 'Subira kwinjira';

  @override
  String get verifyEmailTitle => 'Emeza imeli yawe';

  @override
  String get verifyEmailVerifiedHeading => 'Imeli yemejwe';

  @override
  String get verifyEmailSettingUpBody =>
      'Imeli yawe yemejwe. Konti yawe irimo gutunganywa…';

  @override
  String get iVerifiedMyEmailCta => 'Nemeje imeli yanjye';

  @override
  String get checkingStatusLabel => 'Birimo kugenzurwa…';

  @override
  String get credentialUploadWarningTitle =>
      'Ifoto y\'ibyangombwa ntiyoherejwe';

  @override
  String get credentialUploadWarningBody =>
      'Ifoto y\'ibyangombwa byawe ntiyabashije koherezwa wiyandikisha. Kanda Hindura amakuru y\'ubusabe hepfo kugira ngo uyongeremo mbere y\'isuzumwa.';

  @override
  String get mentorRevokedTitle =>
      'Uburenganzira bwawe bw\'ubujyanama bwahagaritswe';

  @override
  String get mentorRevokedDefaultBody =>
      'Umuyobozi yakuyeho uburenganzira bwawe bw\'ubujyanama. Vugurura amakuru yawe hepfo wongere usabe.';

  @override
  String get mentorRejectedTitle => 'Ubusabe bwawe bw\'ubujyanama ntibwemejwe';

  @override
  String get mentorRejectedDefaultBody =>
      'Soma ibitekerezo by\'ubuyobozi, uvugurure amakuru yawe y\'umwuga, maze wongere wohereze ubusabe.';

  @override
  String get mentorPendingVerifiedTitle =>
      'Imeli yawe yemejwe — ubusabe butegereje isuzumwa';

  @override
  String get checkApplicationStatusCta => 'Reba aho ubusabe bugeze';

  @override
  String get editApplicationDetailsCta => 'Hindura amakuru y\'ubusabe';

  @override
  String get updateResubmitApplicationCta =>
      'Vugurura wongere wohereze ubusabe';

  @override
  String get approveMentorCta => 'Emeza umujyanama';

  @override
  String get approveMentorApplicationCta => 'Emeza ubusabe bw\'ubujyanama';

  @override
  String get rejectWithReasonCta => 'Anga utange impamvu';

  @override
  String get rejectApplicationCta => 'Anga ubusabe';

  @override
  String get verifiedEmailAccountBadge => 'Konti ifite imeli yemejwe';

  @override
  String get languageSelectBody =>
      'Hitamo ururimi rugaragara muri UpBridge yawe.';

  @override
  String get alreadyHaveAccountPrompt => 'Usanzwe ufite konti?';

  @override
  String get mentorPendingVerifiedBody =>
      'Imeli yawe yemejwe neza. Ubusabe bwawe bw\'ubujyanama burimo gusuzumwa n\'itsinda ry\'ubuyobozi rya UpBridge Rwanda. Kwemeza imeli ntibiha uburenganzira bw\'ubujyanama. Uzamenyeshwa igihe isuzumwa rirangiye.';

  @override
  String get mentorReviewFollowsVerificationTitle =>
      'Isuzumwa ry\'ubujyanama rikurikira kwemeza imeli';

  @override
  String get mentorReviewFollowsVerificationBody =>
      'Kwemeza imeli byemeza aderesi yawe gusa — ntibitanga uburenganzira bw\'ubujyanama. Umaze kwemeza imeli, ubusabe bwawe bujya mu isuzumwa ry\'ubuyobozi.';
}
