package com.fitpulse.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Fase 6 (widget en tiempo real): servicio en primer plano que mantiene vivo el
 * sensor de pasos del teléfono (TYPE_STEP_COUNTER) aunque la app esté cerrada.
 *
 * Es la única forma que permite Android de seguir recibiendo datos del sensor
 * sin la app en primer plano: un servicio en primer plano con una notificación
 * permanente (el sistema la exige). Cada paso repinta el widget con el conteo
 * REAL del día y comparte su línea base con la app (canal nativo), de modo que
 * app y widget muestran siempre el mismo número. Si el sistema no permite el
 * servicio, la app sigue funcionando y el widget se refresca al abrirla: nunca
 * se finge un dato.
 */
class StepWidgetService : Service(), SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var ultimoPasos = -1
    private var ultimoPintado = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForeground() es obligatorio sí o sí tras startForegroundService();
        // se intenta primero para no dejar el arranque a medias.
        if (!iniciarForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!hayWidgets() || !permisoActividad() || !registrarSensor()) {
            detenerServicio()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    // ---- Requisitos ----

    private fun hayWidgets(): Boolean {
        val manager = AppWidgetManager.getInstance(this)
        return manager.getAppWidgetIds(
            ComponentName(this, HomeWidgetProvider::class.java)
        ).isNotEmpty()
    }

    private fun permisoActividad(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        return checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun iniciarForeground(): Boolean {
        try {
            val manager = getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val canal = NotificationChannel(
                    CANAL,
                    "Pasos en tiempo real",
                    NotificationManager.IMPORTANCE_LOW
                )
                canal.description =
                    "Mantiene el widget de FitPulse al día con tus pasos reales."
                canal.setShowBadge(false)
                manager.createNotificationChannel(canal)
            }
            val pi = PendingIntent.getActivity(
                this, 0, Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val notificacion: Notification =
                Notification.Builder(this, CANAL)
                    .setContentTitle("FitPulse")
                    .setContentText("Contando tus pasos para el widget")
                    .setSmallIcon(R.drawable.ic_stat_fitpulse)
                    .setContentIntent(pi)
                    .setOngoing(true)
                    .setShowWhen(false)
                    .build()
            startForeground(NOTIF_ID, notificacion)
            return true
        } catch (_: Exception) {
            // Tipo de servicio no permitido o notificaciones bloqueadas: la app
            // sigue igual, el widget se refresca al abrirla.
            return false
        }
    }

    private fun registrarSensor(): Boolean {
        val manager = sensorManager ?: getSystemService(SensorManager::class.java)
            .also { sensorManager = it }
        val sensor = stepSensor ?: manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            .also { stepSensor = it }
        if (sensor == null) return false
        return manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    // ---- Sensor ----

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_STEP_COUNTER) return
        val raw = event.values[0].toInt()
        val base = calcularBase(raw)
        val pasos = (raw - base).coerceAtLeast(0)
        val ahora = System.currentTimeMillis()
        // Se repinta como mucho una vez por segundo: suficiente para verse "en
        // vivo" sin castigar la batería con un refresco por cada paso.
        if (pasos != ultimoPasos && ahora - ultimoPintado >= INTERVALO_PINTADO_MS) {
            ultimoPasos = pasos
            ultimoPintado = ahora
            HomeWidgetRenderer.actualizarPasos(this, pasos)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No aplica al contador de pasos.
    }

    /**
     * Línea base compartida con la app: primer contador del día (o el valor tras
     * reiniciar el teléfono). Se persiste en `fitpulse_steps`; la app la adopta
     * por el canal nativo para contar exactamente igual que el widget.
     */
    private fun calcularBase(raw: Int): Int {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val hoy = fechaHoy()
        val fecha = prefs.getString(KEY_FECHA, null)
        val baseGuardada =
            if (prefs.contains(KEY_BASE)) prefs.getInt(KEY_BASE, -1) else null
        if (fecha != hoy || baseGuardada == null || raw < baseGuardada) {
            prefs.edit().putInt(KEY_BASE, raw).putString(KEY_FECHA, hoy).apply()
            return raw
        }
        return baseGuardada
    }

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }

    private fun detenerServicio() {
        sensorManager?.unregisterListener(this)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun fechaHoy(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    companion object {
        private const val CANAL = "fitpulse_pasos"
        private const val NOTIF_ID = 4201
        private const val PREFS = "fitpulse_steps"
        private const val KEY_BASE = "base"
        private const val KEY_FECHA = "fecha"
        private const val INTERVALO_PINTADO_MS = 1000L

        /** Arranca el servicio si hay widgets colocados (idempotente). */
        fun ensureRunning(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, HomeWidgetProvider::class.java)
                )
                if (ids.isEmpty()) return
                context.startForegroundService(
                    Intent(context, StepWidgetService::class.java)
                )
            } catch (_: Exception) {
                // Arranque en segundo plano restringido: se reintenta al abrir
                // la app o al volver a colocar el widget.
            }
        }

        /** Detiene el servicio (p. ej. al quitar el último widget). */
        fun detener(context: Context) {
            try {
                context.stopService(Intent(context, StepWidgetService::class.java))
            } catch (_: Exception) {
            }
        }

        /**
         * Adopta la línea base que publica la app (canal nativo) si es de hoy y
         * más antigua que la propia: así el servicio cuenta igual que la app
         * aunque se haya arrancado más tarde (p. ej. al colocar el widget).
         */
        fun registrarBaseDeLaApp(context: Context, base: Int?, fecha: String?) {
            if (base == null || fecha == null) return
            if (fecha != fechaHoy()) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val propia =
                if (prefs.contains(KEY_BASE)) prefs.getInt(KEY_BASE, -1) else null
            val propiaFecha = prefs.getString(KEY_FECHA, null)
            val reemplazar = propiaFecha != fecha || propia == null || base < propia
            if (reemplazar) {
                prefs.edit().putInt(KEY_BASE, base).putString(KEY_FECHA, fecha).apply()
            }
        }

        private fun fechaHoy(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        /**
         * Base/fecha de pasos que lleva el servicio (`base`, `fecha`), o `null`
         * si todavía no ha contado nada. La app la lee para contar igual.
         */
        fun leerBase(context: Context): Map<String, Any>? {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val fecha = prefs.getString(KEY_FECHA, null) ?: return null
            if (!prefs.contains(KEY_BASE)) return null
            return mapOf("base" to prefs.getInt(KEY_BASE, -1), "fecha" to fecha)
        }
    }
}
