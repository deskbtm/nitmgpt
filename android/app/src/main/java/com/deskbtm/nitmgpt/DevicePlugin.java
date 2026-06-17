package com.deskbtm.nitmgpt;

import android.os.Build;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Exposes lightweight device capability checks to Dart.
 */
public class DevicePlugin implements MethodChannel.MethodCallHandler {

    private static final String CHANNEL = "com.deskbtm.nitmgpt/device";

    public static void registerWith(BinaryMessenger messenger) {
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler(new DevicePlugin());
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if ("isEmulator".equals(call.method)) {
            result.success(isEmulator());
            return;
        }
        result.notImplemented();
    }

    static boolean isEmulator() {
        final String fingerprint = Build.FINGERPRINT;
        final String model = Build.MODEL;
        final String manufacturer = Build.MANUFACTURER;
        final String brand = Build.BRAND;
        final String device = Build.DEVICE;
        final String product = Build.PRODUCT;
        final String hardware = Build.HARDWARE;

        return fingerprint.startsWith("generic")
                || fingerprint.startsWith("unknown")
                || model.contains("google_sdk")
                || model.contains("Emulator")
                || model.contains("Android SDK built for x86")
                || model.contains("sdk_gphone")
                || manufacturer.contains("Genymotion")
                || (brand.startsWith("generic") && device.startsWith("generic"))
                || "google_sdk".equals(product)
                || product.contains("sdk_gphone")
                || product.contains("emulator")
                || product.contains("simulator")
                || hardware.contains("ranchu")
                || hardware.contains("goldfish");
    }
}
