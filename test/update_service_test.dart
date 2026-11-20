import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:small_school_management/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('naya version true deta hai', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('same version false deta hai', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('purana version false deta hai', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.9', '1.1.0'), isFalse);
    });

    test('numeric compare hota hai, string compare nahi (1.0.10 > 1.0.9)', () {
      // String compare mein '1.0.10' < '1.0.9' hota — yeh bug tha.
      expect(UpdateService.isNewerVersion('1.0.10', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.9', '1.0.10'), isFalse);
    });

    test('alag lambai ke versions (1.0 vs 1.0.1)', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.0', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0', '1.0'), isFalse);
    });

    test('build number (+N) ignore hota hai', () {
      expect(UpdateService.isNewerVersion('1.0.1+2', '1.0.1+1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.2+1', '1.0.1+9'), isTrue);
    });

    test('ghalat / khaali input pe crash nahi hota', () {
      expect(UpdateService.isNewerVersion('', ''), isFalse);
      expect(UpdateService.isNewerVersion('abc', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', 'abc'), isTrue);
    });
  });

  group('UpdateService defaults', () {
    test('fresh instance ka state saaf hota hai', () {
      final s = UpdateService();
      expect(s.updateAvailable, isFalse,
          reason: 'check se pehle kuch available nahi');
      expect(s.latestVersion, isNull);
      expect(s.lastError, isNull);
      expect(s.isChecking, isFalse);
      expect(s.autoUpdateEnabled, isTrue);
    });

    test('autoUpdateEnabled toggle hota hai', () {
      final s = UpdateService();
      s.autoUpdateEnabled = false;
      expect(s.autoUpdateEnabled, isFalse);
    });
  });

  group('Database upgrade wiring (regression)', () {
    // Yeh bug dobara na aaye: DB version bump + onUpgrade zaroori hai warna
    // purani install pe seed data kabhi nahi aata.
    final src = File('lib/db/database_helper.dart').readAsStringSync();

    test('DB version 2 pe hai (1 pe nahi)', () {
      expect(src, contains('static const int _dbVersion = 2;'));
      expect(src, isNot(contains('version: 1,')));
    });

    test('openDatabase mein onUpgrade wired hai', () {
      expect(src, contains('onUpgrade: _onUpgrade'));
      expect(src, contains('onCreate: _onCreate'));
      expect(src, contains('version: _dbVersion'));
    });

    test('onUpgrade purane version se teachers + students seed karta hai', () {
      final body = src.substring(
        src.indexOf('Future<void> _onUpgrade'),
        src.indexOf('// ============ SEED HELPERS'),
      );
      expect(body, contains('if (oldVersion < 2)'));
      expect(body, contains('_seedTeachers(db)'));
      expect(body, contains('_seedStudents(db)'));
    });

    test('seed helpers idempotent hain (duplicate rows se bachate hain)', () {
      for (final table in ['users', 'teachers', 'students']) {
        expect(
          src,
          contains("SELECT COUNT(*) FROM $table"),
          reason: '$table ke liye guard chahiye',
        );
      }
    });

    test('seed data barkarar hai: 5 teachers aur 40 students', () {
      expect(
        "db.insert('teachers'".allMatches(src).length,
        5,
        reason: '5 teachers hone chahiye',
      );
      expect(
        RegExp(r"^\s+\{'name':", multiLine: true).allMatches(src).length,
        40,
        reason: '40 students hone chahiye',
      );
    });
  });

  group('UpdateService source wiring (regression)', () {
    final src = File('lib/services/update_service.dart').readAsStringSync();

    test('version hardcode nahi — package_info_plus se aata hai', () {
      expect(
          src,
          contains(
              "import 'package:package_info_plus/package_info_plus.dart';"));
      expect(src, contains('PackageInfo.fromPlatform()'));
      expect(src, isNot(contains("_currentVersion = '1.0.0'")));
    });

    test('jhoota Shorebird SnackBar hata diya gaya', () {
      expect(
          src, isNot(contains('Shorebird will apply patches on next restart')));
      expect(src, isNot(contains('applyUpdate')));
    });

    test('APK download page kholne ka rasta hai', () {
      expect(src, contains('openDownloadPage'));
      expect(src, contains('launchUrl'));
    });
  });
}
