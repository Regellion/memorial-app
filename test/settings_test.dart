import 'package:flutter_test/flutter_test.dart';
import 'package:memorial_online_app/settings.dart';

void main() {
  group('Settings', () {
    test('Initial font size should be 20', () {
      final settings = Settings();
      expect(settings.fontSize, 20);
    });

    test('Setting font size should update correctly', () {
      final settings = Settings();
      settings.setFontSize(30);
      expect(settings.fontSize, 30);
    });

    test('Setting font size should notify listeners', () {
      final settings = Settings();
      var notified = false;
      settings.addListener(() {
        notified = true;
      });
      settings.setFontSize(25);
      expect(notified, true);
    });
  });
}