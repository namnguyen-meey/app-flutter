import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("environment")

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "com.example.shopsample.dev"
            resValue(type = "string", name = "app_name", value = "Shop Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationId = "com.example.shopsample.stg"
            resValue(type = "string", name = "app_name", value = "Shop Staging")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.example.shopsample"
            resValue(type = "string", name = "app_name", value = "Shop")
        }
    }

    buildFeatures.resValues = true
}