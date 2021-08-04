import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/services.dart';

/// The copy status of the selected file.
enum FilePickerStatus {
  /// The file is being copied to a temporary location.
  copying,

  /// The copy process has completed.
  done,
}

/// A listener informing about the copy status of the selected file.
typedef FilePickerListener = void Function(FilePickerStatus status);

/// Pick a file using the native file explorer.
///
/// The files available for selection can be restricted by specifying a list
/// of allowed file extensions or a list of allowed MIME types or a combination
/// of the two.
///
/// If the user selects a large file or if the selected file is stored on a
/// virtual file system such as OneDrive or iCloud, copying the file to a
/// temporary location might take a while. To inform the user about the file
/// being copied, e.g. by displaying a progress dialog, a [listener] can be
/// specified that informs about the copy status of the file.
Future<File?> pickFile({
  List<String>? allowedExtensions,
  List<String>? allowedMimeTypes,
  FilePickerListener? listener,
}) async {
  final completer = Completer<File?>();
  _jobController.add(_Job(
    completer: completer,
    allowedExtensions: allowedExtensions,
    allowedMimeTypes: allowedMimeTypes,
    listener: listener,
  ));
  if (!_workerStarted) {
    _worker();
    _workerStarted = true;
  }
  return completer.future;
}

const _channel = const MethodChannel('lean_file_picker');
const _eventChannel = const EventChannel('lean_file_picker_events');
final _jobController = StreamController<_Job>();
var _workerStarted = false;

class _Job {
  final Completer<File?> completer;
  final List<String>? allowedExtensions;
  final List<String>? allowedMimeTypes;
  final FilePickerListener? listener;

  _Job({
    required this.completer,
    required this.allowedExtensions,
    required this.allowedMimeTypes,
    required this.listener,
  });
}

void _worker() async {
  await for (final job in _jobController.stream) {
    final stream = _eventChannel.receiveBroadcastStream().cast<bool>();
    final subscription = stream.listen((copying) {
      if (job.listener != null && copying) {
        job.listener!.call(FilePickerStatus.copying);
      }
    });

    final path = await _channel.invokeMethod('pickFile', <String, Object?>{
      'allowedExtensions': job.allowedExtensions,
      'allowedMimeTypes': job.allowedMimeTypes,
    });

    await subscription.cancel();
    job.listener?.call(FilePickerStatus.done);

    if (path != null) {
      job.completer.complete(File(path));
    } else {
      job.completer.complete(null);
    }
  }
}
