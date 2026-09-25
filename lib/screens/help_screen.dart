import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../theme.dart';

/// Ayuda y Soporte: manual de usuario local (funciona sin internet) y FAQ.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _manual = '';
  String? _manualIdioma;

  @override
  void initState() {
    super.initState();
    _cargarManual();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarga el manual al cambiar el idioma en vivo (Perfil → Idioma).
    final en = context.read<LocaleService>().isEnglish;
    final wanted = en ? 'en' : 'es';
    if (_manualIdioma != wanted) _cargarManual();
  }

  Future<void> _cargarManual() async {
    final en = context.read<LocaleService>().isEnglish;
    final name = en ? 'assets/docs/manual_en.md' : 'assets/docs/manual_es.md';
    final raw = await rootBundle.loadString(name);
    if (mounted) {
      setState(() {
        _manual = raw;
        _manualIdioma = en ? 'en' : 'es';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HelpHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    title: strings.helpManualTitle,
                    icon: Icons.menu_book_outlined,
                    child: _ManualBody(markdown: _manual),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: strings.helpFaqTitle,
                    icon: Icons.question_answer_outlined,
                    child: _FaqList(),
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

class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(color: AppColors.surface),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.live_help, color: AppColors.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.helpHeaderTitle,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.helpHeaderSubtitle,
                  style: AppType.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Renderiza el manual local (markdown ligero) sin dependencias.
class _ManualBody extends StatelessWidget {
  const _ManualBody({required this.markdown});

  final String markdown;

  /// Quita los marcadores bold (`**`) para que no se muestren como texto literal.
  static String _plain(String input) => input.replaceAll('**', '');

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final children = <Widget>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final header = RegExp(r'^#+\s+(.*)$').firstMatch(line);
      if (header != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            _plain(header.group(1)!),
            style: AppType.headlineSm.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ));
        continue;
      }
      final tableRow = RegExp(r'^\|\s*(.*?)\s*\|$').firstMatch(line);
      if (tableRow != null) {
        final cells = tableRow
            .group(1)!
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty && !RegExp(r'^[-: ]+$').hasMatch(c))
            .toList();
        if (cells.isEmpty) continue;
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _plain(cells.first),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _plain(cells.length > 1 ? cells.sublist(1).join(' · ') : ''),
                  style: AppType.bodySm.copyWith(
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }
      final listItem = RegExp(r'^\s*(?:\d+\.|-)\s+(.*)$').firstMatch(line);
      if (listItem != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixedDim,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _plain(listItem.group(1)!),
                  style: AppType.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          _plain(line),
          style: AppType.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

/// Preguntas frecuentes (FAQ) en colapsables.
class _FaqList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    final faq = <(String, String)>[
      (strings.faqDataQ, strings.faqDataA),
      (strings.faqOfflineQ, strings.faqOfflineA),
      (strings.faqResetQ, strings.faqResetA),
    ];
    return Column(
      children: [
        for (final (q, a) in faq)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  q,
                  style: AppType.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                leading: Icon(Icons.question_answer_outlined, size: 20, color: AppColors.primary),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      a,
                      style: AppType.bodySm.copyWith(color: AppColors.outline, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
