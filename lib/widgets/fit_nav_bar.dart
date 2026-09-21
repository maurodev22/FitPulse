import 'package:flutter/material.dart';

import '../theme.dart';

enum FitTab { home, tacos, shop, fitness, profile }

class FitNavBar extends StatelessWidget {
  const FitNavBar({super.key, required this.current, this.onChanged});

  final FitTab current;
  final ValueChanged<FitTab>? onChanged;

  @override
  Widget build(BuildContext context) {
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              tab: FitTab.home,
              icon: Icons.home,
              label: 'Inicio',
              selected: current == FitTab.home,
              onTap: () => onChanged?.call(FitTab.home),
            ),
            _NavItem(
              tab: FitTab.tacos,
              icon: Icons.restaurant_menu,
              label: 'Recetas',
              selected: current == FitTab.tacos,
              onTap: () => onChanged?.call(FitTab.tacos),
            ),
            _NavItem(
              tab: FitTab.shop,
              icon: Icons.insights,
              label: 'Progreso',
              selected: current == FitTab.shop,
              onTap: () => onChanged?.call(FitTab.shop),
            ),
            _NavItem(
              tab: FitTab.fitness,
              icon: Icons.lightbulb_outline,
              label: 'Consejos',
              selected: current == FitTab.fitness,
              onTap: () => onChanged?.call(FitTab.fitness),
            ),
            _NavItem(
              tab: FitTab.profile,
              icon: Icons.person,
              label: 'Perfil',
              selected: current == FitTab.profile,
              onTap: () => onChanged?.call(FitTab.profile),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
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