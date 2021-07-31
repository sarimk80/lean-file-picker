import 'dart:async';
import 'dart:io';
import 'dart:core';

import 'package:flutter/services.dart';

class LeanFilePicker {
  static const MethodChannel _channel = const MethodChannel('lean_file_picker');

  static Future<File?> pickFile({List<String>? allowedExtensions}) async {
    final String? path = await _channel.invokeMethod('pickFile', <String, Object?>{
      'allowedExtensions': allowedExtensions,
    });
    if (path != null) {
      return File(path);
    }
    return null;
  }
}
