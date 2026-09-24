import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../theme.dart';

enum FitTab {
  home,
  recipes,
  progress,
  tips,
  profile,
  help;

  /// Nombre estable para registros (independiente del idioma).
  String get nombre => name;
}

class FitNavBar extends StatelessWidget {
  const FitNavBar({super.key, required this.current, this.onChanged});

  final FitTab current;
  final ValueChanged<FitTab>? onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleService>().strings;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _NavItem(
                tab: FitTab.home,
                icon: Icons.home,
                label: strings.navHome,
                selected: current == FitTab.home,
                onTap: () => onChanged?.call(FitTab.home),
              ),
            ),
            Flexible(
              child: _NavItem(
                tab: FitTab.recipes,
                icon: Icons.restaurant_menu,
                label: strings.navRecipes,
                selected: current == FitTab.recipes,
                onTap: () => onChanged?.call(FitTab.recipes),
              ),
            ),
            Flexible(
              child: _NavItem(
                tab: FitTab.progress,
                icon: Icons.insights,
                label: strings.navProgress,
                selected: current == FitTab.progress,
                onTap: () => onChanged?.call(FitTab.progress),
              ),
            ),
            Flexible(
              child: _NavItem(
                tab: FitTab.tips,
                icon: Icons.lightbulb_outline,
                label: strings.navTips,
                selected: current == FitTab.tips,
                onTap: () => onChanged?.call(FitTab.tips),
              ),
            ),
            Flexible(
              child: _NavItem(
                tab: FitTab.profile,
                icon: Icons.person,
                label: strings.navProfile,
                selected: current == FitTab.profile,
                onTap: () => onChanged?.call(FitTab.profile),
              ),
            ),
            Flexible(
              child: _NavItem(
                tab: FitTab.help,
                icon: Icons.help_outline,
                label: strings.navHelp,
                selected: current == FitTab.help,
                onTap: () => onChanged?.call(FitTab.help),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FitTab tab;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant;
    return Material(
      color: selected ? AppColors.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppType.labelSm.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}