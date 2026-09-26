/// Publicidad de AdMob (Fases 3 + 8.3): banner, recompensado y app open.
///
/// Se usan EXCLUSIVAMENTE IDs de PRUEBA oficiales de Google:
/// - Banner, recompensado y app open funcionan en cualquier dispositivo con
///   Play Services.
/// - AdMob/Google Play no aceptan cuentas con residencia en Cuba; para
///   anuncios reales se sustituyen estos IDs por los de una cuenta registrada
///   fuera de Cuba (ver `PLAN.md`, Fase 8.3: lista de sustitución).
///
/// Consentimiento UE (Fase 8.3): TODO formato pasa por [AdsPermiso.consentimientoOk]
/// que se actualiza desde `main()` cuando se resuelve el UMP. Sin consentimiento
/// resuelto → no se cargan anuncios reales (degradado honesto).
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme.dart';

/// ID de bloque de banner de PRUEBA (Android).
const String kAdmobBannerTestId = 'ca-app-pub-3940256099942544/6300978111';

/// ID de bloque de anuncio RECOMPENSADO de PRUEBA (Android).
const String kAdmobRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

/// ID de bloque de anuncio de APERTURA (App Open) de PRUEBA (Android).
const String kAdmobAppOpenTestId = 'ca-app-pub-3940256099942544/9257395921';

/// Decisión pura de cuándo renderizar anuncios. Función testeable.
bool adsPermitidos({
  required bool adsEnabled,
  required bool premium,
  required bool consentimientoOk,
}) =>
    adsEnabled && !premium && consentimientoOk;

/// Puerta global que comparten todos los formatos de anuncio.
///
/// Se actualiza desde `main()` cuando el consentimiento UMP se resuelve.
/// En los tests los widgets/servicios leen estos valores directamente.
class AdsPermiso {
  /// El SDK UMP permite pedir anuncios (canRequestAds == true).
  static bool consentimientoOk = false;

  /// El consentimiento no se pudo resolver por causa técnica/red (p. ej. sin
  /// red a Google desde Cuba). En desarrollo se reserva igualmente la zona de
  /// banner con el placeholder honesto, para que el layout se pueda testear.
  static bool consentimientoErrorSinRed = false;

  /// Vista previa de piezas DE PRUEBA (imagen/texto, claramente marcadas).
  ///
  /// Se activa en `main()` cuando el consentimiento UMP falla por red (Cuba o
  /// sin acceso a Google): el banner y el recompensado muestran piezas locales
  /// "Anuncio de PRUEBA" para verificar el layout y el flujo del +25 PTs sin
  /// depender de AdMob. Con consentimiento resuelto (cliente fuera de Cuba con
  /// IDs reales) queda falso y se muestran anuncios reales.
  static bool vistaPreviaTest = false;

  /// Un entrenamiento (reproductor) está en pantalla: no se interrumpe con un
  /// anuncio de apertura. Lo gestiona `workout_player_screen.dart`.
  static bool ejercicioActivo = false;

  /// Hay un anuncio a pantalla completa en curso (app open o recompensado):
  /// no se muestra otro encima.
  static bool anuncioALaVista = false;
}

/// Restablece la puerta global (útil en tests).
void resetAdsPermisoParaTests() {
  AdsPermiso.consentimientoOk = false;
  AdsPermiso.consentimientoErrorSinRed = false;
  AdsPermiso.ejercicioActivo = false;
  AdsPermiso.anuncioALaVista = false;
  AdsPermiso.vistaPreviaTest = false;
}

/// Inicializa el SDK de AdMob. Nunca lanza: si no hay soporte (tests,
/// emulador sin Play Services) simplemente no hace nada.
Future<void> initAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // Sin soporte: los widgets de anuncio no mostrarán nada.
  }
}

/// Banner inferior de AdMob con degradación elegante.
///
/// Si el SDK no está disponible (tests, sin Play Services) o el anuncio no
/// carga, no ocupa espacio (SizedBox.shrink). Con el consentimiento UMP
/// resuelto se intenta cargar el banner real; sin consentimiento (fallo
/// técnico/red en desarrollo) se muestra la zona de anuncio honesta si
/// [mostrarPlaceholderCuandoFalla] está activo.
class FitBannerAd extends StatefulWidget {
  const FitBannerAd({super.key});

  /// Cuando el anuncio de prueba no carga (sin conexión a AdMob, p. ej. en
  /// Cuba), muestra una zona marcada "Anuncio" en lugar de colapsar a cero,
  /// para que el layout de la publicidad sea visible y testeable.
  ///
  /// Se activa en `main()` (producción/pruebas manuales); los tests de widget
  /// no llaman a `main()`, así que quedan con el comportamiento discreto.
  static bool mostrarPlaceholderCuandoFalla = false;

  @override
  State<FitBannerAd> createState() => _FitBannerAdState();
}

