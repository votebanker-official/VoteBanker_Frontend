import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/core/utils/person_name.dart';

void main() {
  test('formats every person-name part for display', () {
    expect(formatPersonName('  arjun   kumar  verma '), 'Arjun Kumar Verma');
    expect(formatPersonName("ravi-kumar o'neil"), "Ravi-Kumar O'Neil");
  });

  test('keeps an empty name empty', () {
    expect(formatPersonName('   '), isEmpty);
  });
}
