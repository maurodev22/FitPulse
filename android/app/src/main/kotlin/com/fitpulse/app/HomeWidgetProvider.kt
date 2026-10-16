package com.fitpulse.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Locale

/** Guarda el snapshot y pinta el widget de home con datos REALES de la app. */
object HomeWidgetRenderer {
    private const val PREFS = "fitpulse_home_widget"
    private const val KEY = "datos"

    fun guardar(context: Context, datos: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, datos).apply()
    }

    /** Actualiza todas las instancias colocadas del widget con el último snapshot. */
    fun aplicar(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if (ids.isEmpty()) return
        val snapshot = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null)
        val views = RemoteViews(context.packageName, R.layout.home_widget_layout)
        llenar(views, snapshot)
        val pi = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.w_root, pi)
        manager.updateAppWidget(ids, views)
    }

    /**
     * Fase 6 (tiempo real): el servicio de pasos escribe en el snapshot el
     * conteo del día (misma línea base que la app) y repinta. Así el widget
     * avanza paso a paso aunque la app esté cerrada, sin esperar a Flutter.
     * Si todavía no hay snapshot (sesión sin iniciar) no hace nada: el widget
     * sigue mostrando "—", nunca un dato inventado.
     */
    fun actualizarPasos(context: Context, pasos: Int) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val snapshot = prefs.getString(KEY, null) ?: return
        try {
            val o = JSONObject(snapshot)
            if (o.optInt("pasos", -1) == pasos) return
            o.put("pasos", pasos)
            prefs.edit().putString(KEY, o.toString()).apply()
            HomeWidgetProvider.forzarActualizacion(context)
        } catch (_: Exception) {
            // Snapshot ilegible: se deja como está (nunca se inventa un dato).
        }
    }

    private fun llenar(views: RemoteViews, snapshot: String?) {
        if (snapshot == null) {
            mostrarVacio(views)
            return
        }
        try {
            val o = JSONObject(snapshot)
            views.setTextViewText(R.id.w_pasos, o.optInt("pasos").toString())
            // Agua de hoy (litros) o "—" si no hay ningún dato real.
            val agua = o.opt("agua")
            views.setTextViewText(
                R.id.w_subtitulo,
                if (agua == null || agua == JSONObject.NULL) "—"
                else String.format(Locale.US, "%.1f L", (agua as Number).toDouble())
            )
            // BPM de hoy (Health Connect) o "—" si no hay dato real.
            val bpm = o.opt("bpm")
            views.setTextViewText(
                R.id.w_bpm,
                if (bpm == null || bpm == JSONObject.NULL) "—" else bpm.toString()
            )
            views.setTextViewText(R.id.w_racha, "${o.optInt("racha")} d")
        } catch (_: Exception) {
            mostrarVacio(views)
        }
    }

    private fun mostrarVacio(views: RemoteViews) {
        views.setTextViewText(R.id.w_subtitulo, "—")
        views.setTextViewText(R.id.w_pasos, "—")
        views.setTextViewText(R.id.w_bpm, "—")
        views.setTextViewText(R.id.w_racha, "—")
    }
}

/** Widget de home (Fase 6): agua, pasos, BPM y racha reales. */
class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        HomeWidgetRenderer.aplicar(context, appWidgetManager, appWidgetIds)
        // Al colocar el widget se asegura el servicio de pasos en vivo (si el
        // sistema lo permite desde este contexto).
        StepWidgetService.ensureRunning(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val manager = AppWidgetManager.getInstance(context)
        val vivos = manager.getAppWidgetIds(
            ComponentName(context, HomeWidgetProvider::class.java)
        )
        // Sin widgets colocados, el servicio de pasos deja de tener sentido.
        if (vivos.isEmpty()) StepWidgetService.detener(context)
    }

    companion object {
        /** Pide a todos los widgets colocados que se repinten con el último dato. */
        fun forzarActualizacion(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, HomeWidgetProvider::class.java)
            )
            HomeWidgetRenderer.aplicar(context, manager, ids)
        }
    }
}
