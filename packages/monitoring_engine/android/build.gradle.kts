group = "com.juanrueda.monitoring_engine"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.juanrueda.monitoring_engine"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        // VIG-003: alineado con el minSdk 26 candidato de la app.
        minSdk = 26
        // Fase 5B: prueba instrumentada con el modelo real, y reglas de R8
        // para MediaPipe en la app release.
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    sourceSets {
        getByName("androidTest") {
            java.srcDirs("src/androidTest/kotlin")
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// Fase 5A: versiones exactas, sin rangos dinámicos (Área 04 §2). CameraX
// 1.6.2 es la última estable de Google Maven (2026-08-26); casos Preview y,
// desde la fase 5B, ImageAnalysis. Las corrutinas las exige el código que genera Pigeon 29.
val cameraxVersion = "1.6.2"

// Fase 5B: MediaPipe Tasks Vision (Face Landmarker), versión exacta. 1.0.0 es
// la estable de 2026-07-28 en Google Maven; no se usa `latest.release` del
// ejemplo oficial. minSdk 24 en su AAR (compatible con 26); bibliotecas
// nativas alineadas a 16 KB. La 1.1.0 (2026-10-06) se descartó por reciente y
// por añadir `litertlm-android`. El modelo va en assets (vigia_models/).
val mediapipeTasksVersion = "1.0.0"

dependencies {
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("com.google.mediapipe:tasks-vision:$mediapipeTasksVersion")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("junit:junit:4.13.2")
}
