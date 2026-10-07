import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Fase 3: la app DEMO es otra aplicación Android. Se deriva de la misma
// definición que lee Dart (`--dart-define=VIGIA_DEMO=true`), que Flutter pasa a
// Gradle en la propiedad `dart-defines` (cada entrada en Base64). Así no puede
// compilarse el recorrido simulado con el applicationId de la app normal ni al
// revés: sus datos (vigia_history_demo_v1.sqlite) quedan en otro almacén.
val vigiaDartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotEmpty() }
        ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        ?.associate { entry ->
            val i = entry.indexOf('=')
            if (i < 0) entry to "" else entry.substring(0, i) to entry.substring(i + 1)
        }
        ?: emptyMap()
val vigiaDemo: Boolean =
    when (val value = vigiaDartDefines["VIGIA_DEMO"]) {
        null, "", "false" -> false
        "true" -> true
        else -> throw GradleException("VIGIA_DEMO=$value no admitido; usa true o false")
    }

android {
    namespace = "com.juanrueda.vigia"
    // VIG-003: fijado explícitamente (Área 07 §14: target ≥ 36). Plantilla Flutter 3.47.6 = 36.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // App normal: com.juanrueda.vigia («Vigía»). Recorrido DEMO:
        // com.juanrueda.vigia.demo («Vigía DEMO»), instalable junto a la normal.
        applicationId = if (vigiaDemo) "com.juanrueda.vigia.demo" else "com.juanrueda.vigia"
        manifestPlaceholders["appLabel"] = if (vigiaDemo) "Vigía DEMO" else "Vigía"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // VIG-003: minSdk 26 es candidato (Área 04 §2, Área 07 §5); la plantilla usa 24.
        minSdk = 26
        targetSdk = 36
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
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
