# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Embedding
-keep class io.flutter.embedding.** { *; }

# Flutter Plugins (общие правила)
-keep class com.google.** { *; }
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# audioplayers
-keep class com.ryanheise.audioplayers.** { *; }
-keep class com.ryanheise.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# vibration (если вдруг вернёшь)
-keep class com.benjaminabel.vibration.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# provider
-keep class com.example.provider.** { *; }

# Общие правила
-keepattributes *Annotation*
-keepattributes Signature
-keep class * extends java.lang.annotation.Annotation { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers class **.R$* {
    public static <fields>;
}
# 🔹 ИГНОРИРУЕМ отсутствующие классы Google Play Core
# (нужны только для Google Play Feature Delivery, не для RuStore)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# 🔹 Разрешаем ссылки на эти классы без ошибок
-keepattributes Signature, RuntimeVisibleAnnotations, AnnotationDefault