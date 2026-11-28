import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../services/campaign_media_service.dart';

class CampaignManagementScreen extends StatefulWidget {
  const CampaignManagementScreen({this.repository, super.key});

  final CampaignMediaRepository? repository;

  @override
  State<CampaignManagementScreen> createState() =>
      _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends State<CampaignManagementScreen> {
  late final CampaignMediaRepository _repository =
      widget.repository ?? CampaignMediaService.instance;
  final _picker = ImagePicker();
  CampaignMediaCollection? _collection;
  String? _error;
  var _loading = true;
  var _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final collection = await _repository.load();
      if (!mounted) return;
      setState(() {
        _collection = collection;
        _loading = false;
      });
    } on CampaignMediaException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error.code);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Campaign media could not be loaded. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload({required bool logo}) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 88,
      );
    } catch (_) {
      if (mounted) _notify('The photo picker could not be opened.');
      return;
    }
    if (file == null || !mounted) return;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (mounted) _notify('The selected image could not be read.');
      return;
    }
    if (!mounted) return;
    final contentType = _imageContentType(bytes);
    if (contentType == null) {
      _notify('Choose a JPG, PNG, or WebP image.');
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      _notify('Images must be 5 MB or smaller.');
      return;
    }

    setState(() => _uploading = true);
    try {
      if (logo) {
        await _repository.uploadLogo(bytes, contentType);
      } else {
        await _repository.uploadPhoto(bytes, contentType);
      }
      if (!mounted) return;
      await _load();
    } on CampaignMediaException catch (error) {
      if (mounted) _notify(_messageFor(error.code));
    } catch (_) {
      if (mounted) {
        _notify('The image could not be uploaded. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteLogo() async {
    final confirmed = await _confirmDelete('Remove this campaign logo?');
    if (!confirmed) return;
    await _runDelete(_repository.deleteLogo);
  }

  Future<void> _deletePhoto(CampaignMediaItem photo) async {
    final confirmed = await _confirmDelete('Remove this campaign photo?');
    if (!confirmed) return;
    await _runDelete(() => _repository.deletePhoto(photo.id));
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove media?'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _runDelete(Future<void> Function() action) async {
    setState(() => _uploading = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
    } on CampaignMediaException catch (error) {
      if (mounted) _notify(_messageFor(error.code));
    } catch (_) {
      if (mounted) _notify('The media could not be removed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final collection = _collection;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Campaign Management'),
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('campaign-refresh'),
            tooltip: 'Refresh campaign media',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child:
            _loading && collection == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null && collection == null
                ? _LoadError(message: _error!, onRetry: _load)
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    key: const Key('campaign-management-content'),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      _IntroCard(
                        onColor: palette.text,
                        mutedColor: palette.textMuted,
                        accentColor: palette.accent,
                      ),
                      const SizedBox(height: 18),
                      _SectionHeading(
                        title: 'Campaign identity',
                        subtitle:
                            'Keep your campaign branding consistent across your materials.',
                      ),
                      const SizedBox(height: 10),
                      _LogoCard(
                        logo: collection?.logo,
                        busy: _uploading,
                        onUpload: () => _pickAndUpload(logo: true),
                        onDelete: collection?.logo == null ? null : _deleteLogo,
                      ),
                      const SizedBox(height: 22),
                      _SectionHeading(
                        title: 'Campaign photos',
                        subtitle:
                            '${collection?.photos.length ?? 0} of ${CampaignMediaService.maxPhotos} photos',
                      ),
                      const SizedBox(height: 10),
                      if (collection == null || collection.photos.isEmpty)
                        _EmptyPhotosCard(
                          busy: _uploading,
                          onAdd: () => _pickAndUpload(logo: false),
                        )
                      else ...[
                        _PhotoGrid(
                          photos: collection.photos,
                          busy: _uploading,
                          onDelete: _deletePhoto,
                        ),
                        if (collection.photos.length <
                            CampaignMediaService.maxPhotos) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('campaign-add-photo'),
                            onPressed:
                                _uploading
                                    ? null
                                    : () => _pickAndUpload(logo: false),
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: const Text('Add photo'),
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: palette.danger)),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }
}

String? _imageContentType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

String _messageFor(String code) {
  return switch (code) {
    'unauthorized' => 'Sign in to manage campaign media.',
    'storage_not_ready' => 'Campaign media storage is not available yet.',
    'too_many_photos' => 'You have reached the 10-photo limit.',
    'invalid_photo' => 'Choose a JPG, PNG, or WebP image.',
    'file_too_large' => 'Images must be 5 MB or smaller.',
    'unreachable' => 'The campaign media service could not be reached.',
    _ => 'Campaign media could not be updated. Please try again.',
  };
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.onColor,
    required this.mutedColor,
    required this.accentColor,
  });

  final Color onColor;
  final Color mutedColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: accentColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your campaign workspace',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage the logo and photos saved to your campaign media library.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.logo,
    required this.busy,
    required this.onUpload,
    required this.onDelete,
  });

  final CampaignMediaItem? logo;
  final bool busy;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                logo == null
                    ? Icon(
                      Icons.image_outlined,
                      color: palette.textMuted,
                      size: 30,
                    )
                    : Image.network(
                      logo!.url,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.broken_image_outlined,
                            color: palette.textMuted,
                          ),
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logo == null ? 'Campaign logo' : 'Saved campaign logo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton.tonal(
                      key: const Key('campaign-upload-logo'),
                      onPressed: busy ? null : onUpload,
                      child: Text(logo == null ? 'Upload logo' : 'Replace'),
                    ),
                    if (onDelete != null)
                      TextButton(
                        onPressed: busy ? null : onDelete,
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotosCard extends StatelessWidget {
  const _EmptyPhotosCard({required this.busy, required this.onAdd});

  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 32,
            color: palette.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'No campaign photos yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add photos to keep your campaign media together.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('campaign-add-photo'),
            onPressed: busy ? null : onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add photos'),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.busy,
    required this.onDelete,
  });

  final List<CampaignMediaItem> photos;
  final bool busy;
  final ValueChanged<CampaignMediaItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GridView.builder(
      key: const Key('campaign-photo-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 172,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photo.url,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => ColoredBox(
                      color: palette.surfaceSecondary,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: palette.textMuted,
                      ),
                    ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  key: Key('campaign-delete-photo-${photo.id}'),
                  tooltip: 'Remove photo',
                  onPressed: busy ? null : () => onDelete(photo),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: palette.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
