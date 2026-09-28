# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }

# Google Play Core (required for App Bundle)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Firebase (Core, Messaging) — payloads FCM et classes de config lues par
# réflexion.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# mobile_scanner (scan QR/carte) embarque ML Kit Barcode Scanning.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# image_cropper embarque uCrop.
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# webview_flutter (paiement)
-keep class android.webkit.** { *; }

# flutter_local_notifications déclare ses receivers/services dans le
# manifest ; R8 peut retirer leurs constructeurs sans référence Java directe.
-keep class com.dexterous.** { *; }

# camera (scanner de carte)
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# androidx.startup : initialise Firebase et d'autres libs via des classes
# déclarées en meta-data dans le Manifest (androidx.startup.InitializationProvider),
# donc invisibles pour R8 — sans ce keep, leurs constructeurs sans argument
# peuvent être supprimés silencieusement.
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer

-dontwarn androidx.**
-dontwarn com.google.android.gms.**
