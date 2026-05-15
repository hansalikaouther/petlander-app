import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/preferences_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(themeModeProvider);
    final email = ref.watch(currentAuthUserProvider)?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _header(user, email),
            const SizedBox(height: 24),
            _section('Compte', [
              _tile(Icons.edit_outlined, 'Modifier mes informations',
                  onTap: () => _editProfile(context, ref, user)),
              _tile(Icons.lock_reset, 'Changer le mot de passe',
                  onTap: () => context.push(AppRoutes.changePassword)),
              _tile(Icons.medical_services_outlined, 'Mes vétérinaires',
                  onTap: () => context.push(AppRoutes.vets)),
              _tile(Icons.notifications_outlined, 'Notifications',
                  onTap: () => context.push(AppRoutes.notifications)),
            ]),
            _section('Préférences', [
              SwitchListTile(
                value: mode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                title: const Text('Mode sombre'),
                secondary: Icon(mode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
              ),
              _RegionTile(),
              _LanguageTile(),
            ]),
            _section('À propos', [
              _tile(Icons.info_outline, 'À propos de Petlander',
                  subtitle: 'Version 1.0.0',
                  onTap: () => context.push(AppRoutes.about)),
              _tile(Icons.favorite_outline, 'Track, Care And Love'),
            ]),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Se déconnecter',
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
            const SizedBox(height: 16),
            // Suppression définitive du compte
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever, color: AppColors.danger),
              label: const Text('Supprimer mon compte',
                  style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(AppUser? user, String? email) {
    final initial = (user?.nom.isNotEmpty ?? false)
        ? user!.nom.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.55),
            AppColors.secondary.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: 'user_avatar',
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.primaryDark,
                child: Text(initial,
                    style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(user?.nom ?? 'Utilisateur',
              style: AppTextStyles.headlineLarge.copyWith(color: Colors.white)),
          if (email != null)
            Text(email,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
            child: Text(title.toUpperCase(),
                style: AppTextStyles.caption.copyWith(letterSpacing: 1.2)),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer définitivement ton compte ?',
      message:
          'Tous tes animaux, vaccins, RDV, documents et données seront DÉFINITIVEMENT supprimés. Cette action est IRRÉVERSIBLE.',
      confirmLabel: 'Oui, supprimer',
      icon: Icons.delete_forever,
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Compte supprimé. À bientôt.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go(AppRoutes.login);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _editProfile(BuildContext context, WidgetRef ref, AppUser? user) {
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _adresseCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.user.nom);
    _phoneCtrl = TextEditingController(text: widget.user.numeroTelephone ?? '');
    _adresseCtrl = TextEditingController(text: widget.user.adresse ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _phoneCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.user.copyWith(
        nom: _nomCtrl.text.trim(),
        numeroTelephone: _phoneCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
      );
      await ref.read(authRepositoryProvider).updateProfile(updated);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modifier mon profil', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adresseCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Enregistrer',
            icon: Icons.check,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Tuile Région : ouvre une feuille de sélection avec drapeaux.
class _RegionTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    return ListTile(
      leading: const Icon(Icons.public, color: AppColors.primaryDark),
      title: const Text('Région'),
      subtitle: Text('${prefs.region.flag}  ${prefs.region.label}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openSheet(context, ref, prefs.region),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, AppRegion current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choisis ta région',
                  style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 8),
            RadioGroup<AppRegion>(
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                ref.read(userPreferencesProvider.notifier).setRegion(v);
                Navigator.pop(context);
              },
              child: Column(
                children: AppRegion.values
                    .map((r) => RadioListTile<AppRegion>(
                          value: r,
                          title: Text('${r.flag}  ${r.label}'),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Tuile Langue : ouvre une feuille de sélection avec drapeaux.
class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.primaryDark),
      title: const Text('Langue'),
      subtitle: Text('${prefs.language.flag}  ${prefs.language.label}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openSheet(context, ref, prefs.language),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, AppLanguage current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choisis ta langue',
                  style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 8),
            RadioGroup<AppLanguage>(
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                ref.read(userPreferencesProvider.notifier).setLanguage(v);
                Navigator.pop(context);
              },
              child: Column(
                children: AppLanguage.values
                    .map((l) => RadioListTile<AppLanguage>(
                          value: l,
                          title: Text('${l.flag}  ${l.label}'),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'ℹ️ La locale change immédiatement (calendriers, dates). Le contenu de l\'app est en français uniquement.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
