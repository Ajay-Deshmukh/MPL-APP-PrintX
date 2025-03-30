plugins {
    id("com.android.application")

    // Add Google Services Plugin for Firebase
    id("com.google.gms.google-services") version "4.4.2" apply false
}

android {
    namespace = "com.example.printxapp"
    compileSdk = 34

    defaultConfig {
        ndkVersion = "29.0.13113456"
        applicationId = "com.example.printxapp"
        minSdk = 23
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    // Correcting sourceSets to point to the right directory
    sourceSets {
        named("main") {
            manifest.srcFile("./app/src/main/AndroidManifest.xml") // Ensure this path is relative to the 'app' folder.
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")

    // Import Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))

    // Firebase dependencies (Analytics, Auth, Firestore, etc.)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}
