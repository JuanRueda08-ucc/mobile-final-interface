import java.util.Base64
import java.util.Properties

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
val vigiaFirebase = when (val value = vigiaDartDefines["VIGIA_FIREBASE"]) {
    null, "", "false" -> false
    "true" -> true
    else -> throw GradleException("VIGIA_FIREBASE=$value no admitido; usa true o false")
}
if (vigiaFirebase) {
    if (vigiaDemo || !vigiaDartDefines["VIGIA_DEMO_INICIO"].isNullOrEmpty()) {
        throw GradleException("Firebase solo está disponible en la variante normal de Vigía")
    }
    for (key in listOf("API_KEY", "APP_ID", "SENDER_ID", "PROJECT_ID")) {
        if (vigiaDartDefines["VIGIA_FIREBASE_$key"].isNullOrBlank()) {
            throw GradleException("Falta VIGIA_FIREBASE_$key en la configuración del APK")
        }
    }
}
val releaseKeyFile = rootProject.file("key.properties")
val releaseKeys = Properties()
if (releaseKeyFile.isFile) {
    releaseKeyFile.inputStream().use { releaseKeys.load(it) }
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

    // Fase 5B: la DEMO no ejecuta el modelo facial. Su APK no lleva el modelo
    // (assets/vigia_models) ni la biblioteca nativa de MediaPipe; sin ellos no
    // puede cargarse aunque el código del plugin esté presente.
    if (vigiaDemo) {
        androidResources {
            ignoreAssetsPatterns += "<dir>vigia_models"
        }
        packaging {
            jniLibs.excludes += "**/libmediapipe_tasks_jni.so"
        }
    }

    signingConfigs {
        if (vigiaFirebase && releaseKeyFile.isFile) {
            create("vigiaRelease") {
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("vigiaRelease")
                ?: signingConfigs.getByName("debug")
        }
    }
}

// Fase 5A: el permiso CAMERA solo existe en la app normal
// (src/normal/AndroidManifest.xml). La DEMO añade src/demo/AndroidManifest.xml,
// que retira el servicio interno de CameraX: no declara ni solicita la cámara
// (se comprueba en los manifiestos finales de ambos APK).
androidComponents {
    onVariants { variant ->
        variant.sources.manifests.addStaticManifestFile(
            if (vigiaDemo) "src/demo/AndroidManifest.xml" else "src/normal/AndroidManifest.xml",
        )
        if (vigiaFirebase) {
            variant.sources.manifests.addStaticManifestFile("src/cloud/AndroidManifest.xml")
        } else {
            variant.sources.manifests.addStaticManifestFile("src/offline/AndroidManifest.xml")
            if (variant.buildType == "release") {
                variant.sources.manifests.addStaticManifestFile("src/offlineRelease/AndroidManifest.xml")
            }
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
