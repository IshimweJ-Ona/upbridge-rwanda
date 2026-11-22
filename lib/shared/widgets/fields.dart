import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/animations/pressable.dart';

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
  late TextEditingController _controller;
  bool _ownsController = false;
  final FocusNode _focus = FocusNode();
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _setController(widget);
    _focus.addListener(() => setState(() {}));
  }

  void _setController(AppTextField field) {
    if (field.controller != null) {
      _controller = field.controller!;
      _ownsController = false;
    } else {
      _controller = TextEditingController(text: field.initialValue);
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _setController(widget);
    }
    if (oldWidget.obscure != widget.obscure) {
      _hidden = widget.obscure;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasError = widget.error != null;
    final borderColor = hasError
        ? p.dangerText
        : _focus.hasFocus
        ? p.focus
        : p.borderStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: AppText.bodySStrong.copyWith(color: p.textPrimary),
                ),
              ),
              if (widget.trailingNote != null)
                Text(
                  widget.trailingNote!,
                  style: AppText.caption.copyWith(color: p.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: Motion.durationFor(context, Motion.fast),
          curve: Motion.curve,
          decoration: BoxDecoration(
            color: widget.readOnly ? p.sunken : p.surface,
            borderRadius: Radii.rMd,
            border: Border.all(
              color: borderColor,
              width: (_focus.hasFocus || hasError) ? 1.5 : 1,
            ),
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
            style: AppText.bodyM.copyWith(color: p.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: AppText.bodyM.copyWith(color: p.textMuted),
              prefixText: widget.prefixText,
              prefixStyle: AppText.bodyM.copyWith(color: p.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: p.textSecondary,
                      ),
                    )
                  : widget.suffixIcon == null
                  ? null
                  : Icon(widget.suffixIcon, size: 20, color: p.textSecondary),
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.durationFor(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 15,
                          color: p.dangerText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.error!,
                          style: AppText.caption.copyWith(color: p.dangerText),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.helper == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.helper!,
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                ),
        ),
      ],
    );
  }
}

class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onTap: () => onChanged(!value),
          scale: 0.99,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: Motion.durationFor(context, Motion.fast),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? p.actionPrimary : p.surface,
                    borderRadius: Radii.rSm,
                    border: Border.all(
                      color: error != null
                          ? p.dangerText
                          : (value ? p.actionPrimary : p.borderStrong),
                      width: 1.4,
                    ),
                  ),
                  child: value
                      ? Icon(Icons.check_rounded, size: 16, color: p.onPrimary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.bodyS.copyWith(color: p.textPrimary),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppText.caption.copyWith(color: p.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 34),
            child: Text(
              error!,
              style: AppText.caption.copyWith(color: p.dangerText),
            ),
          ),
      ],
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Motion.durationFor(context, Motion.base),
          curve: Motion.curve,
          width: 48,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? p.actionPrimary : p.borderSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: Motion.durationFor(context, Motion.base),
            curve: Motion.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact search input with optional clear button and consistent 44px height.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: Motion.durationFor(context, Motion.fast),
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.rMd,
        border: Border.all(
          color: _focus.hasFocus ? p.focus : p.borderSubtle,
          width: _focus.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: AppText.bodyM.copyWith(color: p.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: AppText.bodyS.copyWith(color: p.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: _focus.hasFocus ? p.focus : p.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close_rounded, size: 18, color: p.textMuted),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}
