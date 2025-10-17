plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.yamani_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.yamani_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // يمكن تعديل هذا لاحقًا عند توقيع التطبيق
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // إصلاح محتمل للأذونات وNDK
    ndkVersion = "27.0.12077973"
    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}
