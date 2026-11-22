import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/animations/reveal.dart';
import 'package:upbridge/shared/widgets/buttons.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

void goBack(BuildContext context, {String fallback = '/'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMax,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class FooterBar extends StatelessWidget {
  const FooterBar({super.key, required this.children, this.note});

  final List<Widget> children;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            12,
            Space.gutter,
            12,
          ),
          child: ConstrainedContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (note != null) ...[note!, const SizedBox(height: 10)],
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PageFrame extends StatefulWidget {
  const PageFrame({
    super.key,
    required this.children,
    this.title,
    this.largeTitle,
    this.eyebrow,
    this.subtitle,
    this.intro,
    this.footer,
    this.footerNote,
    this.actions = const [],
    this.showBack = false,
    this.closeIcon = false,
    this.onBack,
    this.backFallback = '/',
    this.onRefresh,
    this.pinned,
    this.padding = const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 28),
    this.stagger = false,
    this.background,
    this.controller,
  });

  final List<Widget> children;
  final String? title;
  final String? largeTitle;
  final String? eyebrow;
  final String? subtitle;
  final Widget? intro;
  final List<Widget>? footer;
  final Widget? footerNote;
  final List<Widget> actions;
  final bool showBack;
  final bool closeIcon;
  final VoidCallback? onBack;
  final String backFallback;
  final Future<void> Function()? onRefresh;
  final Widget? pinned;
  final EdgeInsets padding;
  final bool stagger;
  final Color? background;
  final ScrollController? controller;

  @override
  State<PageFrame> createState() => _PageFrameState();
}

class _PageFrameState extends State<PageFrame> {
  late final ScrollController _sc = widget.controller ?? ScrollController();
  bool _scrolled = false;
  bool _pastTitle = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || !_sc.hasClients) return;
    final o = _sc.offset;
    final scrolled = o > 2;
    final past = o > (widget.eyebrow == null ? 30 : 46);
    if (scrolled != _scrolled || past != _pastTitle) {
      setState(() {
        _scrolled = scrolled;
        _pastTitle = past;
      });
    }
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    if (widget.controller == null) _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = widget;
    final hasLarge = w.largeTitle != null;
    final bottomInset = w.footer == null
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    final content = <Widget>[
      if (w.eyebrow != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: MonoLabel(w.eyebrow!),
        ),
      if (hasLarge)
        Text(
          w.largeTitle!,
          style: AppText.display.copyWith(color: p.textPrimary),
        ),
      if (w.subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            w.subtitle!,
            style: AppText.bodyS.copyWith(color: p.textSecondary),
          ),
        ),
      if (w.intro != null) w.intro!,
      ...w.children,
    ];

    Widget scroll = SingleChildScrollView(
      controller: _sc,
      padding: w.padding.copyWith(bottom: w.padding.bottom + bottomInset),
      child: ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: w.stagger ? staggered(content) : content,
        ),
      ),
    );

    if (w.onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: w.onRefresh!,
        color: p.accent,
        backgroundColor: p.surface,
        displacement: 24,
        child: scroll,
      );
    }

    return Scaffold(
      backgroundColor: w.background ?? p.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              title: w.largeTitle ?? w.title,
              titleVisible: !hasLarge || _pastTitle,
              divider: _scrolled && w.pinned == null,
              leading: w.showBack
                  ? CircleIconButton(
                      icon: w.closeIcon
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      tooltip: w.closeIcon ? 'Close' : 'Back',
                      onTap:
                          w.onBack ??
                          () => goBack(context, fallback: w.backFallback),
                    )
                  : null,
              actions: w.actions,
            ),
            if (w.pinned != null) w.pinned!,
            Expanded(child: scroll),
            if (w.footer != null)
              FooterBar(note: w.footerNote, children: w.footer!),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    this.title,
    required this.titleVisible,
    required this.divider,
    this.leading,
    this.actions = const [],
  });

  final String? title;
  final bool titleVisible;
  final bool divider;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dur = Motion.durationFor(context, Motion.fast);
    return AnimatedContainer(
      duration: dur,
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: divider
                ? p.borderSubtle
                : p.borderSubtle.withValues(alpha: 0),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: leading == null ? Space.gutter : 6,
        right: 6,
      ),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 2),
          Expanded(
            child: AnimatedOpacity(
              opacity: titleVisible && title != null ? 1 : 0,
              duration: dur,
              child: Text(
                title ?? '',
                style: AppText.titleS.copyWith(color: p.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.footerNote,
    this.actions = const [],
    this.closeIcon = false,
    this.backFallback = '/',
    this.onBack,
    this.pinned,
    this.largeTitle,
    this.eyebrow,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? footer;
  final Widget? footerNote;
  final List<Widget> actions;
  final bool closeIcon;
  final String backFallback;
  final VoidCallback? onBack;
  final Widget? pinned;
  final String? largeTitle;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: title,
    largeTitle: largeTitle,
    eyebrow: eyebrow,
    showBack: true,
    closeIcon: closeIcon,
    backFallback: backFallback,
    onBack: onBack,
    footer: footer,
    footerNote: footerNote,
    actions: actions,
    pinned: pinned,
    children: children,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.body,
    this.bottom = 20,
  });

  final String title;
  final String? eyebrow;
  final String? body;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            MonoLabel(eyebrow!),
            const SizedBox(height: 8),
          ],
          Text(title, style: AppText.titleL.copyWith(color: p.textPrimary)),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, style: AppText.bodyM.copyWith(color: p.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.durationFor(context, Motion.base),
              curve: Motion.curve,
              height: 4,
              decoration: BoxDecoration(
                color: i <= index ? p.accent : p.borderSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
