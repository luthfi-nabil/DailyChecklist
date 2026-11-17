import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CalmCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const CalmCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.line(context)),
      ),
      child: child,
    );
  }
}

class CalmProgressBar extends StatelessWidget {
  final int percent;
  final bool gold;
  final double height;
  final Color? barColor;

  const CalmProgressBar({
    super.key,
    required this.percent,
    this.gold = false,
    this.height = 12,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    final bg = gold ? AppColors.goldSoft(context) : AppColors.accentSoft(context);
    final fg = barColor ?? (gold ? AppColors.gold(context) : AppColors.accent(context));

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        width: double.infinity,
        color: bg,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 350),
          widthFactor: clamped / 100.0,
          child: Container(
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class CalmSegmentedControl<T> extends StatelessWidget {
  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onChanged;

  const CalmSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((item) {
          final isSel = item.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.surface(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSel ? AppColors.ink(context) : AppColors.muted(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

void showCalmSnackBar(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink(context),
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(
        message,
        style: TextStyle(color: AppColors.bg(context)),
      ),
      action: onUndo != null
          ? SnackBarAction(
              label: 'Urungkan',
              textColor: AppColors.bg(context),
              onPressed: onUndo,
            )
          : null,
    ),
  );
}
