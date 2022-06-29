package ch.perron2.lean_file_picker;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import android.util.Log;
import android.webkit.MimeTypeMap;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class LeanFilePickerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private static final String TAG = LeanFilePickerPlugin.class.getSimpleName();
    // Random number to prevent clashes with other plugins because Flutter does
    // not (yet) provide a mechanism to cleanly allocate unique request codes
    // for calls to startActivityForResult().
    private static final int REQUEST_OPEN_DOCUMENT = 487314648;

    private MethodChannel channel;
    private EventChannel.EventSink eventSink;
    private Activity activity;
    private Result result;
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "lean_file_picker");
        channel.setMethodCallHandler(this);
        EventChannel eventChannel = new EventChannel(
            flutterPluginBinding.getBinaryMessenger(), "lean_file_picker_events");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                LeanFilePickerPlugin.this.eventSink = events;
            }
    
            @Override
            public void onCancel(Object arguments) {
                LeanFilePickerPlugin.this.eventSink = null;
            }
        });
    }
    
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        this.result = result;
        if (call.method.equals("pickFile")) {
            List<String> extensions = call.argument("allowedExtensions");
            if (extensions == null) {
                extensions = Collections.emptyList();
            }
            List<String> mimeTypes = call.argument("allowedMimeTypes");
            if (mimeTypes == null) {
                mimeTypes = Collections.emptyList();
            }
            pickFile(extensions, mimeTypes);
        } else {
            result.notImplemented();
        }
    }
    
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
    
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }
    
    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }
    
    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }
    
    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
    
    private void pickFile(List<String> extensions, List<String> mimeTypes) {
        List<String> allMimeTypes = new ArrayList<>(extensions.size() + mimeTypes.size());
        allMimeTypes.addAll(mimeTypes);
        for (String extension : extensions) {
            String mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
            if (mimeType != null) {
                allMimeTypes.add(mimeType);
            }
        }
    
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        if (!allMimeTypes.isEmpty()) {
            intent.putExtra(Intent.EXTRA_MIME_TYPES, allMimeTypes.toArray(new String[0]));
        }
    
        activity.startActivityForResult(intent, REQUEST_OPEN_DOCUMENT);
    }
    
    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_OPEN_DOCUMENT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                final Uri documentUri = data.getData();
                if (documentUri != null) {
                    String name = queryFileName(activity.getContentResolver(), documentUri);
                    File cacheDir = activity.getCacheDir();
                    final File outputFile = new File(cacheDir, name);
                    eventSink.success(true);
                    //Threads reverted to runnable anon classes in place of Lamda's
                    new Thread(new Runnable() {
                        @Override
                        public void run(){
                            final boolean success = copyFile(documentUri, outputFile);
                            activity.runOnUiThread(new Runnable() {
                                @Override
                                        public void run(){
                                    eventSink.success(false);
                                    if (success) {
                                        result.success(outputFile.toString());
                                    } else {
                                        result.success(null);
                                    }
                                }
    
                            });
                        }
                    }).start();
                    return true;
                }
            }
            result.success(null);
            return true;
        }
        return false;
    }
    
    private String queryFileName(ContentResolver resolver, Uri uri) {
        Cursor returnCursor = resolver.query(uri, null, null, null, null);
        if (returnCursor != null) {
            int nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
            returnCursor.moveToFirst();
            String name = returnCursor.getString(nameIndex);
            returnCursor.close();
            return name;
        }
        return uri.getLastPathSegment();
    }
    
    private boolean copyFile(Uri sourceUri, File targetFile) {
        try (InputStream stream = activity.getContentResolver().openInputStream(sourceUri)) {
            try (FileOutputStream outStream = new FileOutputStream(targetFile)) {
                byte[] buffer = new byte[16 * 1024];
                int bytesRead;
                while ((bytesRead = stream.read(buffer)) != -1) {
                    outStream.write(buffer, 0, bytesRead);
                }
            }
            return true;
        } catch (Exception ex) {
            Log.d(TAG, "Cannot copy selected file", ex);
        }
        return false;
    }
}
