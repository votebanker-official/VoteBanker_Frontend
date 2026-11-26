import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/features/profile/screens/my_portfolio_screen.dart';

void main() {
  testWidgets('my portfolio displays profile data returned by the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MyPortfolioScreen(
          loadProfile:
              () async => {
                'full_name': 'Asha Rao',
                'designation': 'Councillor',
                'organization': 'Community Alliance',
                'assembly_constituency': 'Central Ward',
                'contact_email': 'asha@example.test',
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Portfolio'), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Councillor · Community Alliance'), findsOneWidget);
    expect(find.text('Central Ward'), findsOneWidget);
    expect(find.text('asha@example.test'), findsOneWidget);
    expect(find.text('No saved portfolio details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('my portfolio reports an empty profile without inventing data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MyPortfolioScreen(loadProfile: () async => null),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved portfolio details'), findsOneWidget);
    expect(find.text('Sample User'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
