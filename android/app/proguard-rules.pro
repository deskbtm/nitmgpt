#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class androidx.lifecycle.** { *; }

# Optional Play Core / deferred components (Flutter embedding references)
-dontwarn com.google.android.play.core.**

# Optional MediaPipe proto / auto-value stubs referenced at compile time
-dontwarn com.google.auto.value.extension.memoized.Memoized
-dontwarn com.google.mediapipe.proto.**