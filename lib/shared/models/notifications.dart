part of 'models.dart';

// ───────────────────────────── Notifications ─────────────────────────────

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.tone,
    this.route,
    this.unread = false,
    this.today = true,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Tone tone;
  final String? route;
  final bool unread;
  final bool today;

  AppNotification read() => AppNotification(
    id: id,
    title: title,
    body: body,
    time: time,
    icon: icon,
    tone: tone,
    route: route,
    today: today,
  );
}
