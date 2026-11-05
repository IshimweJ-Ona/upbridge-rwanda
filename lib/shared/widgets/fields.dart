// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

/// Labelled input with helper text, error state and an animated focus border.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.prefixText,
    this.suffixIcon,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    this.trailingNote,
    this.inputFormatters,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? helper;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final IconData? suffixIcon;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? trailingNote;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  final FocusNode _focus = FocusNode();
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final borderColor = hasError
        ? AppColors.dangerText
        : _focus.hasFocus
            ? AppColors.focus
            : AppColors.borderStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: AppText.bodySStrong)),
            if (widget.trailingNote != null) Text(widget.trailingNote!, style: AppText.caption),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          decoration: BoxDecoration(
            color: widget.readOnly ? AppColors.canvas : AppColors.surface,
            borderRadius: Radii.rMd,
            border: Border.all(color: borderColor, width: (_focus.hasFocus || hasError) ? 1.6 : 1),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            obscureText: _hidden,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            minLines: widget.minLines,
            onChanged: widget.onChanged,
            textInputAction: widget.textInputAction,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            autofocus: widget.autofocus,
            inputFormatters: widget.inputFormatters,
            style: AppText.bodyM.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: AppText.bodyM.copyWith(color: AppColors.textMuted),
              prefixText: widget.prefixText,
              prefixStyle: AppText.bodyM.copyWith(color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: AnimatedSwitcher(
                        duration: Motion.fast,
                        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                        child: Icon(
                          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          key: ValueKey(_hidden),
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : widget.suffixIcon == null
                      ? null
                      : Icon(widget.suffixIcon, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.error_outline_rounded, size: 15, color: AppColors.dangerText),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(widget.error!, style: AppText.caption.copyWith(color: AppColors.dangerText))),
                    ],
                  ),
                )
              : widget.helper == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(widget.helper!, style: AppText.caption),
                    ),
        ),
      ],
    );
  }
}

/// Six boxes for the SMS code; moves focus forward and back automatically.
class OtpField extends StatefulWidget {
  const OtpField({super.key, this.length = 6, this.initial = '', this.onChanged, this.hasError = false});

  final int length;
  final String initial;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final List<TextEditingController> _c = List.generate(
    widget.length,
    (i) => TextEditingController(text: i < widget.initial.length ? widget.initial[i] : ''),
  );
  late final List<FocusNode> _f = List.generate(widget.length, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (final f in _f) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  String get value => _c.map((c) => c.text).join();

  void _changed(int i, String v) {
    if (v.length == 2) {
      _c[i].text = v.substring(1);
      _c[i].selection = const TextSelection.collapsed(offset: 1);
      if (i < widget.length - 1) _f[i + 1].requestFocus();
    } else if (v.length > 2) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < widget.length; k++) {
        _c[k].text = k < digits.length ? digits[k] : '';
      }
      _f[(digits.length).clamp(0, widget.length - 1)].requestFocus();
    } else if (v.isNotEmpty && i < widget.length - 1) {
      _f[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _f[i - 1].requestFocus();
    }
    widget.onChanged?.call(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.fast,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: Radii.rMd,
                border: Border.all(
                  color: widget.hasError
                      ? AppColors.dangerText
                      : _f[i].hasFocus
                          ? AppColors.focus
                          : AppColors.borderStrong,
                  width: _f[i].hasFocus ? 1.6 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _c[i],
                focusNode: _f[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppText.dataMonoL,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(border: InputBorder.none, counterText: '', isDense: true),
                onChanged: (v) => _changed(i, v),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Checkbox with a label; the box fills and the tick pops in.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.label, required this.value, required this.onChanged, this.error, this.subtitle});

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onTap: () => onChanged(!value),
          scale: 0.99,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: Motion.fast,
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: value ? AppColors.actionPrimary : AppColors.surface,
                  borderRadius: Radii.rSm,
                  border: Border.all(color: error != null ? AppColors.dangerText : (value ? AppColors.actionPrimary : AppColors.borderStrong), width: 1.4),
                ),
                child: AnimatedScale(
                  scale: value ? 1 : 0,
                  duration: Motion.base,
                  curve: Motion.emphasized,
                  child: const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.bodyS.copyWith(color: AppColors.textPrimary)),
                    if (subtitle != null) Text(subtitle!, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 34),
            child: Text(error!, style: AppText.caption.copyWith(color: AppColors.dangerText)),
          ),
      ],
    );
  }
}

/// Toggle switch drawn to match the design (navy when on).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.actionPrimary : AppColors.borderSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x2213294B), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
