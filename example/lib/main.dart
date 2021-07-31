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
  var _lastPick = 'No file picked';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('Pick File'),
                onPressed: () async {
                  final file = await LeanFilePicker.pickFile(allowedExtensions: ['zip']);
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
