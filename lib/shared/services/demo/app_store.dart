// Holds the explicitly in-memory demo session and cross-screen sample state.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/shared/widgets/feedback.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// Everything the demo shows, held in one immutable snapshot.
class AppData {
  const AppData({
    this.user,
    required this.youthId,
    required this.tasks,
    required this.reviews,
    required this.submissions,
    required this.mentors,
    required this.sessions,
    required this.opportunities,
    required this.applications,
    required this.projects,
    required this.notifications,
    required this.mentees,
    required this.platformUsers,
    required this.applicants,
    required this.forwards,
    required this.settings,
    this.goal,
    this.interests = const [],
    this.language = 'en',
    this.checkInDone = false,
    this.reviewedCount = 46,
    this.resetPhone,
  });

  final AppUser? user;
  final String youthId;
  final List<LearningTask> tasks;
  final List<Review> reviews;
  final List<Submission> submissions;
  final List<Mentor> mentors;
  final List<Session> sessions;
  final List<Opportunity> opportunities;
  final List<Application> applications;
  final List<Project> projects;
  final List<AppNotification> notifications;
  final List<Mentee> mentees;
  final List<PlatformUser> platformUsers;
  final List<MentorApplicant> applicants;
  final List<ForwardItem> forwards;
  final Map<String, bool> settings;
  final String? goal;
  final List<String> interests;
  final String language;
  final bool checkInDone;
  final int reviewedCount;
  final String? resetPhone;

  static const _keep = Object();

  AppData copyWith({
    Object? user = _keep,
    String? youthId,
    List<LearningTask>? tasks,
    List<Review>? reviews,
    List<Submission>? submissions,
    List<Session>? sessions,
    List<Opportunity>? opportunities,
    List<Application>? applications,
    List<Project>? projects,
    List<AppNotification>? notifications,
    List<Mentee>? mentees,
    List<PlatformUser>? platformUsers,
    List<MentorApplicant>? applicants,
    List<ForwardItem>? forwards,
    Map<String, bool>? settings,
    String? goal,
    List<String>? interests,
    String? language,
    bool? checkInDone,
    int? reviewedCount,
    String? resetPhone,
  }) =>
      AppData(
        user: identical(user, _keep) ? this.user : user as AppUser?,
        youthId: youthId ?? this.youthId,
        tasks: tasks ?? this.tasks,
        reviews: reviews ?? this.reviews,
        submissions: submissions ?? this.submissions,
        mentors: mentors,
        sessions: sessions ?? this.sessions,
        opportunities: opportunities ?? this.opportunities,
        applications: applications ?? this.applications,
        projects: projects ?? this.projects,
        notifications: notifications ?? this.notifications,
        mentees: mentees ?? this.mentees,
        platformUsers: platformUsers ?? this.platformUsers,
        applicants: applicants ?? this.applicants,
        forwards: forwards ?? this.forwards,
        settings: settings ?? this.settings,
        goal: goal ?? this.goal,
        interests: interests ?? this.interests,
        language: language ?? this.language,
        checkInDone: checkInDone ?? this.checkInDone,
        reviewedCount: reviewedCount ?? this.reviewedCount,
        resetPhone: resetPhone ?? this.resetPhone,
      );

  // ── lookups ──
  LearningTask task(String id) => tasks.firstWhere((t) => t.id == id, orElse: () => tasks.first);
  Opportunity? opportunity(String id) => _find(opportunities, (o) => o.id == id);
  Mentor mentor(String id) => mentors.firstWhere((m) => m.id == id, orElse: () => mentors.first);
  Project? project(String id) => _find(projects, (p) => p.id == id);
  Application? application(String id) => _find(applications, (a) => a.id == id);
  Application? applicationFor(String oppId) => _find(applications, (a) => a.oppId == oppId && a.youthId == user?.id && a.status != AppStatus.withdrawn);
  Submission? submission(String id) => _find(submissions, (s) => s.id == id);
  Mentee? mentee(String id) => _find(mentees, (m) => m.id == id);
  MentorApplicant? applicant(String id) => _find(applicants, (a) => a.id == id);
  ForwardItem? forward(String id) => _find(forwards, (f) => f.id == id);
  Project? projectForTask(String taskId) => _find(projects, (p) => p.taskId == taskId);

  List<Review> reviewsFor(String taskId) => reviews.where((r) => r.taskId == taskId).toList();
  Review? latestReview(String taskId) {
    final list = reviewsFor(taskId);
    return list.isEmpty ? null : list.first;
  }

