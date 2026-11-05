// Owner: Student 5 · Core, shared, app shell, home & admin
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/widgets/buttons.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

// ───────────────────────────── Toast ─────────────────────────────

_ActiveToast? _activeToast;

class _ActiveToast {
  _ActiveToast(this.entry);
  final OverlayEntry entry;
  bool removed = false;

  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }
}

/// Short confirmation that slides up above the tab bar and leaves on its own.
void showToast(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded, Tone tone = Tone.success}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _activeToast?.remove();
  late final _ActiveToast handle;
  final entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      icon: icon,
      tone: tone,
      onDone: () {
        handle.remove();
        if (identical(_activeToast, handle)) _activeToast = null;
      },
    ),
  );
  handle = _ActiveToast(entry);
  _activeToast = handle;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.icon, required this.tone, required this.onDone});

  final String message;
  final IconData icon;
  final Tone tone;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.base, reverseDuration: Motion.fast);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.emphasized, reverseCurve: Motion.exit);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2400), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 84;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, child) => Opacity(
              opacity: _t.value.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, 24 * (1 - _t.value)), child: child),
            ),
            child: Material(
              color: AppColors.inverse,
              borderRadius: Radii.rLg,
              elevation: 6,
              shadowColor: const Color(0x4013294B),
              child: InkWell(
                borderRadius: Radii.rLg,
                onTap: _dismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 20, color: widget.tone == Tone.success ? const Color(0xFF7FD3A7) : AppColors.brandOrange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(widget.message, style: AppText.bodySStrong.copyWith(color: AppColors.textInverse))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Dialog ─────────────────────────────

/// Confirmation dialog with a 48 % navy scrim and a fade-scale entrance.
/// Resolves to `true` only when the confirm button is pressed.
Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: AppColors.scrim,
    transitionDuration: Motion.base,
    pageBuilder: (ctx, _, _) => _AppDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      icon: icon,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeScaleTransition(animation: anim, child: child),
  );
  return result ?? false;
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({required this.title, this.body, required this.confirmLabel, required this.cancelLabel, required this.destructive, this.icon});

  final String title;
  final String? body;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: AppColors.surface,
              borderRadius: Radii.rXl,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      IconTile(icon!, tone: destructive ? Tone.danger : Tone.info, size: 40),
                      const SizedBox(height: 14),
                    ],
                    Text(title, style: AppText.titleM),
                    if (body != null) ...[const SizedBox(height: 8), Text(body!, style: AppText.bodyM)],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            cancelLabel,
                            variant: ButtonVariant.secondary,
                            size: ButtonSize.medium,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            confirmLabel,
                            variant: destructive ? ButtonVariant.danger : ButtonVariant.primary,
                            size: ButtonSize.medium,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded bottom sheet with a drag handle.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.titleM),
            const SizedBox(height: 14),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

// ───────────────────────────── In-app banner ─────────────────────────────

class AppBanner {
  const AppBanner({required this.title, required this.body, required this.route, this.icon = Icons.notifications_active_rounded});

  final String title;
  final String body;
  final String route;
  final IconData icon;
}

class BannerController extends Notifier<AppBanner?> {
  Timer? _timer;

  @override
  AppBanner? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(AppBanner banner) {
    _timer?.cancel();
    state = banner;
    _timer = Timer(const Duration(seconds: 7), hide);
  }

  void hide() {
    _timer?.cancel();
    state = null;
  }
}

final bannerProvider = NotifierProvider<BannerController, AppBanner?>(BannerController.new);

/// Sits above the router and drops a notification banner in from the top
/// (the Alice-approved message that appears 3 s after a resubmission).
class BannerHost extends ConsumerWidget {
  const BannerHost({super.key, required this.child, required this.onOpen});

  final Widget child;
  final void Function(String route) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(bannerProvider);
    final top = MediaQuery.paddingOf(context).top + 8;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 12,
          right: 12,
          top: top,
          child: AnimatedSwitcher(
            duration: Motion.slow,
            reverseDuration: Motion.base,
            switchInCurve: Motion.emphasized,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: banner == null
                ? const SizedBox.shrink(key: ValueKey('none'))
                : Center(
                    key: ValueKey(banner.title),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Dismissible(
                        key: ValueKey('d-${banner.title}'),
                        direction: DismissDirection.up,
                        onDismissed: (_) => ref.read(bannerProvider.notifier).hide(),
                        child: Pressable(
                          onTap: () {
                            ref.read(bannerProvider.notifier).hide();
                            onOpen(banner.route);
                          },
                          child: Material(
                            color: AppColors.inverse,
                            borderRadius: Radii.rLg,
                            elevation: 10,
                            shadowColor: const Color(0x5513294B),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(color: AppColors.brandOrange.withValues(alpha: 0.18), borderRadius: Radii.rMd),
                                    child: Icon(banner.icon, size: 20, color: AppColors.brandOrange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('UPBRIDGE · NOW', style: AppText.labelMono.copyWith(color: const Color(0xB3FFFFFF))),
                                        const SizedBox(height: 4),
                                        Text(banner.title, style: AppText.bodySStrong.copyWith(color: AppColors.textInverse)),
                                        const SizedBox(height: 2),
                                        Text(banner.body, style: AppText.bodyS.copyWith(color: const Color(0xD9FFFFFF))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xB3FFFFFF)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
