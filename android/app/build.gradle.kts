plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    // Firebase BoM (manages all Firebase versions)
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    implementation("com.google.ar:core:1.51.0")

    // Firebase Authentication (required)
    implementation("com.google.firebase:firebase-auth")

    // Google Sign-in services (required for Google login)
    implementation("com.google.android.gms:play-services-auth")

    // Optional: Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.example.decormate_android"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.decormate_android"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