class _FitBannerAdState extends State<FitBannerAd> {
  BannerAd? _banner;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      if (!AdsPermiso.consentimientoOk) {
        // Fase 8.3: sin consentimiento no se carga ningún anuncio real. Si el
        // fallo fue técnico/red (dev en Cuba, o sin Google), se reserva la
        // zona con el placeholder honesto; si el usuario no consintió (UE),
        // no se muestra nada (honesto, sin espacios falsos).
        if (AdsPermiso.consentimientoErrorSinRed && mounted) {
          setState(() => _loadFailed = true);
        }
        return;
      }
      await initAds();
      final ad = BannerAd(
        adUnitId: kAdmobBannerTestId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) return;
            setState(() => _banner = ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint('[FitPulse/Ads] banner falló: código ${error.code} '
                '(${error.domain}): ${error.message}');
            if (!mounted) return;
            setState(() => _loadFailed = true);
          },
        ),
      );
      await ad.load();
    } catch (e) {
      debugPrint('[FitPulse/Ads] banner sin soporte: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null && _loadFailed && FitBannerAd.mostrarPlaceholderCuandoFalla) {
      // Vista previa de prueba (Cuba/dev sin red a Google): pieza local rica,
      // claramente marcada como PRUEBA, para verificar el layout del banner.
      if (AdsPermiso.vistaPreviaTest) {
        return Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceContainer,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.campaign, size: 20, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FitPulse · Ejercítate hoy 💪',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Anuncio de PRUEBA local — AdMob sin conexión',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRUEBA',
                  style: AppType.labelSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Zona de anuncio honesta cuando no hay conexión a AdMob (prueba local).
      return Container(
        width: double.infinity,
        height: 50,
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined,
                size: 14, color: AppColors.outline),
            const SizedBox(width: 6),
            Text(
              'Zona de anuncio · sin conexión a AdMob (prueba)',
              style: AppType.bodySm.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      );
    }
    if (banner == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}

/// Muestra un anuncio recompensado de PRUEBA y llama a [onRecompensa] cuando
/// el usuario gana la recompensa. [onError] informa si no se puede mostrar.
///
/// Nunca lanza: los fallos se reportan por [onError]. Respeta la puerta de
/// consentimiento y evita solaparse con otro anuncio a pantalla completa.
/// En modo vista previa ([AdsPermiso.vistaPreviaTest]) simula el flujo con una
/// pieza de imagen/texto local para poder probar el +25 PTs sin AdMob.
Future<void> mostrarAnuncioRecompensado({
  required BuildContext context,
  required VoidCallback onRecompensa,
  required ValueChanged<String> onError,
}) async {
  // Vista previa de prueba (Cuba/dev sin red a Google): flujo completo del
  // recompensado con una pieza local claramente marcada como PRUEBA.
  if (AdsPermiso.vistaPreviaTest && !AdsPermiso.consentimientoOk) {
    await _mostrarRecompensadoDePrueba(context, onRecompensa);
    return;
  }
  if (!AdsPermiso.consentimientoOk) {
    onError('Los anuncios no están disponibles en este dispositivo.');
    return;
  }
  RewardedAd? recompensado;
  void limpiar() {
    AdsPermiso.anuncioALaVista = false;
    recompensado?.dispose();
  }

  try {
    await initAds();
    await RewardedAd.load(
      adUnitId: kAdmobRewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          recompensado = ad;
          AdsPermiso.anuncioALaVista = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => limpiar(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              limpiar();
              onError('No se pudo mostrar el anuncio.');
            },
          );
          ad.show(onUserEarnedReward: (_, _) => onRecompensa());
        },
        onAdFailedToLoad: (error) {
          limpiar();
          onError('El anuncio no está disponible ahora.');
        },
      ),
    );
  } catch (_) {
    limpiar();
    onError('Los anuncios no están disponibles en este dispositivo.');
  }
}

/// Simula el anuncio recompensado en vista previa (prueba local): una pieza
/// de solo imagen/texto claramente marcada como PRUEBA. Al cerrarla se otorga
/// la recompensa para poder probar el flujo completo del +25 PTs sin AdMob.
Future<void> _mostrarRecompensadoDePrueba(
  BuildContext context,
  VoidCallback onRecompensa,
) async {
  final otorgar = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Anuncio de prueba',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _RecompensaDePruebaDialog(),
  );
  if (otorgar == true) onRecompensa();
}

