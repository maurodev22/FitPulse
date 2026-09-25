package com.fitpulse.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

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

    private fun llenar(views: RemoteViews, snapshot: String?) {
        if (snapshot == null) {
            views.setTextViewText(R.id.w_pasos, "—")
            views.setTextViewText(R.id.w_calorias, "—")
            views.setTextViewText(R.id.w_racha, "—")
            return
        }
        try {
            val o = JSONObject(snapshot)
            views.setTextViewText(R.id.w_pasos, o.optInt("pasos").toString())
            val cal = o.opt("calorias")
            views.setTextViewText(
                R.id.w_calorias,
                if (cal == null || cal == JSONObject.NULL) "—" else cal.toString()
            )
            views.setTextViewText(R.id.w_racha, "${o.optInt("racha")} d")
        } catch (_: Exception) {
            views.setTextViewText(R.id.w_pasos, "—")
            views.setTextViewText(R.id.w_calorias, "—")
            views.setTextViewText(R.id.w_racha, "—")
        }
    }
}

/** Widget de home (Fase 6): pasos, calorías y racha reales. */
class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        HomeWidgetRenderer.aplicar(context, appWidgetManager, appWidgetIds)
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