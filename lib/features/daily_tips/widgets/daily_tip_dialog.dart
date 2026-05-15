import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../data/daily_tips_database.dart';

/// Dialog modal "Conseil du jour" avec animation, gradient et call-to-action.
class DailyTipDialog extends StatelessWidget {
  final DailyTip tip;
  const DailyTipDialog({super.key, required this.tip});

  static Future<void> show(BuildContext context, DailyTip tip) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DailyTipDialog(tip: tip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ZoomIn(
        duration: const Duration(milliseconds: 350),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.25),
                AppColors.secondary.withValues(alpha: 0.20),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bandeau catégorie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tip.category.label,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Conseil du jour',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                tip.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 14),
              _RichTipText(text: tip.body),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Compris, merci !'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit renderer Markdown léger (gras `**...**` uniquement).
class _RichTipText extends StatelessWidget {
  final String text;
  const _RichTipText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*([^*]+)\*\*');
    var lastEnd = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
        children: spans,
      ),
    );
  }
}
