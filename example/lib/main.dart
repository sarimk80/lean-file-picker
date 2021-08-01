import 'package:flutter/material.dart';
import 'package:lean_file_picker/lean_file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _copying = false;
  var _lastPick = 'No file picked';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('File Picker Example'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('Pick File'),
                onPressed: () async {
                  final file = await pickFile(
                    allowedExtensions: ['zip'],
                    allowedMimeTypes: ['image/jpeg', 'text/*'],
                    listener: (status) =>
                        setState(() => _copying = status == FilePickerStatus.copying),
                  );
                  if (file != null) {
                    final path = file.path;
                    final size = file.lengthSync();
                    file.deleteSync();
                    setState(() => _lastPick = 'Picked file $path\nwith a size of $size bytes');
                  } else {
                    setState(() => _lastPick = 'Picker canceled');
                  }
                },
              ),
              if (_copying)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Copying data to temporary file",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              if (!_copying)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _lastPick,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
