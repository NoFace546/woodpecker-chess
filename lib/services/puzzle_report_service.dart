import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/solve/puzzle.dart';

Future<void> reportPuzzle(BuildContext context, Puzzle puzzle) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final pkg = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    String deviceLine = 'Device: unknown';
    String osLine = 'OS: unknown';
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceLine = 'Device: ${info.manufacturer} ${info.model}';
      osLine = 'OS: Android ${info.version.release} (API ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceLine = 'Device: ${info.model}';
      osLine = 'OS: iOS ${info.systemVersion}';
    }

    final body = '''
[Auto-generated]
App version: ${pkg.version}+${pkg.buildNumber}
$deviceLine
$osLine

Puzzle ID: ${puzzle.id}
Rating: ${puzzle.rating}
Themes: ${puzzle.themes.join(', ')}
FEN: ${puzzle.fen}
Line: ${puzzle.uciMoves.join(' ')}

[Please describe what looks wrong]
Why do you think this puzzle is invalid?
''';
    final uri = Uri(
      scheme: 'mailto',
      path: 'sebiosjed@gmail.com',
      query: _encodeQuery({
        'subject': 'Woodpecker puzzle report: ${puzzle.id}',
        'body': body,
      }),
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open your email app. Please try again.'),
      ),
    );
  }
}

String _encodeQuery(Map<String, String> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
}
