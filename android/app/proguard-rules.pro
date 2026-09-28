# =====================================================================
# FitPulse — reglas R8/ProGuard (solo aplican al build de RELEASE).
# El gradle plugin de Flutter ya añade este archivo automáticamente
# cuando existe ("flutter_proguard_rules.pro" + proguard-android-optimize).
# =====================================================================

# ---------------------------------------------------------------------
# Room + WorkManager (crash de arranque en release):
# Las clases *_Impl (p. ej. androidx.work.impl.WorkDatabase_Impl) las genera
# Room CON el build y luego se instancian SOLO por reflexión
# (Room.getGeneratedImplementation: Class.forName + getDeclaredConstructor).
# R8 no ve la reflexión, considera el constructor "sin uso" y lo elimina,
# provocando en el arranque:
#   NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> []
# (El debug no lo pilla: no hay minificación. Solo pasa en release/APK).
# Se conservan la clase entera y todos sus miembros.
# ---------------------------------------------------------------------
-keep class * extends androidx.room.RoomDatabase {
    <init>();
    <methods>;
    <fields>;
}

# ---------------------------------------------------------------------
# ML Kit Pose Detection (fallo del entrenador con cámara en release):
# El detector de pose fallaba en release con
#   PlatformException code=InputImageConverterError
#   NullPointerException: ... 'getClass()' on a null object reference
# El bug REAL: R8 eliminaba el constructor sin args de los registrars de
# ML Kit (com.google.mlkit.* / com.google.firebase.components). ML Kit los
# instancia por réflexion (ComponentDiscovery + meta-data android:name="com.google.firebase.components:..."),
# y sin ese <init>() el logcat del Pixel mostraba:
#   W ComponentDiscovery: Could not instantiate com.google.mlkit.vision.pose.internal.PoseRegistrar
#   Caused by: java.lang.NoSuchMethodException: ...PoseRegistrar.<init> []
# Resultado: MlKitContext.get(SharedPrefManager.class) devuelve null y el
# trazado interno (zzmj.<init>) revienta en CADA InputImage convertido.
# (El debug no lo pilla: no hay minificación. Solo pasa en release/APK.)
# Se conservan: las clases de ML Kit/Firebase Components y el constructor
# de cada ComponentRegistrar (cargados por reflexión vía meta-data).
# ---------------------------------------------------------------------
-keep class com.google.mlkit.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep class * extends com.google.firebase.components.ComponentRegistrar {
    <init>();
}
-dontwarn com.google.mlkit.**