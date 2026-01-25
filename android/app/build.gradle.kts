import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // id("kotlin-android") //
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.schedule_app"
    compileSdk = 36
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zongzi.schedule"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 34  // Android 14
        targetSdk = 36  // Android 16
        versionCode = 10002203
        versionName = "2.2.3"
        
        // 移除abiFilters，使用splits进行ABI拆分
    }

    signingConfigs {
        create("release") {
            // 签名配置从key.properties读取
            // 如果文件不存在，则跳过签名配置
            try {
                val keyPropertiesFile = rootProject.file("key.properties")
                if (keyPropertiesFile.exists()) {
                    val keyProperties = Properties()
                    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
                    
                    storeFile = file(keyProperties["storeFile"] as String)
                    storePassword = keyProperties["storePassword"] as String
                    keyAlias = keyProperties["keyAlias"] as String
                    keyPassword = keyProperties["keyPassword"] as String
                }
            } catch (e: Exception) {
                println("Warning: Could not load signing config: ${e.message}")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // 启用代码混淆和压缩
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    // 配置ABI拆分，只生成arm64-v8a
    //splits {
    //    //abi {
    //        //isEnable = true
    //        //reset()
    //       //include("arm64-v8a")
    //        //isUniversalApk = false
    //    }
    //}
    
    packaging {
        jniLibs {
            pickFirsts += setOf(
                "**/libflutter.so",
                "**/libc++_shared.so"
            )
        }
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    jvmToolchain(21) 
}
