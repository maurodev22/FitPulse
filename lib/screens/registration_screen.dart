import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/app_state.dart';
import '../state/athlete_profile.dart';
import '../theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nombreController = TextEditingController(text: 'Sofía Martínez');
  final _edadController = TextEditingController(text: '26');
  String _sexo = 'Femenino';
  final _pesoController = TextEditingController(text: '64.5');
  final _alturaController = TextEditingController(text: '1.72');
  String _meta = 'Definir';

  static const _metas = {
    'Bajar de peso': Color(0xFFFBBF24),
    'Definir': Color(0xFF6FFBBE),
    'Aumentar de peso': Color(0xFF60A5FA),
    'Mantener': Color(0xFF34D399),
  };

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    // Persistir la sesión del atleta en el dispositivo antes de entrar.
    context.read<AppState>().guardarPerfil(_buildProfile());

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  /// Construye el perfil a partir de los campos del formulario.
  AthleteProfile _buildProfile() {
    return AthleteProfile(
      nombre: _nombreController.text.trim().isEmpty
          ? 'Sofía Martínez'
          : _nombreController.text.trim(),
      edad: int.tryParse(_edadController.text.trim()) ?? 26,
      sexo: _sexo,
      pesoKg: double.tryParse(_pesoController.text.trim()) ?? 64.5,
      alturaM: double.tryParse(_alturaController.text.trim()) ?? 1.72,
      meta: _meta,
    );
  }

  /// IMC calculado en vivo a partir de peso y altura del formulario.
  double get _imcEnVivo {
    final peso = double.tryParse(_pesoController.text.trim()) ?? 0;
    final altura = double.tryParse(_alturaController.text.trim()) ?? 0;
    if (peso <= 0 || altura <= 0) return 0;
    return peso / (altura * altura);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _RegHeader(onSkip: _goToDashboard),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const _WelcomeBlock(),
                  const SizedBox(height: 20),
                  _buildAvatarPicker(),
                  const SizedBox(height: 20),
                  _buildForm(),
                ],
              ),
            ),
            _RegFooter(onSave: _goToDashboard),
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
            child: Image.asset('assets/images/avatar.jpg', fit: BoxFit.cover),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Nombre Completo', required: true, icon: Icons.person),
        const SizedBox(height: 6),
        _textField(controller: _nombreController, hint: 'Ej. Sofía Martínez'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Edad', required: true, icon: Icons.cake),
                  const SizedBox(height: 6),
                  _textField(
                    controller: _edadController,
                    hint: '26',
                    suffix: 'años',
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
                  _dropdown(_sexo, (v) => setState(() => _sexo = v!), [
                    'Femenino',
                    'Masculino',
                    'Otro',
                  ]),
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
                  const SizedBox(height: 6),
                  _textField(
                    controller: _pesoController,
                    hint: '64.5',
                    suffix: 'kg',
                    onChanged: (_) => setState(() {}),
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
                  const SizedBox(height: 6),
                  _textField(
                    controller: _alturaController,
                    hint: '1.72',
                    suffix: 'm',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BmiBar(imc: _imcEnVivo),
        const SizedBox(height: 20),
        Row(
          children: [
            _fieldLabel('Meta Principal', required: true, icon: Icons.flag),
            const Spacer(),
            Text(
              'Requerido',
              style: AppType.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _metas.entries
              .map(
                (entry) => _MetaChip(
                  label: entry.key,
                  dotColor: entry.value,
                  selected: entry.key == _meta,
                  onTap: () => setState(() => _meta = entry.key),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppColors.outline),
          const SizedBox(width: 4),
        ],
        Text(
          text.toUpperCase(),
          style: AppType.labelSm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppType.bodyMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppType.bodyMd.copyWith(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                suffix,
                style: AppType.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(String value, ValueChanged<String?> onChanged, List<String> options) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
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
  const _RegHeader({required this.onSkip});

  final VoidCallback onSkip;

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
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PASO 1 DE 2',
                    style: AppType.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Saltar',
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Personaliza tu experiencia',
                style: AppType.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Crea tu Perfil Atlético',
          style: AppType.headlineLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Para calibrar tus métricas de pulso, quema calórica y planes de entrenamiento diarios.',
          style: AppType.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }
}

class _BmiBar extends StatelessWidget {
  const _BmiBar({required this.imc});

  /// IMC en vivo calculado desde el formulario (0 si no hay datos válidos).
  final double imc;

  @override
  Widget build(BuildContext context) {
    final valid = imc > 0;
    final label = valid ? imc.toStringAsFixed(1) : '--';
    final categoria = valid
        ? _categoriaImc(imc)
        : 'Ingresa tu peso y altura';
    final badge = valid
        ? (imc < 25 && imc >= 18.5 ? 'ÓPTIMO' : '¡ATENCIÓN!')
        : 'PENDIENTE';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMC Inicial Estimado: $label',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  categoria,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
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
                    Text(
                      'Guardar y Entrar al Dashboard',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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