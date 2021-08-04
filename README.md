# Lean File Picker

![Pub Version](https://img.shields.io/pub/v/lean_file_picker)

Pick a single file using the native file explorer.

## Motivation

Why do we need another file picker for Flutter if there is already a plugin
for file selection available? The existing [`file_picker`](1) plugin
has two serious problems on iOS:

- The [`file_picker`](1) plugin requires you to build your Flutter app with
  frameworks ([`use_frameworks!`](2)) instead of using static linking. This
  results in substantially larger binaries.
- The [`file_picker`](1) plugin has a considerable list of large dependencies
  (DKImagePickerController, DKPhotoGallery, SDWebImage, SwiftyGif) that yet
  again increase your binary size.

By using `lean_file_picker` instead of [`file_picker`](1) I managed to reduce
the installation size of an app from 81.3 MB to 31.3 MB — a reduction of 50 MB
or more than 60%!

If the native file explorer behavior on Android and iOS is sufficient for your
needs then replace [`file_picker`](1) with `lean_file_picker` for a much
reduced installation size and memory consumption (especially on iOS).

[1]: https://pub.dev/packages/file_picker
[2]: https://guides.cocoapods.org/syntax/podfile.html#use_frameworks_bang

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
