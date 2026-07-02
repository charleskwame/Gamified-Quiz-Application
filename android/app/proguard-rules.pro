# Suppress warnings for optional Play Core split compat classes
# (referenced by Flutter's embedded engine but not used by this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# --- Firebase Auth session-persistence keep rules ---
# Protect Firebase Auth's internal classes so R8 does not strip or obfuscate the
# classes responsible for persisting/restoring the authentication token on disk.
# Without these rules the user is logged out on every cold start or app update.
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.auth.**
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task