import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/vets_providers.dart';

class VetsListScreen extends ConsumerWidget {
  const VetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetsAsync = ref.watch(vetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes vétérinaires')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vets/add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vetsProvider),
        child: vetsAsync.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (vets) {
            if (vets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.medical_services_outlined,
                    title: 'Aucun vétérinaire enregistré',
                    subtitle: 'Ajoute ton vétérinaire pour planifier des rendez-vous',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: vets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 60 * i),
                child: _VetCard(vet: vets[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VetCard extends ConsumerWidget {
  final Veterinaire vet;
  const _VetCard({required this.vet});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr ${vet.nom}', style: AppTextStyles.headlineMedium),
                      if (vet.specialite != null && vet.specialite!.isNotEmpty)
                        Text(vet.specialite!,
                            style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryDark),
                  tooltip: 'Modifier',
                  onPressed: () => _editVet(context, ref, vet),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  tooltip: 'Supprimer',
                  onPressed: () => _confirmDelete(context, ref, vet),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (vet.adresse != null && vet.adresse!.isNotEmpty)
              _infoRow(Icons.location_on_outlined, vet.adresse!),
            if (vet.numeroTelephone != null && vet.numeroTelephone!.isNotEmpty)
              InkWell(
                onTap: () => _call(vet.numeroTelephone!),
                child: _infoRow(
                  Icons.phone_outlined,
                  vet.numeroTelephone!,
                  highlight: true,
                ),
              ),
            if (vet.email != null && vet.email!.isNotEmpty)
              InkWell(
                onTap: () => _email(vet.email!),
                child: _infoRow(Icons.email_outlined, vet.email!, highlight: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: highlight ? AppColors.primaryDark : AppColors.textSecondary,
                decoration: highlight ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Veterinaire vet) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer ce vétérinaire ?',
      message: 'Dr ${vet.nom} sera retiré de ta liste.',
      icon: Icons.delete_outline,
      isDestructive: true,
      confirmLabel: 'Supprimer',
    );
    if (ok != true) return;
    try {
      await ref.read(vetRepositoryProvider).delete(vet.id);
      ref.invalidate(vetsProvider);
      Fluttertoast.showToast(
        msg: 'Vétérinaire supprimé',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Erreur : $e',
        backgroundColor: AppColors.danger,
        textColor: Colors.white,
      );
    }
  }

  void _editVet(BuildContext context, WidgetRef ref, Veterinaire vet) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditVetSheet(vet: vet),
    );
  }
}

class _EditVetSheet extends ConsumerStatefulWidget {
  final Veterinaire vet;
  const _EditVetSheet({required this.vet});

  @override
  ConsumerState<_EditVetSheet> createState() => _EditVetSheetState();
}

class _EditVetSheetState extends ConsumerState<_EditVetSheet> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.vet.nom);
    _specCtrl = TextEditingController(text: widget.vet.specialite ?? '');
    _adresseCtrl = TextEditingController(text: widget.vet.adresse ?? '');
    _phoneCtrl = TextEditingController(text: widget.vet.numeroTelephone ?? '');
    _emailCtrl = TextEditingController(text: widget.vet.email ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _specCtrl.dispose();
    _adresseCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(
          msg: 'Le nom est requis', backgroundColor: AppColors.danger);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(vetRepositoryProvider).update(widget.vet.id, {
        'nom': _nomCtrl.text.trim(),
        'specialite':
            _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
        'adresse':
            _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        'numero_telephone':
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email':
            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      });
      ref.invalidate(vetsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: 'Vétérinaire modifié ✓',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Erreur : $e', backgroundColor: AppColors.danger);
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier le vétérinaire',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specCtrl,
              decoration: const InputDecoration(
                labelText: 'Spécialité',
                prefixIcon: Icon(Icons.medical_services_outlined),
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
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
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
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Enregistrer',
              icon: Icons.check,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
