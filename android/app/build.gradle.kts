plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Remove this line: id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sqlite_crud_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.sqlite_crud_app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large apps
        multiDexEnabled = true
        
        // Add renderscript support
        renderscriptTargetApi = 21
        renderscriptSupportModeEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // Remove kotlinOptions since you're not using Kotlin
    // kotlinOptions {
    //     jvmTarget = "11"
    // }

    buildTypes {
        getByName("debug") {
            // Optimize debug builds for faster startup
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            
            // Add debug configurations
            manifestPlaceholders["enableOnBackInvokedCallback"] = "true"
        }
        
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // Replace for production
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Add release configurations
            manifestPlaceholders["enableOnBackInvokedCallback"] = "true"
        }
    }

    lint {
        disable += "ObsoleteLintCustomCheck"
        // Disable some lint checks that might cause issues
        disable += "MissingTranslation"
        disable += "ExtraTranslation"
        disable += "UnusedResources"
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }

    // Suppress warnings from all dependencies
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:1.9.0")
        }
    }
    
    // Optimize APK size and performance
    packaging {
        resources {
            excludes.add("META-INF/DEPENDENCIES")
            excludes.add("META-INF/LICENSE")
            excludes.add("META-INF/LICENSE.txt")
            excludes.add("META-INF/license.txt")
            excludes.add("META-INF/NOTICE")
            excludes.add("META-INF/NOTICE.txt")
            excludes.add("META-INF/notice.txt")
            excludes.add("META-INF/ASL2.0")
            excludes.add("META-INF/*.kotlin_module")
        }
    }
    
    // Add aapt options to handle OpenGL ES warnings
    androidResources {
        noCompress += listOf("tflite", "lite")
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~"
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
}