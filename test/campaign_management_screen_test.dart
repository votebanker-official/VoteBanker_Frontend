import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/features/campaigns/screens/campaign_management_screen.dart';
import 'package:votebanker/features/campaigns/services/campaign_media_service.dart';

void main() {
  testWidgets('campaign management shows saved media and actual photo count', (
    tester,
  ) async {
    final repository = _CampaignMediaRepository(
      CampaignMediaCollection(
        logo: const CampaignMediaItem(
          id: 'logo-id',
          url: 'https://example.test/logo.png',
          kind: 'logo',
        ),
        photos: const [
          CampaignMediaItem(
            id: 'photo-id',
            url: 'https://example.test/photo.png',
            kind: 'photo',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CampaignManagementScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campaign Management'), findsOneWidget);
    expect(find.text('Saved campaign logo'), findsOneWidget);
    expect(find.text('1 of 10 photos'), findsOneWidget);
    expect(find.byKey(const Key('campaign-photo-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campaign management gives an empty state without fake media', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: CampaignManagementScreen(
          repository: _CampaignMediaRepository(const CampaignMediaCollection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No campaign photos yet'), findsOneWidget);
    expect(find.text('0 of 10 photos'), findsOneWidget);
    expect(find.text('Saved campaign logo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _CampaignMediaRepository implements CampaignMediaRepository {
  _CampaignMediaRepository(this.collection);

  final CampaignMediaCollection collection;

  @override
  Future<void> deleteLogo() async {}

  @override
  Future<void> deletePhoto(String id) async {}

  @override
  Future<CampaignMediaCollection> load() async => collection;

  @override
  Future<CampaignMediaItem> uploadLogo(
    List<int> bytes,
    String contentType,
  ) async {
    return const CampaignMediaItem(
      id: 'logo-id',
      url: 'https://example.test/logo.png',
      kind: 'logo',
    );
  }

  @override
  Future<CampaignMediaItem> uploadPhoto(
    List<int> bytes,
    String contentType,
  ) async {
    return const CampaignMediaItem(
      id: 'photo-id',
      url: 'https://example.test/photo.png',
      kind: 'photo',
    );
  }
}
