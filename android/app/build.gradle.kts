// Force bypass of NDK check
project.extra.set("android.dir", "D:/TaskHive/android")
project.extra.set("android.ndkDirectory", "")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.taskhive"
    // Hard-coded to 34 for modern compatibility
    compileSdk = 35 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.taskhive"
        
        // 🚀 CRITICAL FIX: Hard-coded for compatibility
        minSdk = 21        // Supports almost all phones
        targetSdk = 35     // Optimized for modern Android (including your Android 12)
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}