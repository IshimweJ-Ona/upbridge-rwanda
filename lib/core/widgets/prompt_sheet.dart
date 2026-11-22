import 'package:flutter/material.dart';
import 'package:upbridge/shared/shared.dart';

/// Opens a modal bottom sheet collecting a single text input and owning its controller lifecycle safely.
Future<String?> showTextPromptSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required String fieldLabel,
  String? hint,
  String initialValue = '',
  required String confirmLabel,
  bool destructive = false,
  int minLength = 0,
  String? minLengthError,
  int maxLines = 3,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TextPromptSheetBody(
      title: title,
      subtitle: subtitle,
      fieldLabel: fieldLabel,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      destructive: destructive,
      minLength: minLength,
      minLengthError: minLengthError,
      maxLines: maxLines,
    ),
  );
}

class _TextPromptSheetBody extends StatefulWidget {
  const _TextPromptSheetBody({
    required this.title,
    this.subtitle,
    required this.fieldLabel,
    this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.destructive,
    required this.minLength,
    this.minLengthError,
    required this.maxLines,
  });

  final String title;
  final String? subtitle;
  final String fieldLabel;
  final String? hint;
  final String initialValue;
  final String confirmLabel;
  final bool destructive;
  final int minLength;
  final String? minLengthError;
  final int maxLines;

  @override
  State<_TextPromptSheetBody> createState() => _TextPromptSheetBodyState();
}

class _TextPromptSheetBodyState extends State<_TextPromptSheetBody> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _ctrl.text.trim();
    if (widget.minLength > 0 && value.length < widget.minLength) {
      setState(
        () => _error =
            widget.minLengthError ??
            'Enter at least ${widget.minLength} characters.',
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        20,
        Space.gutter,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppText.titleM),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.subtitle!,
              style: AppText.bodyS.copyWith(color: p.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          AppTextField(
            label: widget.fieldLabel,
            hint: widget.hint,
            controller: _ctrl,
            maxLines: widget.maxLines,
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            widget.confirmLabel,
            variant: widget.destructive
                ? ButtonVariant.danger
                : ButtonVariant.primary,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
