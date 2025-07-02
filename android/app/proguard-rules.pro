# Keep NFC related classes
-keep class com.example.sqlite_crud_app.MainActivity { *; }

# Keep NFC classes
-keep class android.nfc.** { *; }
-keep class android.nfc.tech.** { *; }

# Keep Flutter method channel classes
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$** { *; }

# Keep method channel handler methods
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$** *;
}

# Don't warn about missing classes
-dontwarn android.nfc.**