/// Pieza "video" de prueba: solo imagen/texto estáticos (un anuncio de imagen
/// en la vida real), con cierre que entrega la recompensa de prueba.
class _RecompensaDePruebaDialog extends StatelessWidget {
  const _RecompensaDePruebaDialog();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            // "Video" del anuncio: creatividad estática (imagen/texto).
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.primaryContainer,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, size: 48,
                          color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FitPulse Premium',
                      textAlign: TextAlign.center,
                      style: AppType.headlineMd.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '7 días gratis · Sin anuncios',
                      textAlign: TextAlign.center,
                      style: AppType.bodyMd.copyWith(
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ANUNCIO DE PRUEBA · SIN CONEXIÓN A AdMob',
                        textAlign: TextAlign.center,
                        style: AppType.labelSm.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Barra de control: cerrar otorga la recompensa (prueba).
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Simulación local: al cerrar ganas +25 PTs de prueba.',
                    textAlign: TextAlign.center,
                    style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Cerrar y ganar +25 PTs (prueba)'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cerrar sin recompensa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decisión pura de cuándo mostrar el anuncio de apertura (App Open).
/// Reglas (Fase 8.3):
/// - Solo con consentimiento resuelto, sin otro anuncio a la vista y sin un
///   entrenamiento en curso (el reproductor lo marca en [AdsPermiso.ejercicioActivo]).
/// - Como máximo [maxPorSesion] por sesión.
/// - No en arranque en frío: hace falta una pausa previa de al menos
///   [pausaMinima] (la app tuvo que ir a segundo plano antes de volver).
/// - Espera [cooldown] desde la última vez mostrado.
@visibleForTesting
bool decisionAppOpen({
  required bool consentimientoOk,
  required bool anuncioALaVista,
  required bool ejercicioActivo,
  required int mostradosEnSesion,
  required Duration pausaPrevia,
  Duration? desdeUltimaVez,
  Duration pausaMinima = const Duration(seconds: 30),
  Duration cooldown = const Duration(seconds: 60),
  int maxPorSesion = 1,
}) {
  if (!consentimientoOk) return false;
  if (anuncioALaVista) return false;
  if (ejercicioActivo) return false;
  if (mostradosEnSesion >= maxPorSesion) return false;
  if (pausaPrevia < pausaMinima) return false;
  if (desdeUltimaVez != null && desdeUltimaVez < cooldown) return false;
  return true;
}

/// Anuncio de apertura (App Open): se muestra al volver al primer plano si
/// procede según [decisionAppOpen]. Nunca lanza: cualquier fallo solo loguea.
class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  static const Duration _pausaMinima = Duration(seconds: 30);
  static const Duration _cooldown = Duration(seconds: 60);
  static const int _maxPorSesion = 1;

  AppOpenAd? _ad;
  bool _cargando = false;
  int _mostradosEnSesion = 0;
  DateTime? _ultimaMostrada;
  DateTime? _ultimaPausa;

  /// Arranca la escucha del ciclo de vida y precarga si hay consentimiento.
  Future<void> iniciar() async {
    WidgetsBinding.instance.addObserver(this);
    await precargar();
  }

  Future<void> precargar() async {
    if (_cargando || _ad != null) return;
    if (!AdsPermiso.consentimientoOk) return;
    _cargando = true;
    try {
      await initAds();
      await AppOpenAd.load(
        adUnitId: kAdmobAppOpenTestId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) => _ad = ad,
          onAdFailedToLoad: (error) =>
              debugPrint('[FitPulse/Ads] app open no cargó: '
                  'código ${error.code} ${error.message}'),
        ),
      );
    } catch (e) {
      debugPrint('[FitPulse/Ads] app open sin soporte: $e');
    } finally {
      _cargando = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _ultimaPausa = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _alVolverAlFrente();
    }
  }

  Future<void> _alVolverAlFrente() async {
    final ahora = DateTime.now();
    final pausa = _ultimaPausa;
    // Arranque en frío: sin pausa previa no se muestra (regla anti-cold-start).
    if (pausa == null) return;
    final desdeUltima = _ultimaMostrada == null
        ? null
        : ahora.difference(_ultimaMostrada!);
    if (!decisionAppOpen(
          consentimientoOk: AdsPermiso.consentimientoOk,
          anuncioALaVista: AdsPermiso.anuncioALaVista,
          ejercicioActivo: AdsPermiso.ejercicioActivo,
          mostradosEnSesion: _mostradosEnSesion,
          pausaPrevia: ahora.difference(pausa),
          desdeUltimaVez: desdeUltima,
          pausaMinima: _pausaMinima,
          cooldown: _cooldown,
          maxPorSesion: _maxPorSesion,
        )) {
      return;
    }
    final ad = _ad ?? (await _cargarParaMostrar());
    if (ad == null) return;
    AdsPermiso.anuncioALaVista = true;
    _mostradosEnSesion++;
    _ultimaMostrada = ahora;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => _cerrar(),
      onAdFailedToShowFullScreenContent: (_, _) => _cerrar(),
    );
    ad.show();
  }

  Future<AppOpenAd?> _cargarParaMostrar() async {
    await precargar();
    return _ad;
  }

  void _cerrar() {
    AdsPermiso.anuncioALaVista = false;
    _ad?.dispose();
    _ad = null;
  }
}