// v1.0.2: in-app APK download ki ASLI test — koi mock nahi, local HTTP server
// se bytes download hoti hain aur poora pipeline chalta hai:
//   .part file -> sha256 verify -> final filename pe rename.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:small_school_management/services/update_service.dart';

/// Fake APK bytes (asli APK ki zaroorat nahi — pipeline wahi hai).
const _fakeApkBytes = [
  0x50, 0x4B, 0x03, 0x04, // ZIP magic, jaisa asli APK ka hota hai
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
];

late String realSha;
late HttpServer server;

Future<void> main() async {
  setUpAll(() async {
    // Asli hash isi code se nikaalte hain jo production use karti hai.
    final tmp = File(
      '${Directory.systemTemp.path}/fake-${DateTime.now().microsecondsSinceEpoch}.apk',
    );
    await tmp.writeAsBytes(_fakeApkBytes);
    realSha = await UpdateService.sha256OfFile(tmp);
    await tmp.delete();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      if (req.uri.path == '/missing.apk') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      req.response.headers.contentType =
          ContentType('application', 'vnd.android.package-archive');
      if (req.uri.path == '/chunked.apk') {
        // Content-Length ke baghair (chunked) — dio is surat mein total = -1
        // deta hai, aur humein jhootha percentage nahi bhejna chahiye.
        req.response.bufferOutput = false;
        req.response.add(_fakeApkBytes.sublist(0, 4));
        await req.response.flush();
        req.response.add(_fakeApkBytes.sublist(4));
        await req.response.close();
        return;
      }
      req.response.contentLength = _fakeApkBytes.length;
      req.response.add(_fakeApkBytes);
      await req.response.close();
    });
  });

  tearDownAll(() => server.close(force: true));

  group('UpdateService.downloadApk (asli HTTP se)', () {
    late Directory dir;
    late UpdateService svc;
    late String url;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('apk_test_');
      svc = UpdateService();
      url = 'http://127.0.0.1:${server.port}/app.apk';
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('download hoti hai, .part hat jati hai, file sahi jagah aati hai',
        () async {
      final file = await svc.downloadApk(
        url: url,
        version: '1.0.2',
        dir: dir,
        expectedSha256: realSha,
      );

      expect(await file.exists(), isTrue);
      expect(
        file.path,
        '${dir.path}/${UpdateService.apkFileName('1.0.2')}',
        reason: 'File versioned naam pe honi chahiye',
      );
      expect(
        await File('${file.path}.part').exists(),
        isFalse,
        reason: '.part file rename ke baad nahi rehni chahiye',
      );
      expect(await file.readAsBytes(), _fakeApkBytes,
          reason: 'Download ki bytes server ki bytes se milni chahiye');
    });

    test('progress callback chalta hai aur 1.0 tak pohanchta hai', () async {
      final seen = <double>[];
      await svc.downloadApk(
        url: url,
        version: '1.0.2',
        dir: dir,
        expectedSha256: realSha,
        onProgress: seen.add,
      );
      expect(seen, isNotEmpty, reason: 'progress report hona chahiye');
      expect(seen.last, 1.0);
      expect(seen.every((v) => v >= 0.0 && v <= 1.0), isTrue);
    });

    test('galat sha256 pe throw hota hai aur corrupt file nahi chhori jati',
        () async {
      final wrongSha = realSha.replaceRange(0, 4, 'dead');
      expect(
        () => svc.downloadApk(
          url: url,
          version: '1.0.2',
          dir: dir,
          expectedSha256: wrongSha,
        ),
        throwsA(allOf(isA<String>(), contains('sha256'))),
      );

      // Thoda wait taake async cleanup ho jaye.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final leftovers = await dir.list().toList();
      expect(leftovers, isEmpty,
          reason: 'Verify fail hone ke baad folder khaali rehna chahiye');
    });

    test('download fail hone pe .part file saaf ho jati hai', () async {
      expect(
        () => svc.downloadApk(
          url: 'http://127.0.0.1:${server.port}/missing.apk',
          version: '1.0.2',
          dir: dir,
          expectedSha256: realSha,
        ),
        throwsA(isA<String>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(await dir.list().toList(), isEmpty);
    });

    test('pehle se maujood sahee APK dobara download nahi hoti', () async {
      final first = await svc.downloadApk(
        url: url,
        version: '1.0.2',
        dir: dir,
        expectedSha256: realSha,
      );
      final mtime = await first.lastModified();

      // Ab server band kar dein — agar dobara download ki koshish hui to fail.
      await server.close(force: true);
      final second = await svc.downloadApk(
        url: url,
        version: '1.0.2',
        dir: dir,
        expectedSha256: realSha,
      );
      expect(second.path, first.path);
      expect(await second.lastModified(), mtime,
          reason: 'File dobara download nahi honi chahiye thi');

      // Baaki tests ke liye server dobara chalu (agla test setUpAll pe depend
      // nahi karta, is liye naya server banate hain).
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        req.response.add(_fakeApkBytes);
        await req.response.close();
      });
      url = 'http://127.0.0.1:${server.port}/app.apk';
    });

    test('chunked download (file ka size maloom na ho) bhi kaam karti hai',
        () async {
      final seen = <double>[];
      final file = await svc.downloadApk(
        url: 'http://127.0.0.1:${server.port}/chunked.apk',
        version: '1.0.2',
        dir: dir,
        expectedSha256: realSha,
        onProgress: seen.add,
      );
      expect(await file.readAsBytes(), _fakeApkBytes,
          reason: 'Chunked download ke bawajood bytes mukammal honi chahiye');
      // dio total = -1 deta hai jab Content-Length na ho. Us waqt fraction
      // report hi nahi karte — warna UI 0% pe atka hua (broken) lagta hai.
      expect(seen, isEmpty, reason: 'unknown size pe fraction nahi bhejna');
    });
  });

  group('UpdateService.verifySha256', () {
    late File f;
    setUp(() async {
      f = File(
          '${Directory.systemTemp.path}/v-${DateTime.now().microsecondsSinceEpoch}');
      await f.writeAsBytes(_fakeApkBytes);
    });
    tearDown(() async {
      if (await f.exists()) await f.delete();
    });

    test('sahi hash pe true', () async {
      expect(await UpdateService.verifySha256(f, realSha), isTrue);
    });

    test('hash case-insensitive aur trim hota hai', () async {
      expect(
          await UpdateService.verifySha256(f, realSha.toUpperCase()), isTrue);
      expect(await UpdateService.verifySha256(f, '  $realSha\n'), isTrue);
    });

    test('galat hash pe false', () async {
      expect(await UpdateService.verifySha256(f, 'a' * 64), isFalse);
    });

    test('sha256 na diya jaye to true (version.json mein optional hai)',
        () async {
      expect(await UpdateService.verifySha256(f, null), isTrue);
      expect(await UpdateService.verifySha256(f, ''), isTrue);
      expect(await UpdateService.verifySha256(f, '   '), isTrue);
    });
  });

  test('sha256OfFile sahi format ka hash deta hai', () async {
    final tmp = File(
      '${Directory.systemTemp.path}/fmt-${DateTime.now().microsecondsSinceEpoch}',
    );
    await tmp.writeAsBytes(_fakeApkBytes);
    final h = await UpdateService.sha256OfFile(tmp);
    await tmp.delete();
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h), isTrue, reason: 'hash: $h');
  });
}
