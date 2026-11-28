import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/features/campaigns/services/campaign_media_service.dart';

void main() {
  test('campaign media requests use the signed-in user API', () async {
    final previousSession = AuthService.instance.session;
    AuthService.instance.session = const AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      userId: 'user-id',
      phone: '+911234567890',
    );
    addTearDown(() => AuthService.instance.session = previousSession);

    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'logo': null,
            'photos': [
              {
                'id': 'photo-id',
                'userId': 'user-id',
                'url': 'https://storage.example/photo.jpg',
                'kind': 'photo',
              },
            ],
          }),
          200,
        );
      }
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'photo': {
              'id': 'uploaded-id',
              'userId': 'user-id',
              'url': 'https://storage.example/uploaded.jpg',
              'kind': 'photo',
            },
          }),
          201,
        );
      }
      return http.Response(
        jsonEncode({'deleted': true, 'id': 'photo-id', 'userId': 'user-id'}),
        200,
      );
    });
    addTearDown(client.close);

    final service = CampaignMediaService(
      client: client,
      baseUrls: const ['https://api.example'],
    );

    final collection = await service.load();
    expect(collection.photos.single.id, 'photo-id');

    final uploaded = await service.uploadPhoto(
      Uint8List.fromList([0xff, 0xd8, 0xff]),
      'image/jpeg',
    );
    expect(uploaded.id, 'uploaded-id');
    await service.deletePhoto('photo-id');

    expect(requests.map((request) => request.url.path), [
      '/api/campaign-media',
      '/api/campaign-media/photos',
      '/api/campaign-media/photos/photo-id',
    ]);
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access-token',
      ),
      isTrue,
    );
    expect(requests[1].headers['content-type'], 'image/jpeg');
    expect(requests[1].bodyBytes, [0xff, 0xd8, 0xff]);
  });

  test(
    'campaign media rejects requests without an authenticated session',
    () async {
      final previousSession = AuthService.instance.session;
      AuthService.instance.session = null;
      addTearDown(() => AuthService.instance.session = previousSession);

      final service = CampaignMediaService(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrls: const ['https://api.example'],
      );
      await expectLater(
        service.load(),
        throwsA(
          isA<CampaignMediaException>().having(
            (error) => error.code,
            'code',
            'unauthorized',
          ),
        ),
      );
    },
  );
}
