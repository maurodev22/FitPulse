import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/locale_service.dart';
import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/wheel_number_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  // Los valores númericos se eligen con ruedas dentro de rangos oficiales.
  late double _edad;
  late double _pesoKg;
  late double _alturaM;
  // Las metas se eligen con chips de selección múltiple (máximo 2).
  final List<String> _metas = <String>[];
  String? _sexo;
  String? _tipoCuerpo;

  String? _nombreError;
  String? _sexoError;
  String? _metaError;
  String? _metaLimite; // Aviso cuando se intenta elegir una 3ª meta.

  static const _metasColores = {
    'Bajar de peso': Color(0xFFFBBF24),
    'Definir': Color(0xFF6FFBBE),
    'Aumentar de peso': Color(0xFF60A5FA),
    'Mantener': Color(0xFF34D399),
  };

  @override
  void initState() {
    super.initState();
    _edad = 30.0;
    _pesoKg = 70.0;
    _alturaM = 1.70;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    context.read<AppState>().guardarPerfil(_buildProfile());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  /// Construye el perfil a partir de los campos del formulario.
  AthleteProfile _buildProfile() {
    return AthleteProfile(
      nombre: _nombreController.text.trim(),
      edad: _edad.round(),
      sexo: _sexo ?? '',
      pesoKg: _pesoKg,
      alturaM: _alturaM,
      metas: List.of(_metas),
      tipoCuerpo: TipoCuerpo.normalizar(_tipoCuerpo),
    );
  }

  /// IMC calculado en vivo a partir de los valores de las ruedas.
  double get _imcEnVivo {
    if (_pesoKg <= 0 || _alturaM <= 0) return 0;
    return _pesoKg / (_alturaM * _alturaM);
  }

  bool _validate() {
    final nombreError = Validators.validarNombre(_nombreController.text);
    final sexoError = _sexo == null ? 'Selecciona un sexo biológico' : null;
    final metaError = _metas.isEmpty ? 'Selecciona al menos una meta principal' : null;
    setState(() {
      _nombreError = nombreError;
      _sexoError = sexoError;
      _metaError = metaError;
    });
    return nombreError == null && sexoError == null && metaError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _RegHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WelcomeBlock(),
                    const SizedBox(height: 20),
                    _buildAvatarPicker(),
                    const SizedBox(height: 20),
                    _buildForm(),
                  ],
                ),
              ),
            ),
            _RegFooter(onSave: () {
              if (_validate()) _goToDashboard();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDCF5EA),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/images/avatar.webp', fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto de perfil',
                  style: AppType.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Añade una foto para identificarte',
                  style: AppType.bodySm.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Subir imagen',
                          style: AppType.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nombre Completo', required: true, icon: Icons.person),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nombreController,
            onChanged: (_) => setState(() {}),
            style: AppType.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe tu nombre',
              hintStyle: AppType.bodyMd.copyWith(color: Colors.grey),
              filled: true,
              fillColor: AppColors.surfaceLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _nombreError == null
                      ? AppColors.outlineVariant
                      : AppColors.error,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorText: _nombreError,
              errorStyle: AppType.bodySm.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Edad', required: true, icon: Icons.cake),
                    const SizedBox(height: 4),
                    _wheelCard(
                      WheelNumberPicker(
                        min: Validators.minEdad.toDouble(),
                        max: Validators.maxEdad.toDouble(),
                        step: 1,
                        decimals: 0,
                        semanticsUnit: 'años',
                        initialValue: _edad,
                        onChanged: (v) => setState(() => _edad = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Sexo biológico', required: true, icon: Icons.wc),
                    const SizedBox(height: 6),
                    _dropdown(
                      _sexo,
                      (v) => setState(() {
                        _sexo = v;
                        _sexoError = null;
                      }),
                      const ['Femenino', 'Masculino', 'Otro'],
                      hint: 'Selecciona',
                      error: _sexoError,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Peso', required: true, icon: Icons.scale),
                    const SizedBox(height: 4),
                    _wheelCard(
                      WheelNumberPicker(
                        min: Validators.minPesoKg,
                        max: Validators.maxPesoKg,
                        step: 0.5,
                        decimals: 1,
                        semanticsUnit: 'kg',
                        initialValue: _pesoKg,
                        onChanged: (v) => setState(() => _pesoKg = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Altura', required: true, icon: Icons.straighten),
                    const SizedBox(height: 4),
                    _wheelCard(
                      WheelNumberPicker(
                        min: Validators.minAlturaM,
                        max: Validators.maxAlturaM,
                        step: 0.01,
                        decimals: 2,
                        semanticsUnit: 'm',
                        initialValue: _alturaM,
                        onChanged: (v) => setState(() => _alturaM = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BmiBar(imc: _imcEnVivo),
          const SizedBox(height: 20),
          _fieldLabel('Meta Principal', required: true, icon: Icons.flag),
          const SizedBox(height: 4),
          Text(
            'Elige hasta 2 metas',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _metasColores.entries
                .map(
                  (entry) => _MetaChip(
                    label: entry.key,
                    dotColor: entry.value,
                    selected: _metas.contains(entry.key),
                    onTap: () => setState(() {
                      if (_metas.contains(entry.key)) {
                        _metas.remove(entry.key);
                        _metaLimite = null;
                      } else if (_metas.length >= 2) {
                        _metaLimite = 'Máximo 2 metas seleccionadas';
                      } else {
                        _metas.add(entry.key);
                        _metaLimite = null;
                      }
                      _metaError = null;
                    }),
                  ),
                )
                .toList(),
          ),
          if (_metaLimite != null) ...[
            const SizedBox(height: 8),
            Text(
              _metaLimite!,
              style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
          if (_metaError != null) ...[
            const SizedBox(height: 8),
            Text(
              _metaError!,
              style: AppType.bodySm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 20),
          _fieldLabel('Tipo de cuerpo', icon: Icons.accessibility_new),
          const SizedBox(height: 4),
          Text(
            'Ayuda a personalizar la perspectiva visual (informativo)',
            style: AppType.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TipoCuerpo.opciones
                .map(
                  (tipo) => ChoiceChip(
                    label: Text(tipo),
                    selected: _tipoCuerpo == tipo,
                    selectedColor: AppColors.secondaryContainer,
                    onSelected: (_) => setState(() => _tipoCuerpo = tipo),
                    labelStyle: AppType.labelMd.copyWith(
                      color: _tipoCuerpo == tipo
                          ? AppColors.onSecondaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _wheelCard(Widget wheel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: wheel,
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppColors.outline),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: AppType.labelSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }

  Widget _dropdown(String? value, ValueChanged<String?> onChanged, List<String> options,
      {String? hint, String? error}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error == null ? AppColors.outlineVariant : AppColors.error),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint ?? '',
            style: AppType.bodyMd.copyWith(color: Colors.grey),
          ),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.onSurfaceVariant),
          style: AppType.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RegHeader extends StatelessWidget {
  const _RegHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.onSurface,
              ),
              const Spacer(),
              Text(
                'CREA TU PERFIL',
                style: AppType.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 6,
              backgroundColor: Color(0xFFE3EBE6),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.regInfoBanner,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.regTitle,
          style: AppType.headlineLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.regSubtitle,
          style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }
}

class _BmiBar extends StatelessWidget {
  const _BmiBar({required this.imc});

  /// IMC en vivo desde las ruedas (0 si no hay datos válidos).
  final double imc;

  @override
  Widget build(BuildContext context) {
    final valid = imc > 0;
    final categoria = valid ? _categoriaImc(imc) : '...';
    final (badge, badColor) = valid ? _estadoImc(imc) : ('—', Colors.grey);

    final borderColor = valid ? badColor : AppColors.outlineVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: valid ? badColor.withValues(alpha: 0.08) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, size: 22, color: valid ? badColor : AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valid ? 'IMC en vivo: ${imc.toStringAsFixed(1)}' : 'IMC en vivo —',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valid ? badColor : AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  valid ? categoria : 'Gira las ruedas de peso y altura',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: valid ? badColor : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: AppType.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoriaImc(double v) {
    if (v < 18.5) return 'Bajo peso';
    if (v < 25) return 'Rango normal y saludable';
    if (v < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  (String, Color) _estadoImc(double v) {
    if (v < 18.5) return ('BAJO', AppColors.error);
    if (v < 25) return ('ÓPTIMO', const Color(0xFF059669));
    if (v < 30) return ('ALTO', const Color(0xFFB45309));
    return ('MUY ALTO', AppColors.error);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surfaceLowest;
    final fg = selected ? Colors.white : AppColors.onSurface;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 54) / 2,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.secondaryFixed : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppType.labelMd.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected) const Icon(Icons.check, size: 15, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegFooter extends StatelessWidget {
  const _RegFooter({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(18),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Guardar y Entrar al Dashboard',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Podrás editar estos valores en cualquier momento desde tu Perfil.',
            style: AppType.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}