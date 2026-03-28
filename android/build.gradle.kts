plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    configurations.configureEach {
        resolutionStrategy.force("com.google.ar:core:1.51.0")
    }

    // Fix namespace for older Flutter plugins that only declare it in AndroidManifest.xml
    project.pluginManager.withPlugin("com.android.library") {
        val android = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.namespace.isNullOrEmpty()) {
            val manifest = project.file("src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val matchResult = Regex("""package="([^"]+)"""").find(manifest.readText())
                if (matchResult != null) {
                    android.namespace = matchResult.groupValues[1]
                }
            }
        }
    }

    // Ensure consistent JVM 17 target across Java and Kotlin for all plugins
    afterEvaluate {
        // Force android compileOptions to Java 17 and compileSdk >= 36 for all plugins  
        project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileSdkVersion(36)
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