  int get approvedCount => tasks.where((t) => t.status == TaskStatus.approved).length;
  bool get isFirstDay => approvedCount == 0;
  int get unreadCount => notifications.where((n) => n.unread).length;
  List<Application> get myApplications => applications.where((a) => a.youthId == user?.id).toList();
  List<Session> get mySessions => sessions.where((s) => s.youthId == user?.id).toList();
  List<Session> get mentorSessions => sessions.where((s) => s.mentorId == user?.id).toList();
  List<Submission> get queue => submissions.where((s) => !s.reviewed).toList();
  List<Opportunity> get openOpportunities => opportunities.where((o) => o.state == ListingState.open).toList();
  LearningTask? get currentTask {
    for (final s in [TaskStatus.changesRequested, TaskStatus.available, TaskStatus.inReview]) {
      for (final t in tasks) {
        if (t.status == s) return t;
      }
    }
    return null;
  }

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }
}

class AppStore extends Notifier<AppData> {
  @override
  AppData build() => AppData(
        youthId: 'jean',
        tasks: SampleData.jeanTasks(),
        reviews: SampleData.jeanReviews(),
        submissions: List.of(SampleData.submissions),
        mentors: SampleData.mentors,
        sessions: List.of(SampleData.sessions),
        opportunities: List.of(SampleData.opportunities),
        applications: List.of(SampleData.applications),
        projects: SampleData.jeanProjects(),
        notifications: List.of(SampleData.jeanNotifications),
        mentees: List.of(SampleData.mentees),
        platformUsers: List.of(SampleData.platformUsers),
        applicants: List.of(SampleData.applicants),
        forwards: List.of(SampleData.forwards.where((f) => f.id != 'f-jean')),
        settings: Map.of(SampleData.settings),
      );

  // ───────────────────────────── Auth ─────────────────────────────

  static String _key(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length >= 9 ? d.substring(d.length - 9) : d;
  }

  /// Returns an error message, or null when signed in.
  Future<String?> login(String phone, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final user = SampleData.accounts[_key(phone)];
    if (user == null) return 'No account uses this number. Check it, or create a free account.';
    if (password != SampleData.demoPassword) return 'That password doesn’t match this number. Try again or reset it.';
    _signIn(user);
    return null;
  }

  void loginAs(Role role) {
    _signIn(switch (role) {
      Role.youth => SampleData.jean,
      Role.mentor => SampleData.alice,
      Role.admin => SampleData.albert,
    });
  }

  void loginAsNewMentor() => _signIn(SampleData.claudine);

  void _signIn(AppUser user) {
    var next = state.copyWith(user: user);
    if (user.role == Role.youth && state.youthId != user.id) {
      next = next.copyWith(
        youthId: user.id,
        tasks: SampleData.jeanTasks(),
        reviews: SampleData.jeanReviews(),
        projects: SampleData.jeanProjects(),
        notifications: List.of(SampleData.jeanNotifications),
        checkInDone: false,
      );
    }
    if (user.role == Role.admin && !next.forwards.any((f) => f.applicationId == 'app-irembo')) {
      final seeded = SampleData.forwards.first;
      next = next.copyWith(
        forwards: [seeded, ...next.forwards],
        applications: next.application('app-irembo') != null
            ? next.applications
            : [
                const Application(
                  id: 'app-irembo',
                  ref: 'UB-2026-04817',
                  oppId: 'irembo',
                  youthId: 'jean',
                  youthName: 'Jean Niyonzima',
                  status: AppStatus.sent,
                  sentOn: 'Sent today',
                  projectIds: ['p-homepage', 'p-semantic'],
                  note: 'I can start full-time on 1 December. My homepage was approved by my mentor and works on a 360 px phone.',
                  statusNote: 'An UpBridge admin checks your evidence matches the listing, then forwards it to Irembo.',
                  timeline: [
                    TimelineEvent('Sent', 'SAT 17 OCT', detail: 'Profile, 2 projects and your note'),
                    TimelineEvent('Checked by UpBridge', 'BY MON 19 OCT', detail: 'An admin confirms your evidence', done: false, current: true),
                    TimelineEvent('Forwarded to Irembo', 'AFTER THE CHECK', done: false),
                    TimelineEvent('Irembo replies', 'BY FRI 20 NOV', done: false),
                  ],
                ),
                ...next.applications,
              ],
      );
    }
    state = next;
  }

