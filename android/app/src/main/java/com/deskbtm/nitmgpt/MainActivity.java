package com.deskbtm.nitmgpt;

import android.content.Intent;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private ModelFilePickerPlugin modelFilePickerPlugin;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        modelFilePickerPlugin = ModelFilePickerPlugin.registerWith(
                this,
                flutterEngine.getDartExecutor().getBinaryMessenger()
        );
        DevicePlugin.registerWith(flutterEngine.getDartExecutor().getBinaryMessenger());
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (modelFilePickerPlugin != null
                && modelFilePickerPlugin.onActivityResult(requestCode, resultCode, data)) {
            return;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onDestroy() {
        if (modelFilePickerPlugin != null) {
            modelFilePickerPlugin.detach();
            modelFilePickerPlugin = null;
        }
        super.onDestroy();
    }
}
