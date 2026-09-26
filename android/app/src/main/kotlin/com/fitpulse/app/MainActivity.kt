package com.fitpulse.app

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import com.google.android.ump.ConsentForm
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
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
        // Fase 8.3: consentimiento publicitario UE (UMP). El SDK de UMP ya
        // viene embebido en play-services-ads (25.4.0), así que no hace falta
        // ninguna dependencia nueva (pub.dev/google_ump no llega desde Cuba).
        // Si el SDK UMP no soporta el dispositivo/red, cada método devuelve una
        // respuesta honesta y la app degrada a "sin anuncios".
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "fitpulse/consent"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "request" -> requestConsentInfo(result)
                "canRequestAds" -> result.success(
                    ConsentInformation.getInstance(this).canRequestAds
                )
                "loadAndShowIfRequired" -> {
                    val ci = ConsentInformation.getInstance(this)
                    if (!ci.isConsentFormAvailable) {
                        // Fuera de EEE (o ya consentido): no hay formulario.
                        result.success(false)
                    } else {
                        ConsentForm.loadAndShowConsentFormIfRequired(
                            this,
                            { form ->
                                form.show(this) { result.success(true) }
                            },
                            { error -> result.success(mapOf("ok" to false, "message" to error.message)) }
                        )
                    }
                }
                "reset" -> {
                    ConsentInformation.getInstance(this).reset()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestConsentInfo(result: MethodChannel.Result) {
        val consentInformation = ConsentInformation.getInstance(this)
        consentInformation.requestConsentInfoUpdate(
            this,
            ConsentRequestParameters(),
            {
                result.success(
                    mapOf(
                        "ok" to true,
                        "canRequestAds" to consentInformation.canRequestAds,
                        "status" to consentInformation.consentStatus.name
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