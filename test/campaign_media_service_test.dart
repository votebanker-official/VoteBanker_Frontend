import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/features/website/models/website_draft.dart';
import 'package:votebanker/features/website/services/campaign_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AuthService.instance.session = null;
  });

  test('validateBytes accepts jpg, jpeg, png, and webp only', () {
    expect(
      CampaignMediaService.validateBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF]), filename: 'logo.jpg'),
      isNull,
    );
    expect(
      CampaignMediaService.validateBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF]), filename: 'logo.JPEG'),
      isNull,
    );
    expect(
      CampaignMediaService.validateBytes(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        filename: 'mark.png',
      ),
      isNull,
    );
    final webp = Uint8List.fromList([
      ...'RIFF'.codeUnits,
      0,
      0,
      0,
      0,
      ...'WEBP'.codeUnits,
    ]);
    expect(CampaignMediaService.validateBytes(webp, filename: 'photo.webp'), isNull);
    expect(
      CampaignMediaService.validateBytes(Uint8List.fromList('GIF89a'.codeUnits), filename: 'a.gif'),
      'invalid_photo',
    );
    expect(
      CampaignMediaService.validateBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF]), filename: 'notes.txt'),
      'invalid_photo',
    );
    expect(
      CampaignMediaService.validateBytes(Uint8List(CampaignMediaService.maxBytes + 1), filename: 'big.jpg'),
      'file_too_large',
    );
  });

  test('saved media keeps bytes for the same user and drops them for another', () {
    final draft = WebsiteDraft();
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
    draft.applyStoredMedia(
      userId: 'user-1',
      logoId: 'logo-1',
      logoUrl: 'https://cdn.example/logo.jpg',
      logoUserId: 'user-1',
      photos: [
        CampaignPhoto(id: 'p1', url: 'https://cdn.example/p1.jpg', userId: 'user-1', bytes: bytes),
      ],
    );
    expect(draft.logoUrl, 'https://cdn.example/logo.jpg');
    expect(draft.campaignPhotos.single.bytes, bytes);
    expect(draft.photos, [bytes]);

    draft.applyStoredMedia(
      userId: 'user-1',
      logoId: 'logo-1',
      logoUrl: 'https://cdn.example/logo.jpg',
      logoUserId: 'user-1',
      photos: [
        CampaignPhoto(id: 'p1', url: 'https://cdn.example/p1.jpg', userId: 'user-1'),
      ],
    );
    expect(draft.campaignPhotos.single.bytes, bytes);
    expect(draft.logo, isNull);

    draft.applyStoredMedia(
      userId: 'user-2',
      photos: const [],
    );
    expect(draft.mediaOwnerId, 'user-2');
    expect(draft.campaignPhotos, isEmpty);
    expect(draft.logoUrl, isEmpty);
    expect(draft.photos, isEmpty);
  });

  test('upload and fetch talk to the campaign media API', () async {
    final requests = <http.Request>[];
    final client = _ScriptedClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'userId': 'user-1',
            'logo': {
              'id': 'logo-1',
              'url': 'https://cdn.example/logo.jpg',
              'userId': 'user-1',
            },
            'photos': [
              {
                'id': 'photo-1',
                'url': 'https://cdn.example/photo.jpg',
                'userId': 'user-1',
              },
            ],
          }),
          200,
        );
      }
      if (request.method == 'DELETE') {
        return http.Response(jsonEncode({'deleted': true}), 200);
      }
      final kind = request.url.path.endsWith('/logo') ? 'logo' : 'photo';
      return http.Response(
        jsonEncode({
          kind: {
            'id': '$kind-new',
            'url': 'https://cdn.example/$kind.jpg',
            'userId': 'user-1',
          },
        }),
        201,
      );
    });
    final service = CampaignMediaService(client: client);
    AuthService.instance.session = const AuthSession(
      accessToken: 'token-1',
      refreshToken: 'refresh-1',
      userId: 'user-1',
      phone: '+910000000000',
    );

    final saved = await service.fetch();
    expect(saved!.logo!.url, 'https://cdn.example/logo.jpg');
    expect(saved.photos.single.userId, 'user-1');
    expect(requests.single.headers['authorization'], 'Bearer token-1');

    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
    final logo = await service.uploadLogo(jpeg);
    expect(logo.id, 'logo-new');
    expect(requests.last.headers['content-type'], 'image/jpeg');
    expect(requests.last.url.path, endsWith('/api/campaign-media/logo'));
    expect(requests.last.bodyBytes, jpeg);

    final photo = await service.uploadPhoto(jpeg);
    expect(photo.url, 'https://cdn.example/photo.jpg');
    expect(requests.last.url.path, endsWith('/api/campaign-media/photos'));

    await service.deletePhoto('photo-1');
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, endsWith('/api/campaign-media/photos/photo-1'));

    expect(
      () => service.uploadLogo(Uint8List.fromList('GIF89a'.codeUnits)),
      throwsA(isA<CampaignMediaException>().having((error) => error.code, 'code', 'invalid_photo')),
    );
  });

  test('a rejected upload reports the server error', () async {
    final service = CampaignMediaService(
      client: _ScriptedClient((request) async {
        return http.Response(jsonEncode({'error': 'too_many_photos'}), 400);
      }),
    );
    AuthService.instance.session = const AuthSession(
      accessToken: 'token-1',
      refreshToken: 'refresh-1',
      userId: 'user-1',
      phone: '+910000000000',
    );
    expect(
      () => service.uploadPhoto(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
      throwsA(isA<CampaignMediaException>().having((error) => error.code, 'code', 'too_many_photos')),
    );
  });
}

class _ScriptedClient extends http.BaseClient {
  _ScriptedClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request as http.Request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
