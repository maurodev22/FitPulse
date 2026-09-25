import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../theme.dart';

/// Política de privacidad (Fase 8, GDPR/UE), accesible desde Perfil.
///
/// Explica qué se guarda (todo local), qué NO se transmite, la base legal del
/// consentimiento para datos de salud (art. 9), edad mínima (art. 8), los
/// derechos del usuario (acceso, rectificación, portabilidad, borrado), la
/// publicidad y la IA local. Texto es/en verbatim desde [AppStrings].
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.pvTitle,
          style: AppType.headlineSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                strings.pvIntro,
                style: AppType.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.pvVigencia,
              style: AppType.labelSm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            _Seccion(titulo: strings.pvSec1, cuerpo: strings.pvSec1Body),
            _Seccion(titulo: strings.pvSec2, cuerpo: strings.pvSec2Body),
            _Seccion(titulo: strings.pvSec3, cuerpo: strings.pvSec3Body),
            _Seccion(titulo: strings.pvSec4, cuerpo: strings.pvSec4Body),
            _Seccion(titulo: strings.pvSec5, cuerpo: strings.pvSec5Body),
            _Seccion(titulo: strings.pvSec6, cuerpo: strings.pvSec6Body),
            _Seccion(titulo: strings.pvSec7, cuerpo: strings.pvSec7Body),
            _Seccion(titulo: strings.pvSec8, cuerpo: strings.pvSec8Body),
            _Seccion(titulo: strings.pvSec9, cuerpo: strings.pvSec9Body),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.cuerpo});

  final String titulo;
  final String cuerpo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: AppType.labelLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cuerpo,
            style: AppType.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}