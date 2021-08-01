# Lean File Picker

Pick a single file using the native file explorer.

## Usage

```dart
import 'package:lean_file_picker/lean_file_picker.dart';
final file = await pickFile(
  allowedExtensions: ['zip'],
  allowedMimeTypes: ['image/jpeg', 'text/*'],
);
if (file != null) {
  print(file.path);
}
```

If the user selects a large file or if the selected file is stored on a virtual
file system such as OneDrive or iCloud, copying the file to a temporary
location might take a while. To inform the user about the file being copied,
e.g. by displaying a progress dialog, you can add a listener to the
`pickFile()` function call:

```dart
import 'package:lean_file_picker/lean_file_picker.dart';
final file = await pickFile(
  listener: (status) {
    if (status == FilePickerStatus.copying) {
      print('Selected file is being copied to a temporary location…');
    } else {
      print('Copy process has completed.');
    }
  },
);
```

Because on iOS the operating system automatically copies the selected file
to a temporary location and does so inside the native file explorer UI, the
selected file is always ready when the file explorer returns to the Flutter
app. Therefore the aforementioned listener is never called on iOS.
