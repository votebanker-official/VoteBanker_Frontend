import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/onboarding/models/domain_suggestion.dart';

void main() {
  test('Arjun Verma produces the sample domains', () {
    final results = suggestDomains('Arjun Verma');

    expect(results.map((domain) => domain.name).toList(), [
      'arjunverma.com',
      'arjunverma.in',
      'arjunverma.co.in',
      'arjunverma.org',
      'arjunverma.net',
    ]);
    expect(results.every((domain) => domain.available), isTrue);
    expect(results.map((domain) => domain.priceInr).toList(), [
      999,
      499,
      299,
      899,
      799,
    ]);
  });

  test('blank and non-latin names produce no domains', () {
    expect(suggestDomains('   '), isEmpty);
    expect(suggestDomains('ಅರ್ಜುನ್'), isEmpty);
  });
}
