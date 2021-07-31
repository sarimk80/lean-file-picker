
import 'dart:async';

import 'package:flutter/services.dart';

class LeanFilePicker {
  static const MethodChannel _channel =
      const MethodChannel('lean_file_picker');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
