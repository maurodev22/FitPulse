import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/avisos.dart';

/// Instancia global (mismo patrón que `initAds()` de AdMob): inicializada en
/// `main()` y usada por perfil y reproductor.
final AvisosService avisosService = AvisosService();

/// Resultado honesto de activar/desactivar un aviso local.
class AvisoResultado {
  const AvisoResultado({required this.ok, required this.mensaje});

  final bool ok;
  final String mensaje;
}

/// Estado del permiso de notificaciones, para pedirlo UNA sola vez y no volver
/// a mostrar el diálogo del sistema en cada arranque si el usuario lo denegó.
enum AvisosPermisoEstado {
  pendiente,
  concedido,
  denegado,
}

/// Fase 6: avisos locales reales (notificaciones en el propio móvil).
///
/// - Hidratación: recordatorio periódico (cada hora) activable por separado.
/// - Racha en riesgo: aviso diario a las 20:00 con la racha REAL del historial;
///   se cancela el día en que se completa una sesión y se reprograma al día
///   siguiente con la racha actualizada.
///
/// Si el permiso de notificaciones se deniega (Android 13+) o el plugin no
/// está disponible, se devuelve un [AvisoResultado] honesto (nunca se finge
/// que un aviso está activo si no puede mostrarse).
class AvisosService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;
  AvisosPermisoEstado _permisoEstado = AvisosPermisoEstado.pendiente;

  /// Inicializa el plugin (canales + icono). Devuelve mensaje de error o null.
  Future<String?> inicializar() async {
    if (_inicializado) return null;
    try {
      tzdata.initializeTimeZones(); // Base tz sin librería de zona horaria.
      const android = AndroidInitializationSettings('ic_stat_fitpulse');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _inicializado = true;
      return null;
    } catch (e) {
      return 'No se pudieron iniciar las notificaciones ($e)';
    }
  }

  /// Permiso de notificaciones, consultando el estado cacheado para no pedirlo
  /// dos veces seguidas (evita un diálogo doble y futuros colgados).
  ///
  /// Android 13+ pide el permiso en tiempo de ejecución; Android 12- siempre
  /// devuelve true. Si el usuario denegó antes, no se vuelve a preguntar.
  Future<bool> _permiso() async {
    if (_permisoEstado == AvisosPermisoEstado.concedido) return true;
    if (_permisoEstado == AvisosPermisoEstado.denegado) return false;
    try {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) {
        _permisoEstado = AvisosPermisoEstado.denegado;
        return false;
      }
      final activas = await impl.areNotificationsEnabled();
      if (activas == true) {
        _permisoEstado = AvisosPermisoEstado.concedido;
        return true;
      }
      final concedido = await impl.requestNotificationsPermission() ?? false;
      _permisoEstado = concedido
          ? AvisosPermisoEstado.concedido
          : AvisosPermisoEstado.denegado;
      return concedido;
    } catch (_) {
      _permisoEstado = AvisosPermisoEstado.denegado;
      return false;
    }
  }

  NotificationDetails get _detallesComunes => const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitpulse_avisos',
          'Avisos de FitPulse',
          channelDescription:
              'Recordatorios de hidratación y de racha (100 % local)',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Sincronización única al arrancar: pide el permiso UNA vez y programa (o
  /// cancela) ambos avisos según los toggles persistidos del perfil. Al ser un
  /// único flujo serializado no hay carrera entre avisos ni doble diálogo.
  Future<void> sincronizar({
    required bool hidratacion,
    required bool racha,
    required int rachaDias,
  }) async {
    final error = await inicializar();
    if (error != null) return; // Honesto: sin plugin no hay avisos.
    if (!await _permiso()) return; // Honesto: sin permiso no se programa nada.
    try {
      await _plugin.cancel(id: AvisosIds.hidratacion);
      await _plugin.cancel(id: AvisosIds.racha);
      if (hidratacion) {
        await _programarHidratacion();
      }
      if (racha) {
        await _programarRacha(rachaDias);
      }
    } catch (_) {
      // Si falla, simplemente no hay avisos; nunca inventa nada.
    }
  }

  /// Activa (programa el recordatorio periódico) o desactiva la hidratación.
  Future<AvisoResultado> setHidratacion({required bool activar}) async {
    if (!await _permiso()) {
      return const AvisoResultado(
        ok: false,
        mensaje: 'Permiso de notificaciones denegado: aviso desactivado',
      );
    }
    try {
      await _plugin.cancel(id: AvisosIds.hidratacion);
      if (activar) {
        await _programarHidratacion();
      }
      return AvisoResultado(
        ok: true,
        mensaje: activar
            ? 'Recordatorio de hidratación activado'
            : 'Recordatorio de hidratación desactivado',
      );
    } catch (e) {
      return AvisoResultado(
        ok: false,
        mensaje: 'No se pudo programar el aviso ($e)',
      );
    }
  }

  /// Activa (programa el aviso diario a las 20:00 con la racha real) o
  /// desactiva el aviso de racha en riesgo.
  Future<AvisoResultado> setRacha({
    required bool activar,
    required int rachaDias,
  }) async {
    if (!await _permiso()) {
      return const AvisoResultado(
        ok: false,
        mensaje: 'Permiso de notificaciones denegado: aviso desactivado',
      );
    }
    try {
      await _plugin.cancel(id: AvisosIds.racha);
      if (activar) {
        await _programarRacha(rachaDias);
      }
      return AvisoResultado(
        ok: true,
        mensaje: activar
            ? 'Aviso de racha activado'
            : 'Aviso de racha desactivado',
      );
    } catch (e) {
      return AvisoResultado(
        ok: false,
        mensaje: 'No se pudo programar el aviso ($e)',
      );
    }
  }

  /// Programa el recordatorio periódico de hidratación (cada hora).
  Future<void> _programarHidratacion() async {
    await _plugin.periodicallyShow(
      id: AvisosIds.hidratacion,
      title: '💧 ¿Agua?',
      body: 'Llevas un rato sin hidratarte: un vaso ahora.',
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: _detallesComunes,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Programa el aviso diario de la racha (próxima 20:00 local en adelante),
  /// repitiéndose cada día a esa hora (la app lo cancela al entrenar hoy).
  Future<void> _programarRacha(int rachaDias) async {
    final cuandoLocal = proximaHoraLocal(DateTime.now(), 20, 0);
    final cuando = tz.TZDateTime.from(comoInstantUtc(cuandoLocal), tz.UTC);
    await _plugin.zonedSchedule(
      id: AvisosIds.racha,
      title: '🏃 Tu racha hoy',
      body: textoAvisoRacha(rachaDias),
      scheduledDate: cuando,
      notificationDetails: _detallesComunes,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Al completar una sesión hoy: cancela el aviso de racha de hoy. Si el
  /// aviso está activo ([reprogramar] true), lo reprograma para mañana con la
  /// racha actualizada (el texto usa datos reales en cada reprogramación).
  Future<void> sesionCompletada(int rachaNueva, {bool reprogramar = true}) async {
    if (!_inicializado) return;
    try {
      await _plugin.cancel(id: AvisosIds.racha);
      if (reprogramar) {
        await _programarRacha(rachaNueva);
      }
    } catch (_) {
      // Si falla, simplemente no hay aviso mañana; nunca inventa nada.
    }
  }
}