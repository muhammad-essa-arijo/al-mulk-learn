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
}
// Some plugins (like file_picker) are built for an older Android version (34)
// but a newer library needs 36. Here we tell every plugin to compile against 36.
// This only changes how the plugins are built, not how the app behaves.
subprojects {
    if (name != "app") {
        afterEvaluate {
            extensions.findByName("android")?.withGroovyBuilder {
                "setCompileSdk"(36)
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
