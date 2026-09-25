import 'package:flutter/material.dart';

import '../theme.dart';

class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 5,
    this.center,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    // Fase 7: micro-animación — el anillo crece suavemente hasta el valor.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainer,
            ),
            if (center != null)
              Center(
                child: IgnorePointer(child: center),
              ),
          ],
        ),
      ),
    );
  }
}

class MetricStat {
  const MetricStat({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.icon,
    this.iconColor,
    this.iconBackground,
  });

  final String label;
  final String value;
  final String unit;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.stat,
    this.subtitle,
    this.subtitleColor,
    this.progress,
    this.radius = 24,
  });

  final MetricStat stat;
  final String? subtitle;
  final Color? subtitleColor;
  final double? progress;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  stat.label.toUpperCase(),
                  style: AppType.labelMd.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (stat.icon != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: stat.iconBackground ?? AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stat.icon, size: 16, color: stat.iconColor ?? AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(stat.value, style: AppType.headlineMd.copyWith(
                color: stat.valueColor ?? AppColors.onSurface, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(stat.unit, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppType.bodySm.copyWith(color: subtitleColor ?? AppColors.outline)),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            // Fase 7: micro-animación — la barra crece suavemente.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress!.clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: AppColors.surfaceLowest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryContainer.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.uppercase = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final titleWidget = uppercase
        ? Text(
            title.toUpperCase(),
            style: AppType.labelLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          )
        : Text(title, style: AppType.headlineSm.copyWith(fontWeight: FontWeight.w700));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleWidget),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: AppType.labelMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          )
        else
          trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surfaceContainerLow;
    final fg = selected ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: AppColors.onPrimary),
                const SizedBox(width: 6),
              ],
              if (icon != null && !selected) ...[
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppType.labelMd.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
