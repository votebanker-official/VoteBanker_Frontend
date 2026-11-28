import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/core/widgets/circular_skip_button.dart';

void main() {
  testWidgets('renders compactly and invokes the existing callback', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: CircularSkipButton(
              key: const Key('compact-skip'),
              onPressed: () => pressed = true,
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const Key('compact-skip'));
    expect(tester.getSize(button), const Size(76, 44));
    expect(tester.widget<Text>(find.text('Skip')).style?.fontSize, 13);

    await tester.tap(button);
    expect(pressed, isTrue);
  });
}
