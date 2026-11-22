import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/widgets/buttons.dart';

/// Picks, compresses, uploads (with progress, cancel, retry), and replaces/deletes Cloudinary assets.
class CloudinaryMediaPicker extends ConsumerStatefulWidget {
  const CloudinaryMediaPicker({
    super.key,
    required this.ownerUid,
    required this.label,
    required this.category,
    this.initialAsset,
    this.imagesOnly = true,
    this.helperText,
    required this.onAssetChanged,
  });

  final String ownerUid;
  final String label;
  final String category;
  final MediaAsset? initialAsset;
  final bool imagesOnly;
  final String? helperText;
  final ValueChanged<MediaAsset?> onAssetChanged;

  @override
  ConsumerState<CloudinaryMediaPicker> createState() =>
      _CloudinaryMediaPickerState();
}

class _CloudinaryMediaPickerState extends ConsumerState<CloudinaryMediaPicker> {
  MediaAsset? _asset;
  PickedUploadFile? _pendingRetryFile;
  UploadCancelToken? _cancelToken;
  double _progress = 0;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _asset = widget.initialAsset;
  }

  @override
  void didUpdateWidget(covariant CloudinaryMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAsset?.publicId != widget.initialAsset?.publicId &&
        !_uploading) {
      _asset = widget.initialAsset;
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final service = ref.read(cloudinaryMediaServiceProvider);
    setState(() => _error = null);
    try {
      final picked = widget.imagesOnly
          ? await service.pickImage()
          : await service.pickImageFile();
      if (picked == null || !mounted) return;
      _pendingRetryFile = picked;
      await _startUpload(picked);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _startUpload(PickedUploadFile file) async {
    final service = ref.read(cloudinaryMediaServiceProvider);
    final cancel = UploadCancelToken();
    _cancelToken = cancel;
    setState(() {
      _uploading = true;
      _progress = 0.05;
      _error = null;
    });
    try {
      final uploaded = await service.replaceFile(
        newFile: file,
        ownerUid: widget.ownerUid,
        previousAsset: _asset,
        category: widget.category,
        cancelToken: cancel,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _asset = uploaded;
        _pendingRetryFile = null;
        _uploading = false;
        _progress = 1.0;
      });
      widget.onAssetChanged(uploaded);
    } on UploadCancelledException {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0;
          _error = 'Upload cancelled.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _removeAsset() async {
    final current = _asset;
    setState(() {
      _asset = null;
      _pendingRetryFile = null;
      _error = null;
    });
    widget.onAssetChanged(null);
    if (current != null && current.publicId.isNotEmpty) {
      await ref.read(cloudinaryMediaServiceProvider).tryDeleteAsset(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final asset = _asset;

    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.rLg,
        border: Border.all(
          color: _error != null ? p.dangerText : p.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: AppText.bodySStrong.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Space.s2),
          if (asset != null) ...[
            Row(
              children: [
                if (asset.isImage)
                  ClipRRect(
                    borderRadius: Radii.rMd,
                    child: CachedNetworkImage(
                      imageUrl: asset.url,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(width: 64, height: 64, color: p.sunken),
                      errorWidget: (_, _, _) => Container(
                        width: 64,
                        height: 64,
                        color: p.sunken,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: p.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.infoSubtle,
                      borderRadius: Radii.rMd,
                    ),
                    child: Icon(Icons.description_outlined, color: p.infoText),
                  ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.displayName,
                        style: AppText.bodySStrong.copyWith(
                          color: p.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(asset.size / 1024).ceil()} KB · Uploaded',
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove file',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _uploading ? null : _removeAsset,
                  icon: Icon(Icons.delete_outline_rounded, color: p.dangerText),
                ),
              ],
            ),
            const SizedBox(height: Space.s3),
          ],
          if (_uploading) ...[
            ClipRRect(
              borderRadius: Radii.rSm,
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 6,
                backgroundColor: p.sunken,
                color: p.accent,
              ),
            ),
            const SizedBox(height: Space.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Uploading… ${(_progress * 100).round()}%',
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                ),
                TextLink(
                  'Cancel',
                  color: p.dangerText,
                  onTap: () => _cancelToken?.cancel(),
                ),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                AppButton(
                  asset == null
                      ? (widget.imagesOnly ? 'Choose photo' : 'Choose image')
                      : 'Replace',
                  size: ButtonSize.medium,
                  variant: ButtonVariant.secondary,
                  expand: false,
                  leadingIcon: widget.imagesOnly
                      ? Icons.photo_library_outlined
                      : Icons.image_outlined,
                  onPressed: _pickAndUpload,
                ),
                if (_error != null && _pendingRetryFile != null)
                  AppButton(
                    'Retry upload',
                    size: ButtonSize.medium,
                    variant: ButtonVariant.ghost,
                    expand: false,
                    leadingIcon: Icons.refresh_rounded,
                    onPressed: () => _startUpload(_pendingRetryFile!),
                  ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.s2),
            Text(_error!, style: AppText.caption.copyWith(color: p.dangerText)),
          ] else ...[
            const SizedBox(height: Space.s2),
            Text(
              widget.helperText ?? 'JPG, JPEG, PNG, or WebP image (max 10 MB)',
              style: AppText.caption.copyWith(color: p.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
