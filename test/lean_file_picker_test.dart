import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_file_picker/lean_file_picker.dart';

void main() {
  const MethodChannel channel = MethodChannel('lean_file_picker');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '/a/file';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('pickFile', () async {
    expect((await LeanFilePicker.pickFile())?.path, '/a/file');
  });
}
