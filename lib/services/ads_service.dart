/// Configuración de anuncios de AdMob (Fase 3).
///
/// Se usan EXCLUSIVAMENTE IDs de PRUEBA oficiales de Google:
/// - Banner y recompensado funcionan en cualquier dispositivo con Play Services.
/// - AdMob/Google Play no aceptan cuentas con residencia en Cuba; para anuncios
///   reales se sustituyen estos IDs por los de una cuenta registrada fuera de
///   Cuba (ver `PLAN.md`, Fase 3).
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ID de bloque de banner de PRUEBA (Android).
const String kAdmobBannerTestId = 'ca-app-pub-3940256099942544/6300978111';

/// ID de bloque de anuncio RECOMPENSADO de PRUEBA (Android).
const String kAdmobRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

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
/// carga, no ocupa espacio (SizedBox.shrink). Un `MobileAdWidget` real
/// requiere que el banner se haya cargado correctamente.
class FitBannerAd extends StatefulWidget {
  const FitBannerAd({super.key});

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
            if (!mounted) return;
            setState(() => _loadFailed = true);
          },
        ),
      );
      await ad.load();
    } catch (_) {
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
    if (banner == null || _loadFailed) return const SizedBox.shrink();
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
/// Nunca lanza: los fallos se reportan por [onError].
Future<void> mostrarAnuncioRecompensado({
  required VoidCallback onRecompensa,
  required ValueChanged<String> onError,
}) async {
  RewardedAd? recompensado;
  void limpiar() => recompensado?.dispose();

  try {
    await initAds();
    await RewardedAd.load(
      adUnitId: kAdmobRewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          recompensado = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
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