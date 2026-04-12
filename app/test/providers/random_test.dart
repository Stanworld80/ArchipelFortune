import 'package:flutter_test/flutter_test.dart';
import 'package:app/providers/session_provider.dart';

void main() {
  group('ArchipelRandom Tests', () {
    test('ArchipelRandom should be deterministic', () {
      final rand1 = ArchipelRandom(12345);
      final rand2 = ArchipelRandom(12345);

      for (int i = 0; i < 100; i++) {
        expect(rand1.next(), rand2.next());
      }
    });

    test('ArchipelRandom.nextInt should be within range', () {
      final rand = ArchipelRandom(42);
      for (int i = 0; i < 100; i++) {
        final val = rand.nextInt(10);
        expect(val, greaterThanOrEqualTo(0));
        expect(val, lessThan(10));
      }
    });

    test('ArchipelRandom.nextBool should return booleans', () {
      final rand = ArchipelRandom(100);
      bool hadTrue = false;
      bool hadFalse = false;
      for (int i = 0; i < 100; i++) {
        final val = rand.nextBool();
        if (val) hadTrue = true;
        else hadFalse = true;
      }
      expect(hadTrue, true);
      expect(hadFalse, true);
    });
  });
}
