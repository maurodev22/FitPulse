package com.fitpulse.app

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Fase 5: permiso de cámara para el entrenador de postura (ML Kit on-device).
        // Se resuelve con las APIs de framework (minSdk 26): sin dependencias extra.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fitpulse/permissions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCameraPermission" -> requestCameraPermission(result)
                "openAppSettings" -> {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // Fase 6: el widget de home recibe el snapshot (pasos, calorías, racha)
        // y se repinta al instante.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fitpulse/home_widget"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "actualizar" -> {
                    val datos = call.argument<String>("datos") ?: ""
                    HomeWidgetRenderer.guardar(this, datos)
                    HomeWidgetProvider.forzarActualizacion(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingCameraResult = result
        requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA)
        // Si el permiso se denegó permanentemente, el sistema entrega la
        // respuesta igualmente en onRequestPermissionsResult (false).
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCameraResult?.success(granted)
            pendingCameraResult = null
        }
    }

    companion object {
        private const val REQUEST_CAMERA = 3001
    }
}