// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'UpBridge Rwanda';

  @override
  String greeting(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabLearn => 'Apprendre';

  @override
  String get tabMentors => 'Mentors';

  @override
  String get tabJobs => 'Opportunités';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabMentorDashboard => 'Tableau';

  @override
  String get tabMentorCourses => 'Cours';

  @override
  String get tabMentorRequests => 'Demandes';

  @override
  String get tabMentorSessions => 'Sessions';

  @override
  String get tabMentorMentees => 'Mentorés';

  @override
  String get tabAdminOverview => 'Aperçu';

  @override
  String get tabAdminUsers => 'Utilisateurs';

  @override
  String get tabAdminMentors => 'Mentors';

  @override
  String get tabAdminContent => 'Catalogue';

  @override
  String get tabAdminSettings => 'Paramètres';

  @override
  String get roleStudent => 'Étudiant';

  @override
  String get roleMentor => 'Mentor';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get menteeLabel => 'Mentoré';

  @override
  String get sessionLabel => 'Session';

  @override
  String get requestLabel => 'Demande';

  @override
  String get welcomeTagline =>
      'Développez vos compétences IT et relationnelles, échangez avec des mentors certifiés et publiez votre portfolio.';

  @override
  String get createFreeAccount => 'Créer un compte gratuit';

  @override
  String get alreadyHaveAccount => 'J\'ai déjà un compte';

  @override
  String get signIn => 'Connexion';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get retry => 'Réessayer';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get submit => 'Envoyer';

  @override
  String get loading => 'Chargement…';

  @override
  String get emptyStateDefault => 'Rien ici pour le moment.';

  @override
  String get offlineMessage =>
      'Vérifiez votre connexion Internet et réessayez.';

  @override
  String get studentDashboardTitle => 'Tableau étudiant';

  @override
  String get mentorDashboardTitle => 'Tableau mentor';

  @override
  String get adminDashboardTitle => 'Console admin';

  @override
  String get nextActionLabel => 'Prochaine action';

  @override
  String get activeMentorshipLabel => 'Mentorat actif';

  @override
  String get upcomingSessionLabel => 'Prochaine session';

  @override
  String get learningProgressLabel => 'Progression';

  @override
  String get recommendedMentorsLabel => 'Mentors recommandés';

  @override
  String get opportunitiesLabel => 'Opportunités';

  @override
  String get pendingRequestsLabel => 'Demandes en attente';

  @override
  String get myMenteesLabel => 'Mes mentorés';

  @override
  String get mentorPendingBannerTitle => 'Candidature mentor en attente';

  @override
  String get mentorPendingBannerBody =>
      'Un administrateur doit approuver votre candidature avant d\'accéder à l\'espace mentor.';

  @override
  String get cvPortfolioTitle => 'CV & Portfolio';

  @override
  String get languageTitle => 'Langue';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get darkModeLabel => 'Mode sombre';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noCoursesYet => 'Aucun cours publié';

  @override
  String get noCoursesBody =>
      'Les cours publiés apparaîtront ici dès qu\'un administrateur les ajoutera.';

  @override
  String get noOpportunitiesYet => 'Aucune opportunité ouverte';

  @override
  String get noOpportunitiesBody =>
      'Les stages, emplois et missions publiés apparaîtront ici.';

  @override
  String get noMentorsYet => 'Aucun mentor vérifié disponible';

  @override
  String get noMentorsBody => 'Les mentors approuvés apparaîtront ici.';

  @override
  String get mentorCoursesTitle => 'Mes cours';

  @override
  String get createCourseLabel => 'Nouveau cours';

  @override
  String get publishLabel => 'Publier';

  @override
  String get saveDraftLabel => 'Brouillon';

  @override
  String get archiveLabel => 'Archiver';

  @override
  String get previewLabel => 'Aperçu';

  @override
  String get engagementLabel => 'Engagement';

  @override
  String get rescheduleLabel => 'Reprogrammer';

  @override
  String get revokeMentorLabel => 'Révoquer mentor';

  @override
  String get mentorPendingMessage =>
      'Votre candidature de mentor est en cours d\'examen par notre équipe d\'administration.';

  @override
  String get mentorApprovedMessage =>
      'Félicitations ! Votre candidature de mentor a été approuvée.';

  @override
  String get mentorRevokedMessage =>
      'Vos privilèges de mentor ont été révoqués par un administrateur.';

  @override
  String get searchHint => 'Rechercher';

  @override
  String get errorLoadingTitle => 'Impossible de charger les données';

  @override
  String get scheduleSessionLabel => 'Planifier une session';

  @override
  String get auditLogsTitle => 'Journal d\'audit';

  @override
  String get createAccountTitle => 'Créer un compte';

  @override
  String get joinUpBridgeTitle => 'Rejoindre UpBridge Rwanda';

  @override
  String get joinUpBridgeBody =>
      'Développez des compétences recherchées, faites valider vos projets et échangez avec des mentors qualifiés au Rwanda.';

  @override
  String get joinAsYouthTitle => 'Rejoindre comme jeune';

  @override
  String get joinAsYouthSubtitle =>
      'Apprendre, prouver ses compétences et trouver un mentor';

  @override
  String get applyAsMentorTitle => 'Postuler comme mentor';

  @override
  String get applyAsMentorSubtitle =>
      'Accompagner de nouveaux talents (validation requise)';

  @override
  String get createYouthAccountCta => 'Créer un compte jeune';

  @override
  String get submitMentorApplicationCta => 'Soumettre ma candidature de mentor';

  @override
  String get adminApprovalNoticeTitle =>
      'Validation administrateur requise avant l\'accès mentor';

  @override
  String get adminApprovalNoticeBody =>
      'La vérification de votre e-mail n\'accorde pas les droits de mentor. Votre dossier reste en attente jusqu\'à sa validation par un administrateur.';

  @override
  String get welcomeBackTitle => 'Bon retour';

  @override
  String get welcomeBackBody =>
      'Connectez-vous avec votre adresse e-mail et votre mot de passe.';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get forgotPasswordCta => 'Mot de passe oublié ?';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordHeading => 'Réinitialiser votre mot de passe';

  @override
  String get resetPasswordBody =>
      'Saisissez l\'adresse e-mail associée à votre compte. Nous vous enverrons un lien sécurisé.';

  @override
  String get sendResetEmailCta => 'Envoyer l\'e-mail de réinitialisation';

  @override
  String get resetEmailSentTitle => 'E-mail envoyé';

  @override
  String get resetEmailSentBody =>
      'Ouvrez le lien reçu par e-mail, choisissez un nouveau mot de passe, puis reconnectez-vous.';

  @override
  String get backToLoginCta => 'Retour à la connexion';

  @override
  String get verifyEmailTitle => 'Vérifiez votre e-mail';

  @override
  String get verifyEmailVerifiedHeading => 'E-mail vérifié';

  @override
  String get verifyEmailSettingUpBody =>
      'Votre adresse e-mail est vérifiée. Configuration du compte…';

  @override
  String get iVerifiedMyEmailCta => 'J\'ai vérifié mon e-mail';

  @override
  String get checkingStatusLabel => 'Vérification…';

  @override
  String get credentialUploadWarningTitle => 'Justificatif non téléversé';

  @override
  String get credentialUploadWarningBody =>
      'Votre justificatif n\'a pas pu être envoyé lors de l\'inscription. Touchez Modifier la candidature ci-dessous pour le joindre avant l\'examen.';

  @override
  String get mentorRevokedTitle => 'Vos privilèges de mentor ont été révoqués';

  @override
  String get mentorRevokedDefaultBody =>
      'Un administrateur a retiré vos privilèges de mentor. Mettez à jour votre dossier ci-dessous pour demander une réactivation.';

  @override
  String get mentorRejectedTitle =>
      'Votre candidature de mentor n\'a pas encore été approuvée';

  @override
  String get mentorRejectedDefaultBody =>
      'Consultez le retour de notre équipe, mettez à jour votre profil professionnel et soumettez à nouveau votre dossier.';

  @override
  String get mentorPendingVerifiedTitle =>
      'E-mail vérifié — candidature en attente d\'examen';

  @override
  String get checkApplicationStatusCta => 'Vérifier l\'état du dossier';

  @override
  String get editApplicationDetailsCta => 'Modifier la candidature';

  @override
  String get updateResubmitApplicationCta => 'Mettre à jour et soumettre';

  @override
  String get approveMentorCta => 'Approuver le mentor';

  @override
  String get approveMentorApplicationCta => 'Approuver la candidature';

  @override
  String get rejectWithReasonCta => 'Refuser avec un motif';

  @override
  String get rejectApplicationCta => 'Refuser la candidature';

  @override
  String get verifiedEmailAccountBadge => 'Compte e-mail vérifié';

  @override
  String get languageSelectBody =>
      'Choisissez la langue d\'affichage de votre espace UpBridge.';

  @override
  String get alreadyHaveAccountPrompt => 'Vous avez déjà un compte ?';

  @override
  String get mentorPendingVerifiedBody =>
      'Votre adresse e-mail a été vérifiée avec succès. Votre candidature de mentor est en cours d\'examen par l\'équipe d\'administration d\'UpBridge Rwanda. La vérification de l\'e-mail n\'accorde pas l\'accès mentor. Vous recevrez une réponse dès que votre dossier aura été examiné.';

  @override
  String get mentorReviewFollowsVerificationTitle =>
      'L\'examen mentor suit la vérification';

  @override
  String get mentorReviewFollowsVerificationBody =>
      'La vérification confirme uniquement votre adresse e-mail — elle n\'accorde pas l\'accès mentor. Une fois vérifiée, votre candidature est transmise aux administrateurs.';
}
