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