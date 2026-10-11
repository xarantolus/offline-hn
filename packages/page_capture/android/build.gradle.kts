group = "io.github.xarantolus.page_capture"
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

val rustDir = layout.projectDirectory.dir("../rust")

val rustAbis = when (val platforms = findProperty("target-platform") as String?) {
    null -> listOf("arm64-v8a", "armeabi-v7a", "x86_64")
    else -> platforms.split(',').mapNotNull {
        when (it.trim()) {
            "android-arm64" -> "arm64-v8a"
            "android-arm" -> "armeabi-v7a"
            "android-x64" -> "x86_64"
            else -> null
        }
    }
}

android {
    namespace = "io.github.xarantolus.page_capture"

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
        minSdk = 24
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.browser:browser:1.9.0")
    implementation("androidx.core:core:1.17.0")
    implementation("androidx.webkit:webkit:1.17.1")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.junit.jupiter:junit-jupiter:5.13.4")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher:1.13.4")
}

androidComponents {
    onVariants { variant ->
        val name = variant.name.replaceFirstChar { it.uppercase() }
        val release = variant.buildType != "debug"
        val output = layout.buildDirectory.dir("rustJniLibs/${variant.name}")
        val cargoBin = File(System.getenv("CARGO_HOME") ?: "${System.getProperty("user.home")}/.cargo", "bin")
        val build = tasks.register<Exec>("buildRust$name") {
            inputs.files(fileTree(rustDir) { include("Cargo.toml", "Cargo.lock", "src/**") })
            inputs.property("abis", rustAbis)
            inputs.property("release", release)
            outputs.dir(output)
            workingDir = rustDir.asFile
            environment("PATH", "${cargoBin}${File.pathSeparator}${System.getenv("PATH")}")
            doFirst {
                environment("ANDROID_NDK_HOME", android.ndkDirectory.absolutePath)
            }
            commandLine(
                listOf("cargo", "ndk") + rustAbis.flatMap { listOf("-t", it) } +
                    listOf("-o", output.get().asFile.absolutePath, "build", "--locked") +
                    if (release) listOf("--release") else emptyList(),
            )
        }
        variant.sources.jniLibs?.addStaticSourceDirectory(output.get().asFile.absolutePath)
        tasks.matching { it.name == "pre${name}Build" }.configureEach { dependsOn(build) }
    }
}
