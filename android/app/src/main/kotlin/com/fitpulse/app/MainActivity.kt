package com.fitpulse.app

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
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
        // Fase 8.3: consentimiento publicitario UE (UMP) vía canal nativo
        // (flutter_ump/pub.dev no llega desde Cuba). El SDK UMP 4.0.0 lo trae
        // google_mobile_ads como dependencia `implementation` de su plugin
        // (runtime sí, pero no al compilador), por eso también se declara en
        // android/app/build.gradle.kts con la misma versión 4.0.0.
        // En UMP 4.0.0 la API cambió: ConsentInformation.getInstance(...) y
        // ConsentForm.loadAndShowConsentFormIfRequired(...) ya NO existen; todo
        // pasa por UserMessagingPlatform. Si el SDK no soporta dispositivo/red,
        // cada método devuelve una respuesta honesta y la app degrada a "sin
        // anuncios".
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fitpulse/consent"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "request" -> requestConsentInfo(result)
                "canRequestAds" -> result.success(
                    UserMessagingPlatform.getConsentInformation(this)
                        .canRequestAds()
                )
                "loadAndShowIfRequired" -> UserMessagingPlatform
                    .loadAndShowConsentFormIfRequired(this) { error ->
                        // error == null => formulario mostrado (o no requerido).
                        result.success(error == null)
                    }
                "reset" -> {
                    UserMessagingPlatform.getConsentInformation(this).reset()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestConsentInfo(result: MethodChannel.Result) {
        val consentInformation =
            UserMessagingPlatform.getConsentInformation(this)
        consentInformation.requestConsentInfoUpdate(
            this,
            ConsentRequestParameters.Builder().build(),
            {
                result.success(
                    mapOf(
                        "ok" to true,
                        "canRequestAds" to consentInformation.canRequestAds(),
                        "status" to consentStatusName(
                            consentInformation.consentStatus
                        )
                    )
                )
            },
            { error ->
                // Fallo técnico/red (p. ej. sin red a Google): la app no muestra
                // anuncios reales (degradado honesto).
                result.success(
                    mapOf(
                        "ok" to false,
                        "code" to error.errorCode,
                        "message" to error.message
                    )
                )
            }
        )
    }

    /** Nombre textual del estado UMP como espera el Dart (ConsentService). */
    private fun consentStatusName(status: Int): String = when (status) {
        ConsentInformation.ConsentStatus.OBTAINED -> "OBTAINED"
        ConsentInformation.ConsentStatus.REQUIRED -> "REQUIRED"
        ConsentInformation.ConsentStatus.NOT_REQUIRED -> "NOT_REQUIRED"
        else -> "UNKNOWN"
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