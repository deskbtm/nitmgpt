package com.deskbtm.nitmgpt;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.OpenableColumns;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Picks model files via SAF without copying to cache, then copies on demand to app storage.
 */
public class ModelFilePickerPlugin implements
        MethodChannel.MethodCallHandler,
        PluginRegistry.ActivityResultListener,
        EventChannel.StreamHandler {

    private static final String TAG = "ModelFilePicker";
    private static final String CHANNEL = "com.deskbtm.nitmgpt/model_file";
    private static final String EVENT_CHANNEL = "com.deskbtm.nitmgpt/model_file_progress";
    private static final int PICK_REQUEST_CODE = 44121;
    private static final int COPY_BUFFER_SIZE = 1024 * 1024;

    private final Activity activity;
    private final MethodChannel methodChannel;
    private final EventChannel eventChannel;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    @Nullable
    private MethodChannel.Result pendingPickResult;
    @Nullable
    private EventChannel.EventSink progressSink;

    public static ModelFilePickerPlugin registerWith(
            @NonNull Activity activity,
            @NonNull BinaryMessenger messenger) {
        final ModelFilePickerPlugin plugin = new ModelFilePickerPlugin(activity, messenger);
        plugin.attach();
        return plugin;
    }

    private ModelFilePickerPlugin(@NonNull Activity activity, @NonNull BinaryMessenger messenger) {
        this.activity = activity;
        this.methodChannel = new MethodChannel(messenger, CHANNEL);
        this.eventChannel = new EventChannel(messenger, EVENT_CHANNEL);
    }

    private void attach() {
        methodChannel.setMethodCallHandler(this);
        eventChannel.setStreamHandler(this);
    }

    public void detach() {
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        executor.shutdownNow();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "pickModelFile":
                pickModelFile(result);
                break;
            case "copyModelFile":
                final String uri = call.argument("uri");
                final String fileName = call.argument("fileName");
                if (uri == null || fileName == null) {
                    result.error("invalid_args", "uri and fileName are required", null);
                    return;
                }
                copyModelFile(uri, fileName, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void pickModelFile(@NonNull MethodChannel.Result result) {
        if (pendingPickResult != null) {
            result.error("already_active", "Another file picker is already active", null);
            return;
        }

        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"*/*", "application/octet-stream"});
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        intent.addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);

        pendingPickResult = result;
        activity.startActivityForResult(intent, PICK_REQUEST_CODE);
    }

    private void copyModelFile(@NonNull String uriString, @NonNull String fileName, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                Uri uri = Uri.parse(uriString);
                File destDir = new File(activity.getExternalFilesDir(null), "model_imports");
                if (!destDir.exists() && !destDir.mkdirs()) {
                    failOnMain(result, "io_error", "Failed to create import directory");
                    return;
                }

                File dest = new File(destDir, sanitizeFileName(fileName));
                if (dest.exists() && !dest.delete()) {
                    failOnMain(result, "io_error", "Failed to replace existing import file");
                    return;
                }

                long totalBytes = querySize(uri);
                long copiedBytes = 0;

                try (InputStream input = activity.getContentResolver().openInputStream(uri);
                     BufferedOutputStream output = new BufferedOutputStream(
                             new FileOutputStream(dest), COPY_BUFFER_SIZE)) {
                    if (input == null) {
                        failOnMain(result, "io_error", "Could not open selected file");
                        return;
                    }

                    byte[] buffer = new byte[COPY_BUFFER_SIZE];
                    int read;
                    while ((read = input.read(buffer)) >= 0) {
                        output.write(buffer, 0, read);
                        copiedBytes += read;
                        emitProgress(copiedBytes, totalBytes);
                    }
                    output.flush();
                }

                emitProgress(copiedBytes, totalBytes > 0 ? totalBytes : copiedBytes);
                succeedOnMain(result, dest.getAbsolutePath());
            } catch (Exception e) {
                Log.e(TAG, "copyModelFile failed", e);
                final String message = e.getMessage() == null ? e.toString() : e.getMessage();
                if (message.contains("ENOSPC")) {
                    failOnMain(result, "enospc", "Not enough storage space");
                } else {
                    failOnMain(result, "io_error", message);
                }
            }
        });
    }

    private void emitProgress(long copiedBytes, long totalBytes) {
        if (progressSink == null) {
            return;
        }
        final int progress;
        if (totalBytes > 0) {
            progress = (int) Math.min(100, (copiedBytes * 100) / totalBytes);
        } else {
            progress = 0;
        }
        mainHandler.post(() -> {
            if (progressSink != null) {
                progressSink.success(progress);
            }
        });
    }

    private long querySize(@NonNull Uri uri) {
        try (Cursor cursor = activity.getContentResolver().query(
                uri,
                new String[]{OpenableColumns.SIZE},
                null,
                null,
                null)) {
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndex(OpenableColumns.SIZE);
                if (index >= 0 && !cursor.isNull(index)) {
                    return cursor.getLong(index);
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "Could not query file size", e);
        }
        return 0L;
    }

    @Nullable
    private String queryDisplayName(@NonNull Uri uri) {
        try (Cursor cursor = activity.getContentResolver().query(
                uri,
                new String[]{OpenableColumns.DISPLAY_NAME},
                null,
                null,
                null)) {
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
                if (index >= 0) {
                    return cursor.getString(index);
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "Could not query display name", e);
        }
        return null;
    }

    @NonNull
    private static String sanitizeFileName(@NonNull String fileName) {
        return fileName.replaceAll("[\\\\/]+", "_");
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode != PICK_REQUEST_CODE) {
            return false;
        }

        final MethodChannel.Result result = pendingPickResult;
        pendingPickResult = null;
        if (result == null) {
            return true;
        }

        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            result.success(null);
            return true;
        }

        final Uri uri = data.getData();
        try {
            final int takeFlags = data.getFlags()
                    & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            activity.getContentResolver().takePersistableUriPermission(uri, takeFlags);
        } catch (Exception e) {
            Log.w(TAG, "Persistable URI permission not granted", e);
        }

        final String name = queryDisplayName(uri);
        if (name == null || name.isEmpty()) {
            result.error("invalid_file", "Could not read selected file name", null);
            return true;
        }

        final Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("uri", uri.toString());
        payload.put("size", querySize(uri));
        result.success(payload);
        return true;
    }

    private void succeedOnMain(@NonNull MethodChannel.Result result, @NonNull String path) {
        mainHandler.post(() -> result.success(path));
    }

    private void failOnMain(@NonNull MethodChannel.Result result, @NonNull String code, @NonNull String message) {
        mainHandler.post(() -> result.error(code, message, null));
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        progressSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        progressSink = null;
    }
}
