// Lets a user choose or remove a local image; uploading is a separate service concern.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:upbridge/core/constants/app_copy.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';

class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    this.label = 'Profile photo',
    this.initialImageUrl,
    this.onChanged,
    this.maxWidth = 320,
  });

  final String label;
  final String? initialImageUrl;
  final ValueChanged<XFile?>? onChanged;
  final double maxWidth;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final _picker = ImagePicker();
  XFile? _picked;
  Future<Uint8List>? _pickedBytes;
  bool _removedInitialImage = false;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted) {
        return;
      }
      if (image != null) {
        setState(() {
          _picked = image;
          _pickedBytes = image.readAsBytes();
          _removedInitialImage = false;
        });
        widget.onChanged?.call(image);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The photo could not be opened. Choose another image.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _remove() {
    setState(() {
      _picked = null;
      _pickedBytes = null;
      _removedInitialImage = true;
      _error = null;
    });
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final initialImageUrl =
        _removedInitialImage ? null : widget.initialImageUrl;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AppText.bodySStrong),
          const SizedBox(height: 8),
          Row(
            children: [
              _Preview(
                imageBytes: _pickedBytes,
                url: initialImageUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        picked == null && initialImageUrl == null
                            ? 'Choose photo'
                            : 'Change photo',
                      ),
                    ),
                    if (picked != null || initialImageUrl != null)
                      TextButton.icon(
                        onPressed: _remove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove photo'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: AppText.caption.copyWith(color: AppColors.dangerText),
            ),
          ],
          const SizedBox(height: 4),
          Text(AppCopy.imageSizeHint, style: AppText.caption),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.imageBytes, required this.url});

  final Future<Uint8List>? imageBytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageBytes = this.imageBytes;
    final Widget child;
    if (imageBytes != null) {
      child = FutureBuilder<Uint8List>(
        future: imageBytes,
        builder: (context, snapshot) => snapshot.hasData
            ? Image.memory(snapshot.data!, fit: BoxFit.cover)
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (url != null && url!.isNotEmpty) {
      child = Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      );
    } else {
      child = const Icon(
        Icons.person_outline_rounded,
        color: AppColors.textMuted,
        size: 28,
      );
    }
    return ClipRRect(
      borderRadius: Radii.rMd,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        color: AppColors.sunken,
        child: child,
      ),
    );
  }
}
