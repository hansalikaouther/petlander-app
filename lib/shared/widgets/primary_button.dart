import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Bouton principal pastel avec gradient et état de chargement.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.secondaryDark],
                ),
          color: disabled ? AppColors.primary.withValues(alpha: 0.4) : null,
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
