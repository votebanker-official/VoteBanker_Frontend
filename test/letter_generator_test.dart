import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/letter_generator/letter_generator_screen.dart';
import 'package:votebanker/features/letter_generator/letter_model.dart';
import 'package:votebanker/features/letter_generator/letter_pdf.dart';
import 'package:votebanker/features/letter_generator/letter_service.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  test('required letter fields are named before a letter is requested', () {
    final errors = letterFieldErrors(
      LetterDraft(
        senderName: '',
        senderAddress: '',
        mobile: '12',
        email: 'not-an-email',
        politicianName: '',
        designation: '',
        designationDetail: '',
        constituency: '',
        subject: '',
        purpose: '',
        message: '',
        date: DateTime(2026, 10, 7),
      ),
    );

    expect(errors['senderName'], 'letterNeedSender');
    expect(errors['politicianName'], 'letterNeedPolitician');
    expect(errors['designation'], 'letterNeedDesignation');
    expect(errors['email'], 'letterNeedEmail');
    expect(errors['mobile'], 'letterNeedMobile');
    expect(letterFileName('Repair: ward road'), 'Repair ward road.pdf');
  });

  test('a letter pdf starts as a pdf document', () async {
    final bytes = await buildLetterPdf('Date: 7 October 2026\n\nYours sincerely,\nAnita Rao');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('the letter service posts the form and reads the letter', () async {
    http.Request? sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': true,
          'letter': {
            'text': 'Respected MLA Ravi Kumar,\n\nPlease repair the school road.\n\nYours sincerely,\nAnita Rao',
            'source': 'ai',
            'subject': 'Repair of the ward road',
            'senderName': 'Anita Rao',
            'politicianName': 'Ravi Kumar',
          },
        })),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final letter = await LetterService(
      client: client,
      baseUrls: const ['http://letter.test'],
    ).generate(
      LetterDraft(
        senderName: 'Anita Rao',
        senderAddress: '12 Lake Road',
        mobile: '9876543210',
        email: 'anita@example.com',
        politicianName: 'Ravi Kumar',
        designation: 'MLA',
        designationDetail: '',
        constituency: 'Bengaluru South',
        subject: 'Repair of the ward road',
        purpose: 'the damaged school road',
        message: 'Children cannot walk safely.',
        date: DateTime(2026, 10, 7),
      ),
    );

    expect(sentRequest?.url.path, '/api/letters/generate');
    final posted = jsonDecode(sentRequest!.body) as Map<String, dynamic>;
    expect(posted['politicianName'], 'Ravi Kumar');
    expect(posted['date'], '2026-10-07');
    expect(letter.isMock, isFalse);
    expect(letter.text, contains('school road'));
  });

  testWidgets('missing details are explained, then a letter can be edited and shared', (tester) async {
    LetterDraft? sent;
    final gate = Completer<GeneratedLetter>();
    await tester.pumpWidget(
      _app(
        LetterGeneratorScreen(
          service: _ScriptedLetterService((draft) {
            sent = draft;
            return gate.future;
          }),
          shareText: (text, {subject}) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Letter Generator'), findsWidgets);
    await _reveal(tester, find.text('Generate Letter'));
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Generate Letter')).onPressed!.call();
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 4000));
    await tester.pump();

    expect(find.text('Enter the sender name.'), findsOneWidget);
    expect(find.text('Select a designation.'), findsOneWidget);
    await _reveal(tester, find.text('Enter the detailed message.'));
    expect(find.text('Enter the detailed message.'), findsOneWidget);
    expect(sent, isNull);

    await tester.drag(find.byType(ListView), const Offset(0, 5000));
    await tester.pump();
    _setField(tester, const Key('letter-sender'), 'Anita Rao');
    _setField(tester, const Key('letter-politician'), 'Ravi Kumar');
    await _reveal(tester, find.byKey(const Key('letter-designation')));
    tester
        .widget<DropdownButtonFormField<String>>(find.byKey(const Key('letter-designation')))
        .onChanged!('MLA');
    await tester.pump();
    await _reveal(tester, find.byKey(const Key('letter-constituency')));
    _setField(tester, const Key('letter-constituency'), 'Bengaluru South');
    await _reveal(tester, find.byKey(const Key('letter-subject')));
    _setField(tester, const Key('letter-subject'), 'Repair of the ward road');
    await _reveal(tester, find.byKey(const Key('letter-purpose')));
    _setField(tester, const Key('letter-purpose'), 'the damaged school road');
    await _reveal(tester, find.byKey(const Key('letter-message')));
    _setField(tester, const Key('letter-message'), 'Children cannot walk safely.');
    await _reveal(tester, find.text('Generate Letter'));
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Generate Letter')).onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Writing your letter...'), findsOneWidget);
    gate.complete(
      GeneratedLetter(
        text: 'Respected MLA Ravi Kumar,\n\nPlease repair the school road.\n\nYours sincerely,\nAnita Rao',
        source: 'mock',
        subject: sent!.subject,
        senderName: sent!.senderName,
        politicianName: sent!.politicianName,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(sent?.politicianName, 'Ravi Kumar');
    expect(find.text('Preview letter'), findsOneWidget);
    expect(find.textContaining('school road'), findsOneWidget);
    expect(find.textContaining('composed from your details'), findsOneWidget);
    await _reveal(tester, find.text('Share'));
    expect(find.text('Edit Letter'), findsOneWidget);
    expect(find.text('Copy Letter'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
}

void _setField(WidgetTester tester, Key key, String value) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
  );
  field.controller!.text = value;
  field.onChanged?.call(value);
}

class _ScriptedLetterService extends LetterService {
  _ScriptedLetterService(this._generate);

  final Future<GeneratedLetter> Function(LetterDraft draft) _generate;

  @override
  Future<GeneratedLetter> generate(LetterDraft draft) => _generate(draft);
}

Widget _app(Widget home) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