  Future<void> signUp({required String name, required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final id = 'youth-${_key(phone)}';
    state = state.copyWith(
      user: AppUser(id: id, name: name.trim(), phone: phone, role: Role.youth, onboarded: false, headline: 'New on UpBridge', location: 'Rwanda'),
      youthId: id,
      tasks: SampleData.freshTasks(),
      reviews: const [],
      projects: const [],
      notifications: const [SampleData.welcomeNotification],
      checkInDone: false,
    );
  }

  void finishOnboarding({required String goal, required List<String> interests}) {
    final u = state.user;
    if (u == null) return;
    final headline = interests.isEmpty ? 'Learning on UpBridge' : 'Learning ${interests.first.toLowerCase()} on UpBridge';
    state = state.copyWith(user: u.copyWith(onboarded: true, headline: headline), goal: goal, interests: interests);
  }

  Future<bool> requestReset(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(resetPhone: phone);
    return true;
  }

  Future<bool> verifyCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return code.length == 6 && code != '000000';
  }

  Future<void> setNewPassword(String password) => Future<void>.delayed(const Duration(milliseconds: 600));

  void logout() => state = state.copyWith(user: null);

  // ───────────────────────────── Youth: learning ─────────────────────────────

  void submitWork(String taskId, {required String live, required String repo, required String note}) {
    final task = state.task(taskId);
    final isResubmission = task.status == TaskStatus.changesRequested;
    _setTask(taskId, TaskStatus.inReview, isResubmission ? 'Resubmitted today · 10:05' : 'Sent today · a mentor replies within 48 h');
    if (isResubmission && state.youthId == 'jean') {
      final youth = state.youthId;
      Timer(const Duration(seconds: 3), () {
        if (state.youthId != youth) return;
        _approve(taskId, SampleData.t3Approval);
        ref.read(bannerProvider.notifier).show(
              const AppBanner(
                title: 'Alice approved your homepage',
                body: 'All 4 criteria met. Add it to your portfolio.',
                route: '/task-feedback/t3',
                icon: Icons.verified_rounded,
              ),
            );
      });
    }
  }

  void _setTask(String id, TaskStatus status, String note) {
    state = state.copyWith(tasks: [for (final t in state.tasks) t.id == id ? t.copyWith(status: status, statusNote: note) : t]);
  }

  void _approve(String taskId, Review review) {
    final tasks = <LearningTask>[];
    var unlockNext = false;
    for (final t in state.tasks) {
      if (t.id == taskId) {
        tasks.add(t.copyWith(status: TaskStatus.approved, statusNote: 'Approved today'));
        unlockNext = true;
      } else if (unlockNext && t.status == TaskStatus.locked) {
        tasks.add(t.copyWith(status: TaskStatus.available, statusNote: 'Ready to start'));
        unlockNext = false;
      } else {
        tasks.add(t);
      }
    }
    final task = state.task(taskId);
    state = state.copyWith(
      tasks: tasks,
      reviews: [review, ...state.reviews],
      notifications: [
        AppNotification(
          id: 'n-approved-$taskId',
          title: '${review.mentorName.split(' ').first} approved your work',
          body: '“${task.title}” met all ${review.results.length} criteria.',
          time: 'NOW',
          icon: Icons.verified_outlined,
          tone: Tone.success,
          route: '/task-feedback/$taskId',
          unread: true,
        ),
        ...state.notifications,
      ],
    );
  }

  /// Creates the portfolio project for an approved task (once) and returns its id.
  String addTaskToPortfolio(String taskId) {
    final existing = state.projectForTask(taskId);
    if (existing != null) return existing.id;
    final task = state.task(taskId);
    final project = taskId == 't3'
        ? SampleData.homepageProject
        : Project(
            id: 'p-$taskId',
            title: task.title,
            summary: task.summary,
            skills: const ['HTML', 'CSS'],
            addedOn: '17 Oct 2026',
            taskId: taskId,
            approvedBy: state.latestReview(taskId)?.mentorName ?? 'Your mentor',
            approvedOn: '17 Oct',
            criteria: 'ALL CRITERIA MET',
          );
    state = state.copyWith(projects: [project, ...state.projects]);
    return project.id;
  }

  // ───────────────────────────── Youth: portfolio & profile ─────────────────────────────

