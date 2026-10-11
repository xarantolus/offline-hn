import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val releaseStorePath: String? =
    keystoreProperties.getProperty("storeFile") ?: System.getenv("X_KEYSTORE_PATH")

android {
    namespace = "io.github.xarantolus.offlinehn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        // Only configured when signing material is present, so debug builds
        // work without a keystore.
        if (releaseStorePath != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(releaseStorePath)
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "io.github.xarantolus.offlinehn"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-dev"
            manifestPlaceholders["applicationLabel"] = "Hacker News (debug)"
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            manifestPlaceholders["applicationLabel"] = "Hacker News"
            signingConfig =
                if (releaseStorePath != null) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
        getByName("profile") {
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-profile"
            manifestPlaceholders["applicationLabel"] = "Hacker News (profile)"
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // The time-change receiver enqueues the plugin's own worker, which needs
    // the same library the plugin uses; Gradle resolves to the higher version.
    implementation("androidx.work:work-runtime:2.11.2")
}

flutter {
    source = "../.."
}
