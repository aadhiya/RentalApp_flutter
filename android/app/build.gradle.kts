plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Kotlin Android plugin
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services") // Google services plugin
}

android {
     namespace = "com.example.rentalapp"
    compileSdk = 36
    ndkVersion = "27.1.12297006"

    defaultConfig {
        applicationId = "com.example.rentalapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            // Using debug signing for development, replace with real config for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
    //implementation("net.java.dev.jna:jna:5.13.0")

    implementation(files("libs/autoreplyprint.aar"))  // Make sure file name matches!
}

repositories {
    flatDir {
        dirs("libs")  // Directory for your AARs
    }
    google()
    mavenCentral()
}

flutter {
    source = "../.."
}