  String addProject({required String title, required String summary, required String link, required List<String> skills}) {
    final id = 'p-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(projects: [
      Project(
        id: id,
        title: title.trim(),
        summary: summary.trim(),
        skills: skills,
        addedOn: '17 Oct 2026',
        liveUrl: link.trim(),
        whatIDid: const [],
        icon: Icons.folder_open_rounded,
        tone: Tone.neutral,
      ),
      ...state.projects,
    ]);
    return id;
  }

  void updateProfile({required String name, required String headline, required String location, required String about}) {
    final u = state.user;
    if (u == null) return;
    state = state.copyWith(user: u.copyWith(name: name.trim(), headline: headline.trim(), location: location.trim(), about: about.trim()));
  }

  void setLanguage(String code) => state = state.copyWith(language: code);

  void markAllRead() => state = state.copyWith(notifications: [for (final n in state.notifications) n.read()]);

  void markRead(String id) => state = state.copyWith(notifications: [for (final n in state.notifications) n.id == id ? n.read() : n]);

  void completeCheckIn() => state = state.copyWith(
        checkInDone: true,
        notifications: [for (final n in state.notifications) n.id == 'n-checkin' ? n.read() : n],
      );

  // ───────────────────────────── Youth: mentorship ─────────────────────────────

  String requestSession({required String mentorId, required SessionSlot slot, required String topic, required String note}) {
    final u = state.user!;
    final m = state.mentor(mentorId);
    final id = 's-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(sessions: [
      Session(
        id: id,
        mentorId: mentorId,
        mentorName: m.name,
        youthId: u.id,
        youthName: u.name,
        day: slot.day,
        time: slot.time,
        topic: topic,
        note: note,
        state: SessionState.requested,
      ),
      ...state.sessions,
    ]);
    return id;
  }

  // ───────────────────────────── Youth: opportunities ─────────────────────────────

  String submitApplication({required String oppId, required List<String> projectIds, required String note}) {
    final u = state.user!;
    final opp = state.opportunity(oppId)!;
    final id = 'app-$oppId';
    final app = Application(
      id: id,
      ref: oppId == 'irembo' ? 'UB-2026-04817' : 'UB-2026-0${4818 + state.applications.length}',
      oppId: oppId,
      youthId: u.id,
      youthName: u.name,
      status: AppStatus.sent,
      sentOn: 'Sent today',
      projectIds: projectIds,
      note: note,
      statusNote: 'An UpBridge admin checks your evidence matches the listing, then forwards it to ${opp.org}.',
      timeline: [
        TimelineEvent('Sent', 'SAT 17 OCT', detail: 'Profile, ${projectIds.length} project${projectIds.length == 1 ? '' : 's'} and your note'),
        const TimelineEvent('Checked by UpBridge', 'BY MON 19 OCT', detail: 'An admin confirms your evidence', done: false, current: true),
        TimelineEvent('Forwarded to ${opp.org}', 'AFTER THE CHECK', done: false),
        TimelineEvent('${opp.org} replies', 'BY ${opp.repliesBy.toUpperCase()}', done: false),
      ],
    );
    final hasForward = state.forwards.any((f) => f.applicationId == id);
    state = state.copyWith(
      applications: [app, ...state.applications.where((a) => a.id != id)],
      opportunities: [for (final o in state.opportunities) o.id == oppId ? o.copyWith(applicants: o.applicants + 1) : o],
      forwards: hasForward
          ? state.forwards
          : [
              ForwardItem(
                id: 'f-${u.id}-$oppId',
                youthName: u.name,
                oppId: oppId,
                sentOn: 'Sent today',
                evidence: '${state.approvedCount} approved tasks · ${projectIds.length} project${projectIds.length == 1 ? '' : 's'} attached',
                applicationId: id,
                checks: oppId == 'irembo' && u.id == 'jean'
                    ? SampleData.forwards.first.checks
                    : [
                        Check('Evidence approved by a mentor', state.approvedCount > 0, '${state.approvedCount} tasks approved'),
                        const Check('Contact details confirmed', true, 'Phone verified at sign-up'),
                      ],
              ),
              ...state.forwards,
            ],
    );
    return id;
  }

  void withdraw(String appId) {
    state = state.copyWith(applications: [
      for (final a in state.applications)
        a.id == appId
            ? a.copyWith(
                status: AppStatus.withdrawn,
                statusNote: 'You withdrew this application on 17 Oct. The employer won’t see it.',
                timeline: [...a.timeline.where((e) => e.done).map((e) => TimelineEvent(e.title, e.date, detail: e.detail)), const TimelineEvent('Withdrawn', 'SAT 17 OCT', detail: 'By you')],
              )
            : a,
    ]);
  }

  // ───────────────────────────── Mentor ─────────────────────────────

  void sendReview(String submissionId, List<CriterionResult> results, String summary) {
    final sub = state.submission(submissionId);
    if (sub == null) return;
    final approved = results.every((r) => r.verdict == Verdict.met);
    state = state.copyWith(
      submissions: [for (final s in state.submissions) s.id == submissionId ? s.copyWith(reviewed: true) : s],
      reviewedCount: state.reviewedCount + 1,
      mentees: [
        for (final m in state.mentees)
          m.id == sub.youthId
              ? Mentee(
                  id: m.id,
                  name: m.name,
                  path: m.path,
                  approved: approved ? m.approved + 1 : m.approved,
                  total: m.total,
                  lastActive: m.lastActive,
                  status: approved ? 'Task ${sub.taskNumber} approved today' : 'Changes requested today',
                  tone: approved ? Tone.success : Tone.warning,
                  district: m.district,
                )
              : m,
      ],
    );
    if (sub.youthId == state.youthId && state.task(sub.taskId).status != TaskStatus.approved) {
      final review = Review(
        id: 'r-${sub.taskId}-${DateTime.now().millisecondsSinceEpoch}',
        taskId: sub.taskId,
        mentorName: state.user?.name ?? 'Your mentor',
        when: 'SAT 17 OCT · 16:40',
        approved: approved,
        summary: summary,
        results: results,
      );
      if (approved) {
        _approve(sub.taskId, review);
      } else {
        _setTask(sub.taskId, TaskStatus.changesRequested, 'Reviewed today');
        state = state.copyWith(reviews: [review, ...state.reviews]);
      }
    }
  }

  void respondToSession(String id, {required bool accept}) {
    state = state.copyWith(sessions: [
      for (final s in state.sessions) s.id == id ? s.copyWith(state: accept ? SessionState.upcoming : SessionState.declined) : s,
    ]);
  }

  // ───────────────────────────── Admin ─────────────────────────────

  void decideApplicant(String id, {required bool approve}) {
    final a = state.applicant(id);
    if (a == null) return;
    state = state.copyWith(
      applicants: [for (final x in state.applicants) x.id == id ? x.copyWith(state: approve ? ApplicantState.approved : ApplicantState.declined) : x],
      platformUsers: approve
          ? [
              ...state.platformUsers,
              PlatformUser(id: 'u-${a.id}', name: a.name, role: Role.mentor, phone: a.phone, district: a.city, joined: 'Verified today', detail: 'New · no mentees yet'),
            ]
          : state.platformUsers,
    );
  }

  void forwardApplication(String id) {
    final f = state.forward(id);
    if (f == null) return;
    final opp = state.opportunity(f.oppId);
    state = state.copyWith(
      forwards: [for (final x in state.forwards) x.id == id ? x.copyWith(forwarded: true) : x],
      applications: [
        for (final a in state.applications)
          a.id == f.applicationId
              ? a.copyWith(
                  status: AppStatus.forwarded,
                  statusNote: '${opp?.org ?? 'The employer'} has your application. They’ve committed to reply by ${opp?.repliesBy ?? 'the reply-by date'}.',
                  timeline: [
                    a.timeline.first,
                    const TimelineEvent('Checked by UpBridge', 'SAT 17 OCT', detail: 'Evidence confirmed'),
                    TimelineEvent('Forwarded to ${opp?.org ?? 'employer'}', 'SAT 17 OCT', current: true),
                    TimelineEvent('${opp?.org ?? 'Employer'} replies', 'BY ${(opp?.repliesBy ?? '').toUpperCase()}', done: false),
                  ],
                )
              : a,
      ],
    );
  }

  void setListingState(String id, ListingState s) {
    state = state.copyWith(opportunities: [for (final o in state.opportunities) o.id == id ? o.copyWith(state: s) : o]);
  }

  void publishListing(Opportunity o) => state = state.copyWith(opportunities: [o, ...state.opportunities]);

  void addUser(PlatformUser u) => state = state.copyWith(platformUsers: [u, ...state.platformUsers]);

  void toggleSetting(String key) {
    final next = Map.of(state.settings);
    next[key] = !(next[key] ?? false);
    state = state.copyWith(settings: next);
  }
}

final appStoreProvider = NotifierProvider<AppStore, AppData>(AppStore.new);

// ───────────────────────────── Opportunity feed (J1 · J1a · J1b) ─────────────────────────────

/// Run with `--dart-define=DEMO_OFFLINE=true` to see the offline state (J1b) on first load.
const demoOffline = bool.fromEnvironment('DEMO_OFFLINE');

class OfflineException implements Exception {
  const OfflineException();
}

int _feedAttempts = 0;

/// Simulates fetching listings over a slow connection.
final feedProvider = FutureProvider<bool>((ref) async {
  _feedAttempts++;
  await Future<void>.delayed(const Duration(milliseconds: 1100));
  if (demoOffline && _feedAttempts == 1) throw const OfflineException();
  return true;
});
