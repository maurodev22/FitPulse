plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitpulse.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Fase 6: flutter_local_notifications 22.x requiere core library
        // desugaring (APIs Java 8+ en Android). El artefacto se resuelve
        // desde el mirror de Aliyun.
        isCoreLibraryDesugaringEnabled = true
    }

    lint {
        // Release sin lint vital: evita resoluciones de red extra (red local
        // inestable) en un chequeo estático que no afecta al APK final.
        checkReleaseBuilds = false
    }

    defaultConfig {
        // FitPulse: identificador único de la app (dev env).
        applicationId = "com.fitpulse.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk 26: requerido por Health Connect (Fase 1).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Fase 3 "app ligera": R8 (shrinker) + eliminación de recursos sin uso.
            // Reduce el tamaño del APK de release (target ~28-35 MB instalado).
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

dependencies {
    // Fase 6: core library desugaring (ver compileOptions arriba).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Fix Pixel (Fase 8, verificación Android 16/17): flutter_local_notifications
    // 22.x arrastra androidx.work 2.7.0 + androidx.room 2.2.5 (2021), que crashean
    // creando WorkDatabase en Android 17 (SDK 37). Se fuerzan las versiones que
    // Google compila juntas (work 2.9.1 <-> room 2.6.1). Artefactos por Aliyun.
    implementation("androidx.work:work-runtime:2.9.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("androidx.work:work-multiprocess:2.9.1")
    implementation("androidx.room:room-runtime:2.6.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
