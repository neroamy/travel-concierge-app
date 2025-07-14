import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class Logger {
  static File? _logFile;
  static bool _initialized = false;
  static bool enableFileLog = true;

  static Future<void> _init() async {
    if (_initialized) return;
    String logPath;
    if (kIsWeb) {
      // Không hỗ trợ ghi file trên web
      enableFileLog = false;
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      logPath = '${dir.path}/log_app.txt';
    } else {
      // Desktop, dev, emulator
      final logDir = Directory('logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      logPath = 'logs/log_app.txt';
    }
    _logFile = File(logPath);
    _initialized = true;
  }

  static Future<void> log(Object? message) async {
    print(message);
    if (!enableFileLog) return;
    await _init();
    if (_logFile != null) {
      await _logFile!.writeAsString(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
      );
    }
  }
}
