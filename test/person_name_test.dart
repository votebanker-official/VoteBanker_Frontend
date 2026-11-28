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

  test('website heading uses the first name and .com', () {
    expect(formatWebsiteHeading('  vaishnavi   kaladagi  '), 'Vaishnavi.com');
    expect(formatWebsiteHeading('RAHUL SHARMA'), 'Rahul.com');
    expect(formatWebsiteHeading('priya'), 'Priya.com');
    expect(formatWebsiteHeading('john david smith'), 'John.com');
    expect(formatWebsiteHeading('McDonald Jones'), 'McDonald.com');
  });

  test('website heading rejects empty, email, and placeholder names', () {
    expect(formatWebsiteHeading(null), isNull);
    expect(formatWebsiteHeading('   '), isNull);
    expect(formatWebsiteHeading('vaishnavi@gmail.com'), isNull);
    expect(
      formatWebsiteHeading(
        'priya@example.com',
        accountEmail: 'priya@example.com',
      ),
      isNull,
    );
    expect(formatWebsiteHeading('null'), isNull);
    expect(formatWebsiteHeading('User'), isNull);
    expect(formatWebsiteHeading('.com'), isNull);
  });

  test('website heading follows the signed-in profile, then the session', () {
    expect(
      websiteBuilderHeading(
        signedIn: false,
        profileName: 'Vaishnavi Kaladagi',
        sessionName: 'Rahul Sharma',
        fallback: 'My Website',
      ),
      'My Website',
    );
    expect(
      websiteBuilderHeading(
        signedIn: true,
        profileName: null,
        sessionName: 'RAHUL SHARMA',
        fallback: 'My Website',
      ),
      'Rahul.com',
    );
    expect(
      websiteBuilderHeading(
        signedIn: true,
        profileName: 'priya',
        sessionName: 'Rahul Sharma',
        fallback: 'My Website',
      ),
      'Priya.com',
    );
    expect(
      websiteBuilderHeading(
        signedIn: true,
        profileName: '',
        sessionName: 'john david smith',
        fallback: 'My Website',
      ),
      'John.com',
    );
    expect(
      websiteBuilderHeading(
        signedIn: true,
        profileName: 'user@email.com',
        sessionName: '',
        fallback: 'My Website',
      ),
      'My Website',
    );
  });
}
