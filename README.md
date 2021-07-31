# Lean File Picker

Pick a single file using the native file explorer.

## Getting Started

```dart
import 'package:lean_file_picker/lean_file_picker.dart';

final FilePicker picker = FilePicker();
final file = await picker.pickFile(
  allowedExtensions: ['zip'],
);
if (file != null) {
  print(file.path);
}
```
