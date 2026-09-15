import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (see docs/RELEASE.md). `android/key.properties` is
// git-ignored; when it is absent the release build falls back to the debug
// key so `flutter build apk --release` still works on a fresh clone.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "com.glowingthreads.quest_key"

    // Google Play requires new apps and updates to target Android 16
    // (API 36) from 31 Aug 2026 (developer.android.com/google/play/requirements/target-sdk).
    // compileSdk must be >= targetSdk.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required by flutter_local_notifications (v10+) for scheduled
        // notifications on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.glowingthreads.quest_key"
        // minSdk 21 is the lowest level supported by both
        // flutter_local_notifications (minSdkVersion 21) and flutter_timezone
        // (minSdkVersion 21); it also matches Flutter's own minimum.
        minSdk = 21
        targetSdk = 36
        // Read from pubspec.yaml `version: x.y.z+n` via the Flutter Gradle
        // plugin (versionName = x.y.z, versionCode = n). Never hard-code.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found; signing the release " +
                        "build with the debug key. See docs/RELEASE.md before uploading to Play."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            // R8 code shrinking + resource shrinking. Keep rules live in
            // proguard-rules.pro and res/raw/keep.xml.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring library version recommended by the flutter_local_notifications README.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
