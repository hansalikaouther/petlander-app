import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';

/// Indicateur visuel de la force du mot de passe + checklist des règles.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final bool showRules;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showRules = true,
  });

  @override
  Widget build(BuildContext context) {
    final score = Validators.passwordStrength(password);
    final color = _color(score);
    final label = _label(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < score;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
        if (showRules) ...[
          const SizedBox(height: 8),
          _rule('Au moins 8 caractères', password.length >= 8),
          _rule('Une majuscule (A-Z)',
              RegExp(r'[A-Z]').hasMatch(password)),
          _rule('Une minuscule (a-z)',
              RegExp(r'[a-z]').hasMatch(password)),
          _rule('Un chiffre (0-9)', RegExp(r'[0-9]').hasMatch(password)),
        ],
      ],
    );
  }

  Widget _rule(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: ok ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: ok ? AppColors.success : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _color(int score) {
    switch (score) {
      case 0:
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _label(int score) {
    switch (score) {
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Fort';
      case 4:
        return 'Très fort';
      default:
        return '';
    }
  }
}
