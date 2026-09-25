import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/config_service.dart';
import '../services/locale_service.dart';
import '../theme.dart';
import 'registration_screen.dart';

/// Pantalla de aceptación de Términos y EULA.
///
/// Se muestra antes de crear el perfil la primera vez. Exige marcar la
/// casilla "He leído y acepto" para poder continuar. Cada versión de los
/// términos tiene un número (kEulaVersion); si cambia, se vuelve a pedir.
class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key});

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 32,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.eulaTitle,
                    style: AppType.headlineLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.eulaIntro,
                    style: AppType.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(title: strings.eulaSection1, body: strings.eulaSection1Body),
                  const SizedBox(height: 16),
                  _Section(title: strings.eulaSection2, body: strings.eulaSection2Body),
                  const SizedBox(height: 16),
                  _Section(title: strings.eulaSection3, body: strings.eulaSection3Body),
                  const SizedBox(height: 16),
                  _Section(title: strings.eulaSection4, body: strings.eulaSection4Body),
                  const SizedBox(height: 16),
                  Text(
                    '${strings.eulaVersionLabel}: v$kEulaVersion',
                    style: AppType.labelSm.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                border: Border(
                  top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: Text(
                      strings.eulaAccept,
                      style: AppType.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      color: _accepted ? AppColors.primary : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: _accepted ? _continue : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              strings.eulaContinue,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _accepted ? Colors.white : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: _accepted ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    context.read<ConfigService>().aceptarEula();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegistrationScreen()),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppType.labelLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: AppType.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}