# R8 / ProGuard rules for Quest Key release builds.
#
# Flutter's own keep rules are added automatically by the Flutter Gradle
# plugin, so nothing Flutter-specific is needed here.
#
# flutter_local_notifications 19.x: per the package README, the GSON keep
# rules the plugin needs are provided automatically by GSON's bundled
# consumer rules ("For flutter_local_notification v19 and higher, the
# ProGuard rules are automatically provided by the GSON"). The rules below
# are belt-and-braces to prevent the classic "notifications silently stop
# working in release" failure if a future plugin/GSON update drops them.
# They are safe to keep even when redundant.

# Keep the plugin's model classes and receivers (serialised with GSON and
# instantiated by the Android system from the manifest).
-keep class com.dexterous.** { *; }

# GSON: keep generic type signatures and TypeToken subclasses
# (from https://github.com/google/gson/blob/main/examples/android-proguard-example/proguard.cfg).
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-dontwarn sun.misc.**

# Desugared java.time types are used by the plugin's scheduling code.
-keep class j$.** { *; }
-dontwarn j$.**

# Keep line numbers so Play Console crash reports stay readable.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
