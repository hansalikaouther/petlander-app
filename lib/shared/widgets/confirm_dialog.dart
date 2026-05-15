import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Dialog générique de confirmation avec icône et bouton dangereux.
/// Retourne `true` si l'utilisateur confirme, `false` ou `null` sinon.
///
/// Usage :
/// ```dart
/// final ok = await ConfirmDialog.show(
///   context: context,
///   title: 'Supprimer cet animal ?',
///   message: 'Cette action est irréversible.',
///   confirmLabel: 'Supprimer',
///   isDestructive: true,
/// );
/// if (ok == true) { /* delete */ }
/// ```
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    IconData icon = Icons.help_outline,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.danger : AppColors.primaryDark)
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 36,
              color: isDestructive
                  ? AppColors.danger
                  : AppColors.primaryDark),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.danger : AppColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Bouton menu "more_vert" qui ouvre un PopupMenu avec Modifier / Supprimer.
/// Affichez-le dans le `trailing` d'un ListTile ou d'une Card.
class ItemActionsMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;

  const ItemActionsMenu({
    super.key,
    this.onEdit,
    this.onDelete,
    this.editLabel = 'Modifier',
    this.deleteLabel = 'Supprimer',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Text(editLabel),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: 10),
                Text(deleteLabel,
                    style: const TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
      ],
    );
  }
}
