import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/vets_providers.dart';

class AddVetScreen extends ConsumerStatefulWidget {
  const AddVetScreen({super.key});

  @override
  ConsumerState<AddVetScreen> createState() => _AddVetScreenState();
}

class _AddVetScreenState extends ConsumerState<AddVetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _specialiteCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _specialiteCtrl.dispose();
    _adresseCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final vet = Veterinaire(
        id: '',
        idUtilisateur: user.id,
        nom: _nomCtrl.text.trim(),
        specialite: _specialiteCtrl.text.trim().isEmpty ? null : _specialiteCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        numeroTelephone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      await ref.read(vetRepositoryProvider).create(vet);
      ref.invalidate(vetsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vétérinaire ajouté'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau vétérinaire')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du vétérinaire *',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'ex : Ben Ali Mohamed',
                ),
                validator: (v) => Validators.name(v, label: 'Le nom'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _specialiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Spécialité',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  hintText: 'Ex : généraliste, dermatologie...',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _adresseCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse de la clinique',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'ex : 05 12 34 56 78',
                ),
                validator: Validators.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  return Validators.email(v);
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Enregistrer',
                icon: Icons.check,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
