import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_actions.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../models/website_draft.dart';
import '../services/campaign_media_service.dart';
import '../widgets/website_language_field.dart';

class WebsiteQuestionsScreen extends StatefulWidget {
  const WebsiteQuestionsScreen({super.key});

  @override
  State<WebsiteQuestionsScreen> createState() => _WebsiteQuestionsScreenState();
}

class _WebsiteQuestionsScreenState extends State<WebsiteQuestionsScreen> {
  var _page = 0;
  var _ready = false;
  var _mediaBusy = false;
  List<TextEditingController> _controllers = [];
  List<_QuestionPage> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final website = OnboardingScope.of(context).website;
    _pages = _questionPages(website);
    _controllers = [
      for (final page in _pages)
        for (final field in page.fields) TextEditingController(text: field.read()),
    ];
    _ready = true;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int _controllerIndex(_QuestionPage page, int fieldIndex) {
    var index = 0;
    for (final item in _pages) {
      if (identical(item, page)) {
        return index + fieldIndex;
      }
      index += item.fields.length;
    }
    return 0;
  }

  void _writePage(_QuestionPage page) {
    for (var i = 0; i < page.fields.length; i++) {
      page.fields[i].write(_controllers[_controllerIndex(page, i)].text.trim());
    }
  }

  bool _guardNavigation() {
    if (!_mediaBusy) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).line('mediaWaitForUpload'))),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final website = OnboardingScope.of(context).website;
    final page = _pages[_page];
    final last = _page == _pages.length - 1;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line(page.titleKey),
              description: l10n.line('questionsBody'),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.line('questionProgress').replaceAll('{step}', '${_page + 1}').replaceAll('{total}', '${_pages.length}'),
              style: AppTextStyles.principle(context),
            ),
            const SizedBox(height: 16),
            if (page.media)
              _MediaSection(
                website: website,
                onBusyChanged: (busy) {
                  if (!mounted || _mediaBusy == busy) return;
                  setState(() => _mediaBusy = busy);
                },
              )
            else
              for (var i = 0; i < page.fields.length; i++) ...[
                WebsiteAnswerField(
                  label: l10n.line(page.fields[i].labelKey),
                  optional: l10n.optionalLabel,
                  maxLines: page.fields[i].maxLines,
                  controller: _controllers[_controllerIndex(page, i)],
                ),
                const SizedBox(height: 12),
              ],
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () {
                if (!_guardNavigation()) return;
                _writePage(page);
                if (_page == 0) {
                  AppRouter.back(context, AppRoutes.websiteInfo);
                  return;
                }
                setState(() => _page -= 1);
              },
              primaryLabel: last ? l10n.line('continueAction') : l10n.next,
              onPrimary: () {
                if (!_guardNavigation()) return;
                _writePage(page);
                if (last) {
                  AppRouter.open(context, AppRoutes.websiteSections);
                  return;
                }
                setState(() => _page += 1);
              },
              skipLabel: l10n.line('skipThisField'),
              onSkip: () {
                if (!_guardNavigation()) return;
                _writePage(page);
                if (last) {
                  AppRouter.open(context, AppRoutes.websiteSections);
                  return;
                }
                setState(() => _page += 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage {
  const _QuestionPage(this.titleKey, this.fields, {this.media = false});

  final String titleKey;
  final List<_Field> fields;
  final bool media;
}

class _Field {
  const _Field(this.labelKey, this.read, this.write, {this.maxLines = 1});

  final String labelKey;
  final String Function() read;
  final void Function(String value) write;
  final int maxLines;
}

List<_QuestionPage> _questionPages(WebsiteDraft website) {
  return [
    _QuestionPage('qPageIdentity', [
      _Field('qFullName', () => website.fullName, (value) => website.fullName = value),
      _Field('qTitle', () => website.publicTitle, (value) => website.publicTitle = value),
      _Field('qOrganization', () => website.organization, (value) => website.organization = value),
    ]),
    _QuestionPage('qPageStory', [
      _Field('qIntro', () => website.introduction, (value) => website.introduction = value, maxLines: 3),
      _Field('qAbout', () => website.about, (value) => website.about = value, maxLines: 4),
      _Field('qVision', () => website.vision, (value) => website.vision = value, maxLines: 3),
      _Field('qMission', () => website.mission, (value) => website.mission = value, maxLines: 3),
    ]),
    _QuestionPage('qPageWork', [
      _Field('qWork', () => website.achievements, (value) => website.achievements = value, maxLines: 4),
      _Field('qPriorities', () => website.priorities, (value) => website.priorities = value, maxLines: 3),
      _Field('qCta', () => website.callToAction, (value) => website.callToAction = value, maxLines: 2),
    ]),
    _QuestionPage('qPageContact', [
      _Field('qContact', () => website.publicContact, (value) => website.publicContact = value, maxLines: 2),
      _Field('qAddress', () => website.address, (value) => website.address = value, maxLines: 2),
      _Field('qPhone', () => website.phone, (value) => website.phone = value),
      _Field('qEmail', () => website.email, (value) => website.email = value),
      _Field('qSocial', () => website.socialLinks, (value) => website.socialLinks = value, maxLines: 2),
      _Field('qLinks', () => website.publicLinks, (value) => website.publicLinks = value, maxLines: 2),
    ]),
    const _QuestionPage('qPageMedia', [], media: true),
  ];
}

class _MediaSection extends StatefulWidget {
  const _MediaSection({required this.website, required this.onBusyChanged});

  final WebsiteDraft website;
  final ValueChanged<bool> onBusyChanged;

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  final _picker = ImagePicker();
  var _epoch = 0;
  var _loading = AuthService.instance.session != null;
  var _busy = false;
  var _logoUploading = false;
  var _photoDone = 0;
  var _photoTotal = 0;
  String? _deletingId;
  List<Uint8List> _pendingPhotos = const [];

  WebsiteDraft get website => widget.website;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrate());
    });
  }

  Future<void> _hydrate() async {
    final epoch = _epoch;
    try {
      final snapshot = await CampaignMediaService.instance.fetch();
      if (!mounted || epoch != _epoch || snapshot == null) return;
      website.applyStoredMedia(
        userId: snapshot.userId,
        logoId: snapshot.logo?.id,
        logoUrl: snapshot.logo?.url,
        logoUserId: snapshot.logo?.userId,
        photos: [
          for (final photo in snapshot.photos)
            CampaignPhoto(id: photo.id, url: photo.url, userId: photo.userId),
        ],
      );
      if (mounted) setState(() {});
      await _downloadMissing(epoch);
    } on CampaignMediaException catch (error) {
      if (!mounted || epoch != _epoch) return;
      if (error.code != 'unauthorized') _show(_message(error, loading: true));
    } catch (_) {
      if (!mounted || epoch != _epoch) return;
      _show(AppLocalizations.of(context).line('mediaLoadFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadMissing(int epoch) async {
    if (website.logoUrl.isNotEmpty && website.logo == null) {
      final bytes = await CampaignMediaService.instance.download(website.logoUrl);
      if (!mounted || epoch != _epoch) return;
      if (bytes != null) setState(() => website.logo = bytes);
    }
    for (final photo in List<CampaignPhoto>.of(website.campaignPhotos)) {
      if (photo.bytes != null) continue;
      final bytes = await CampaignMediaService.instance.download(photo.url);
      if (!mounted || epoch != _epoch) return;
      if (bytes == null) continue;
      setState(() {
        photo.bytes = bytes;
        website.ownsGallery = true;
        website.syncGalleryBytes();
      });
    }
  }

  Future<void> _uploadLogo() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
    } catch (_) {
      if (mounted) _show(l10n.photoError);
      return;
    }
    if (file == null || !mounted) return;
    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (mounted) _show(l10n.photoError);
      return;
    }
    final problem = CampaignMediaService.validateBytes(bytes, filename: file.name);
    if (problem != null) {
      _show(_message(CampaignMediaException(problem)));
      return;
    }

    final previousBytes = website.logo;
    final previousId = website.logoId;
    final previousUrl = website.logoUrl;
    final previousUser = website.logoUserId;
    _epoch += 1;
    _setBusy(true);
    setState(() {
      _logoUploading = true;
      website.logo = bytes;
    });
    try {
      final saved = await CampaignMediaService.instance.uploadLogo(bytes);
      if (!mounted) return;
      setState(() {
        website
          ..logo = bytes
          ..logoId = saved.id
          ..logoUrl = saved.url
          ..logoUserId = saved.userId
          ..mediaOwnerId = saved.userId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        website
          ..logo = previousBytes
          ..logoId = previousId
          ..logoUrl = previousUrl
          ..logoUserId = previousUser;
      });
      _show(_message(error));
    } finally {
      if (mounted) {
        setState(() => _logoUploading = false);
        _setBusy(false);
      }
    }
  }

  Future<void> _removeLogo() async {
    if (_busy) return;
    final hadId = website.logoId.isNotEmpty;
    final previousBytes = website.logo;
    final previousId = website.logoId;
    final previousUrl = website.logoUrl;
    final previousUser = website.logoUserId;
    _epoch += 1;
    _setBusy(true);
    setState(() {
      website
        ..logo = null
        ..logoId = ''
        ..logoUrl = ''
        ..logoUserId = '';
    });
    if (!hadId) {
      _setBusy(false);
      return;
    }
    try {
      await CampaignMediaService.instance.deleteLogo();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        website
          ..logo = previousBytes
          ..logoId = previousId
          ..logoUrl = previousUrl
          ..logoUserId = previousUser;
      });
      _show(_message(error));
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _addPhotos() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final remaining = CampaignMediaService.maxPhotos - website.campaignPhotos.length;
    if (remaining <= 0) {
      _show(l10n.line('mediaTooMany'));
      return;
    }
    List<XFile> files;
    try {
      files = await _picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
        limit: remaining,
      );
    } catch (_) {
      if (mounted) _show(l10n.photoError);
      return;
    }
    if (!mounted || files.isEmpty) return;
    var tooMany = false;
    if (files.length > remaining) {
      tooMany = true;
      files = files.sublist(0, remaining);
    }

    final accepted = <Uint8List>[];
    var invalid = false;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final problem = CampaignMediaService.validateBytes(bytes, filename: file.name);
        if (problem != null) {
          invalid = true;
          continue;
        }
        accepted.add(bytes);
      } catch (_) {
        invalid = true;
      }
    }
    if (!mounted) return;
    if (tooMany) _show(l10n.line('mediaTooMany'));
    if (invalid) _show(l10n.line('mediaSkipped'));
    if (accepted.isEmpty) return;

    _epoch += 1;
    _setBusy(true);
    setState(() {
      _pendingPhotos = accepted;
      _photoTotal = accepted.length;
      _photoDone = 0;
    });
    var failed = 0;
    String? stopCode;
    try {
      for (var index = 0; index < accepted.length; index++) {
        final bytes = accepted[index];
        try {
          final saved = await CampaignMediaService.instance.uploadPhoto(bytes);
          if (!mounted) return;
          setState(() {
            website.campaignPhotos.add(
              CampaignPhoto(
                id: saved.id,
                url: saved.url,
                userId: saved.userId,
                bytes: bytes,
              ),
            );
            website
              ..ownsGallery = true
              ..mediaOwnerId = saved.userId
              ..syncGalleryBytes();
            _photoDone = index + 1;
            _pendingPhotos = accepted.sublist(index + 1);
          });
        } on CampaignMediaException catch (error) {
          failed += 1;
          if (error.code == 'unauthorized' ||
              error.code == 'storage_not_ready' ||
              error.code == 'too_many_photos') {
            stopCode = error.code;
            break;
          }
        } catch (_) {
          failed += 1;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingPhotos = const [];
          _photoTotal = 0;
          _photoDone = 0;
        });
        _setBusy(false);
      }
    }
    if (!mounted) return;
    if (stopCode != null) {
      _show(_message(CampaignMediaException(stopCode)));
    } else if (failed > 0) {
      _show(l10n.line('mediaUploadFailed'));
    }
  }

  Future<void> _removePhoto(CampaignPhoto photo) async {
    if (_busy) return;
    _epoch += 1;
    _setBusy(true);
    setState(() => _deletingId = photo.id);
    try {
      await CampaignMediaService.instance.deletePhoto(photo.id);
      if (!mounted) return;
      setState(() {
        website.campaignPhotos.removeWhere((item) => item.id == photo.id);
        website.ownsGallery = true;
        website.syncGalleryBytes();
      });
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
        _setBusy(false);
      }
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    widget.onBusyChanged(value);
    if (mounted) setState(() {});
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _message(Object error, {bool loading = false}) {
    final l10n = AppLocalizations.of(context);
    final code = error is CampaignMediaException ? error.code : '';
    return switch (code) {
      'invalid_photo' => l10n.line('mediaInvalidType'),
      'file_too_large' => l10n.line('mediaTooLarge'),
      'too_many_photos' => l10n.line('mediaTooMany'),
      'unauthorized' => l10n.line('mediaSignIn'),
      'storage_not_ready' => l10n.line('mediaStorageNotReady'),
      'delete_failed' => l10n.line('mediaDeleteFailed'),
      _ => loading ? l10n.line('mediaLoadFailed') : l10n.line('mediaUploadFailed'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final hasLogo = website.logo != null || website.logoUrl.isNotEmpty;
    final countLabel = l10n
        .line('photoCount')
        .replaceAll('{count}', '${website.campaignPhotos.length}')
        .replaceAll('{max}', '${CampaignMediaService.maxPhotos}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l10n.line('qLogo')} (${l10n.optionalLabel})', style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('upload-logo'),
          onPressed: _busy ? null : _uploadLogo,
          style: OutlinedButton.styleFrom(foregroundColor: palette.accent),
          icon: Icon(hasLogo ? Icons.cached : Icons.add_a_photo_outlined),
          label: Text(hasLogo ? l10n.line('replaceLogo') : l10n.line('uploadLogo')),
        ),
        if (hasLogo) ...[
          const SizedBox(height: 8),
          _LogoPreview(
            bytes: website.logo,
            url: website.logoUrl,
            uploading: _logoUploading,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('remove-logo'),
              onPressed: _busy ? null : _removeLogo,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.danger,
                side: BorderSide(color: palette.border),
              ),
              icon: const Icon(Icons.close),
              label: Text(l10n.line('removeLogo')),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('${l10n.line('qPhotos')} (${l10n.optionalLabel})', style: AppTextStyles.label(context)),
        if (website.campaignPhotos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(countLabel, style: AppTextStyles.muted(context)),
        ],
        const SizedBox(height: 8),
        if (website.campaignPhotos.isEmpty && _pendingPhotos.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('add-more-photos'),
              onPressed: _busy ? null : _addPhotos,
              style: OutlinedButton.styleFrom(foregroundColor: palette.accent),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.line('addMorePhotos')),
            ),
          )
        else
          _PhotoGrid(
            photos: website.campaignPhotos,
            pending: _pendingPhotos,
            deletingId: _deletingId,
            busy: _busy,
            onAdd: _addPhotos,
            onRemove: _removePhoto,
          ),
        if (_loading) ...[
          const SizedBox(height: 8),
          Text(
            l10n.line('mediaLoading'),
            key: const Key('media-loading'),
            style: AppTextStyles.muted(context),
          ),
        ],
        if (_logoUploading || _photoTotal > 0) ...[
          const SizedBox(height: 12),
          Text(
            _logoUploading
                ? l10n.line('mediaUploadingLogo')
                : l10n
                    .line('mediaUploading')
                    .replaceAll('{current}', '${_photoDone < _photoTotal ? _photoDone + 1 : _photoTotal}')
                    .replaceAll('{total}', '$_photoTotal'),
            key: const Key('media-progress'),
            style: AppTextStyles.principle(context),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            value: _photoTotal == 0 ? null : ((_photoDone + 0.15) / _photoTotal).clamp(0.0, 1.0),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({
    required this.bytes,
    required this.url,
    required this.uploading,
  });

  final Uint8List? bytes;
  final String url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('logo-preview'),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _StoredImage(bytes: bytes, url: url, fit: BoxFit.contain),
          ),
          if (uploading)
            const ColoredBox(
              color: Color(0x88FFFFFF),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.pending,
    required this.deletingId,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<CampaignPhoto> photos;
  final List<Uint8List> pending;
  final String? deletingId;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<CampaignPhoto> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 48) return const SizedBox.shrink();
        final columns = width >= 760 ? 4 : width >= 420 ? 3 : 2;
        const spacing = 10.0;
        final tile = (width - spacing * (columns - 1)) / columns;
        final showAdd = !busy && photos.length < CampaignMediaService.maxPhotos;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final photo in photos)
              _PhotoTile(
                size: tile,
                photo: photo,
                deleting: deletingId == photo.id,
                onRemove: busy ? null : () => onRemove(photo),
              ),
            for (final bytes in pending)
              _PendingTile(size: tile, bytes: bytes),
            if (showAdd)
              SizedBox(
                width: tile,
                height: tile,
                child: OutlinedButton(
                  key: const Key('add-more-photos'),
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.all(8),
                    minimumSize: Size(tile, tile),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined),
                      const SizedBox(height: 6),
                      Text(
                        l10n.line('addMorePhotos'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.size,
    required this.photo,
    required this.deleting,
    required this.onRemove,
  });

  final double size;
  final CampaignPhoto photo;
  final bool deleting;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      key: Key('campaign-photo-${photo.id}'),
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: palette.surfaceSecondary,
                child: _StoredImage(bytes: photo.bytes, url: photo.url, fit: BoxFit.cover),
              ),
              if (deleting)
                const ColoredBox(
                  color: Color(0x88FFFFFF),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white,
                  elevation: 1,
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: Key('remove-photo-${photo.id}'),
                    tooltip: l10n.line('removePhoto'),
                    onPressed: onRemove,
                    icon: Icon(Icons.close, size: 18, color: palette.danger),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.size, required this.bytes});

  final double size;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
            const ColoredBox(
              color: Color(0x660B1626),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoredImage extends StatelessWidget {
  const _StoredImage({required this.bytes, required this.url, required this.fit});

  final Uint8List? bytes;
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit, gaplessPlayback: true);
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image_outlined, color: context.palette.textMuted);
        },
      );
    }
    return Icon(Icons.broken_image_outlined, color: context.palette.textMuted);
  }
}
