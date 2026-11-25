import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _listDartFiles(Directory dir) {
  if (!dir.existsSync()) return const <File>[];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList(growable: false);
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

void main() {
  final rootDir = Directory.current;

  group('Phase 8.1 — Clean Architecture & Static Security Audit', () {
    test('1. All lib/features/*/domain/ files are 100% Pure Dart', () {
      final featuresDir = Directory('${rootDir.path}/lib/features');
      expect(featuresDir.existsSync(), isTrue);

      final forbiddenImportPattern = RegExp(
        r'''^\s*import\s+['"](package:flutter/|package:supabase_flutter/|package:drift/|dart:ui)''',
        multiLine: true,
      );

      final violations = <String>[];
      var scannedFiles = 0;

      for (final entity in featuresDir.listSync().whereType<Directory>()) {
        final domainDir = Directory('${entity.path}/domain');
        for (final file in _listDartFiles(domainDir)) {
          scannedFiles++;
          final content = file.readAsStringSync();
          for (final match in forbiddenImportPattern.allMatches(content)) {
            violations.add('${_normalizePath(file.path)}: ${match.group(0)}');
          }
        }
      }

      expect(scannedFiles, greaterThan(0));
      expect(
        violations,
        isEmpty,
        reason: 'Domain layer must remain Pure Dart:\n${violations.join('\n')}',
      );
    });

    test(
      '2. Presentation, Router & Core Widgets never import supabase_flutter or drift',
      () {
        final forbiddenImportPattern = RegExp(
          r'''^\s*import\s+['"]package:(supabase_flutter|drift)/''',
          multiLine: true,
        );

        final targetDirs = <Directory>[
          Directory('${rootDir.path}/lib/core/router'),
          Directory('${rootDir.path}/lib/core/widgets'),
        ];

        final featuresDir = Directory('${rootDir.path}/lib/features');
        for (final entity in featuresDir.listSync().whereType<Directory>()) {
          targetDirs.add(Directory('${entity.path}/presentation'));
        }

        final violations = <String>[];
        var scannedFiles = 0;

        for (final dir in targetDirs) {
          for (final file in _listDartFiles(dir)) {
            scannedFiles++;
            final content = file.readAsStringSync();
            for (final match in forbiddenImportPattern.allMatches(content)) {
              violations.add('${_normalizePath(file.path)}: ${match.group(0)}');
            }
          }
        }

        expect(scannedFiles, greaterThan(0));
        expect(
          violations,
          isEmpty,
          reason:
              'Presentation/Router/Core Widgets must not import Supabase or Drift:\n${violations.join('\n')}',
        );
      },
    );

    test('3. Zero deprecated dart:html imports anywhere in lib/', () {
      final dartHtmlPattern = RegExp(
        r'''^\s*import\s+['"]dart:html['"]''',
        multiLine: true,
      );

      final violations = <String>[];
      final libFiles = _listDartFiles(Directory('${rootDir.path}/lib'));
      expect(libFiles, isNotEmpty);

      for (final file in libFiles) {
        final content = file.readAsStringSync();
        if (dartHtmlPattern.hasMatch(content)) {
          violations.add(_normalizePath(file.path));
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Deprecated dart:html found in:\n${violations.join('\n')}',
      );
    });

    test(
      '4. Student Portal never persists PIN to localStorage, sessionStorage, or SharedPreferences',
      () {
        final portalDir = Directory(
          '${rootDir.path}/lib/features/student_portal',
        );
        expect(portalDir.existsSync(), isTrue);

        final forbiddenStoragePattern = RegExp(
          r'\b(localStorage|sessionStorage|SharedPreferences|shared_preferences)\b',
        );

        final violations = <String>[];
        final files = _listDartFiles(portalDir);
        expect(files, isNotEmpty);

        for (final file in files) {
          final content = file.readAsStringSync();
          if (forbiddenStoragePattern.hasMatch(content)) {
            violations.add(_normalizePath(file.path));
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Client-side storage reference found in student_portal:\n${violations.join('\n')}',
        );
      },
    );

    test('5. Web PWA assets, Drift WASM runtime & Sarabun fonts exist', () {
      final manifestFile = File('${rootDir.path}/web/manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['name'], isA<String>());
      expect((manifest['name'] as String).contains('Checklist-Student'), isTrue);
      expect(manifest['short_name'], 'Checklist');
      expect(manifest['lang'], 'th');
      expect(manifest['display'], 'standalone');
      expect(manifest['start_url'], '/');
      expect(manifest['theme_color'], '#3B5BDB');
      expect(manifest['background_color'], '#3B5BDB');
      expect(manifest['prefer_related_applications'], isFalse);

      final icons = (manifest['icons'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(icons.length, greaterThanOrEqualTo(4));

      final purposes = icons.map((i) => i['purpose'] as String?).toSet();
      expect(purposes, containsAll(<String>['any', 'maskable']));

      for (final icon in icons) {
        final src = icon['src'] as String;
        final iconFile = File('${rootDir.path}/web/$src');
        expect(
          iconFile.existsSync() && iconFile.lengthSync() > 0,
          isTrue,
          reason: 'Missing or empty icon referenced in manifest.json: $src',
        );
      }

      final indexHtml = File('${rootDir.path}/web/index.html');
      expect(indexHtml.existsSync(), isTrue);
      final htmlText = indexHtml.readAsStringSync();
      expect(htmlText, contains('<html lang="th">'));
      expect(htmlText, contains(r'<base href="$FLUTTER_BASE_HREF">'));
      expect(htmlText, contains('apple-mobile-web-app-capable'));
      expect(htmlText, contains('flutter-first-frame'));

      for (final requiredAsset in const <String>[
        'web/favicon.png',
        'web/sqlite3.wasm',
        'web/drift_worker.js',
        'assets/fonts/Sarabun-Regular.ttf',
        'assets/fonts/Sarabun-Bold.ttf',
      ]) {
        final f = File('${rootDir.path}/$requiredAsset');
        expect(
          f.existsSync() && f.lengthSync() > 0,
          isTrue,
          reason: 'Missing or empty required asset: $requiredAsset',
        );
      }
    });

    test(
      '6. vercel.json is valid JSON, serves WASM/PWA headers & never hijacks static/runtime files',
      () {
        final vercelFile = File('${rootDir.path}/vercel.json');
        expect(vercelFile.existsSync(), isTrue);

        final rawJson = vercelFile.readAsStringSync();
        final config = jsonDecode(rawJson) as Map<String, dynamic>;

        expect(config['outputDirectory'], 'build/web');
        expect(config['buildCommand'], isA<String>());
        expect(
          rawJson.contains('Cross-Origin-Embedder-Policy'),
          isFalse,
          reason:
              'Do not add Cross-Origin-Embedder-Policy which can break Supabase/Google OAuth.',
        );

        final rewrites = (config['rewrites'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(rewrites, isNotEmpty);

        final spaRewrite = rewrites.first;
        expect(spaRewrite['destination'], '/index.html');

        final sourcePattern = RegExp('^${spaRewrite['source'] as String}\$');

        // App deep links MUST match the SPA rewrite to /index.html.
        for (final appRoute in const <String>[
          '/',
          '/login',
          '/teacher/dashboard',
          '/teacher/classes/class-123/grading',
          '/student',
          '/student/t-8492',
        ]) {
          expect(
            sourcePattern.hasMatch(appRoute),
            isTrue,
            reason: 'SPA route should rewrite to /index.html: $appRoute',
          );
        }

        // Static / runtime files MUST NOT be hijacked by the SPA rewrite.
        for (final staticAsset in const <String>[
          '/sqlite3.wasm',
          '/drift_worker.js',
          '/main.dart.js',
          '/flutter_service_worker.js',
          '/flutter_bootstrap.js',
          '/manifest.json',
          '/version.json',
          '/favicon.png',
          '/icons/Icon-192.png',
          '/assets/assets/fonts/Sarabun-Regular.ttf',
          '/canvaskit/skwasm.wasm',
        ]) {
          expect(
            sourcePattern.hasMatch(staticAsset),
            isFalse,
            reason: 'Static/runtime file must NOT rewrite to /index.html: $staticAsset',
          );
        }

        final headersList = (config['headers'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        Map<String, String> headersForSource(String source) {
          final entry = headersList.firstWhere(
            (h) => h['source'] == source,
            orElse: () => <String, dynamic>{},
          );
          final list = (entry['headers'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>();
          return <String, String>{
            for (final h in list) h['key'] as String: h['value'] as String,
          };
        }

        expect(
          headersForSource(r'/(.*)\.wasm')['Content-Type'],
          'application/wasm',
        );

        for (final noCachePath in const <String>[
          '/index.html',
          '/flutter_service_worker.js',
          '/version.json',
          '/manifest.json',
        ]) {
          expect(
            headersForSource(noCachePath)['Cache-Control'],
            'no-cache, no-store, must-revalidate',
            reason: 'Expected strict no-cache header on $noCachePath',
          );
        }

        final globalHeaders = headersForSource('/(.*)');
        expect(globalHeaders['X-Content-Type-Options'], 'nosniff');
        expect(
          globalHeaders['Referrer-Policy'],
          'strict-origin-when-cross-origin',
        );
        expect(globalHeaders['X-Frame-Options'], 'SAMEORIGIN');
      },
    );
  });
}
