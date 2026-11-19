import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

InputDecoration m6InputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? prefixIcon,
}) {
  final line = AppColors.line(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    isDense: true,
    filled: true,
    fillColor: AppColors.surface(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.accent(context), width: 1.5),
    ),
  );
}

ButtonStyle m6PrimaryButtonStyle(BuildContext context) {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent(context),
    foregroundColor: AppColors.accentInk(context),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
  );
}

ButtonStyle m6GhostButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    backgroundColor: AppColors.soft(context),
    foregroundColor: AppColors.accentDeep(context),
    side: BorderSide(color: AppColors.line(context)),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
  );
}

class M6StatBox extends StatelessWidget {
  final String label;
  final String value;
  const M6StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.soft(context),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
          ),
        ],
      ),
    );
  }
}

class M6Pill extends StatelessWidget {
  final String text;
  const M6Pill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tabBg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.accentDeep(context),
        ),
      ),
    );
  }
}

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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A8D6070),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
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
    this.height = 8,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    final bg = AppColors.tabBg(context);
    final fg = barColor ?? AppColors.accent(context);

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
  String undoLabel = 'Undo',
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null || !messenger.mounted) return;
  messenger.removeCurrentSnackBar();
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
              label: undoLabel,
              textColor: AppColors.bg(context),
              onPressed: onUndo,
            )
          : null,
    ),
  );
}
