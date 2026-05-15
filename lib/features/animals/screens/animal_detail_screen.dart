import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/widgets/animal_icon.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../../consultations/providers/consultations_providers.dart';
import '../../operations/providers/operations_providers.dart';
import '../../vaccinations/providers/vaccinations_providers.dart';
import '../data/health_book_pdf.dart';
import '../providers/animals_providers.dart';

class AnimalDetailScreen extends ConsumerWidget {
  final String animalId;
  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalAsync = ref.watch(animalDetailProvider(animalId));
    return Scaffold(
      body: animalAsync.when(
        loading: () => const Center(child: LoadingPaw()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (animal) => _buildContent(context, ref, animal),
      ),
    );
  }

  LinearGradient _gradientFor(AnimalType type) {
    switch (type) {
      case AnimalType.chien:   return AppColors.gradientChien;
      case AnimalType.chat:    return AppColors.gradientChat;
      case AnimalType.lapin:   return AppColors.gradientLapin;
      case AnimalType.oiseau:  return AppColors.gradientOiseau;
      case AnimalType.rongeur: return AppColors.gradientRongeur;
      case AnimalType.reptile: return AppColors.gradientReptile;
      case AnimalType.autre:   return AppColors.gradientAutre;
    }
  }

  Color _accentFor(AnimalType type) {
    switch (type) {
      case AnimalType.chien:   return AppColors.animalChien;
      case AnimalType.chat:    return AppColors.animalChat;
      case AnimalType.lapin:   return AppColors.animalLapin;
      case AnimalType.oiseau:  return AppColors.animalOiseau;
      case AnimalType.rongeur: return AppColors.animalRongeur;
      case AnimalType.reptile: return AppColors.animalReptile;
      case AnimalType.autre:   return AppColors.animalAutre;
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Animal animal) {
    final gradient = _gradientFor(animal.type);
    final accent   = _accentFor(animal.type);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: accent,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'Exporter le carnet en PDF',
              onPressed: () => _exportPdf(context, ref, animal),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Modifier',
              onPressed: () => _editAnimal(context, ref, animal),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(context, ref, animal),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimalIcon(type: animal.type, size: 32),
                const SizedBox(width: 8),
                Text(animal.nom,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            background: animal.photoUrl != null
                ? CachedNetworkImage(imageUrl: animal.photoUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(gradient: gradient),
                    child: Center(
                      child: AnimalIcon(type: animal.type, size: 120),
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _infoCard(context, [
                _row(Icons.category_outlined, 'Type', animal.type.label),
                if (animal.race != null) _row(Icons.label_outline, 'Race', animal.race!),
                _row(Icons.wc_outlined, 'Sexe', animal.sexe.label),
                if (animal.dateNaissance != null)
                  _row(Icons.cake_outlined, 'Âge',
                      AppDateUtils.ageFromBirthDate(animal.dateNaissance!)),
                if (animal.poidsActuel != null)
                  _row(Icons.monitor_weight_outlined, 'Poids',
                      '${animal.poidsActuel!.toStringAsFixed(1)} kg'),
                if (animal.couleur != null)
                  _row(Icons.palette_outlined, 'Couleur', animal.couleur!),
                if (animal.numeroPuce != null)
                  _row(Icons.qr_code_2, 'N° puce', animal.numeroPuce!),
                _row(animal.sterilise ? Icons.check_circle : Icons.cancel,
                    'Stérilisé', animal.sterilise ? 'Oui' : 'Non'),
              ]),
              const SizedBox(height: 24),
              Text('Suivi médical', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              _medSection(context, animal),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _medSection(BuildContext context, Animal animal) {
    final tiles = [
      _MedTile(Icons.vaccines, 'Vaccinations', AppColors.accent,
          () => context.push('/animals/${animal.id}/vaccinations')),
      _MedTile(Icons.medical_services_outlined, 'Consultations', AppColors.primary,
          () => context.push('/animals/${animal.id}/consultations')),
      _MedTile(Icons.healing, 'Opérations', AppColors.warning,
          () => context.push('/animals/${animal.id}/operations')),
      _MedTile(Icons.show_chart, 'Croissance', AppColors.info,
          () => context.push('/animals/${animal.id}/growth')),
      _MedTile(Icons.folder_outlined, 'Documents', AppColors.secondary,
          () => context.push('/animals/${animal.id}/documents')),
      _MedTile(Icons.warning_amber_rounded, 'Allergies', AppColors.danger,
          () => context.push('/animals/${animal.id}/allergies')),
      _MedTile(Icons.medical_information_outlined, 'Maladies chroniques',
          AppColors.warning,
          () => context.push('/animals/${animal.id}/maladies')),
      _MedTile(Icons.lightbulb_outline, 'Vaccins recommandés',
          AppColors.accentDark,
          () => context.push('/animals/${animal.id}/vaccines/recommended')),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: tiles,
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, Animal animal) async {
    try {
      final vaccinations = await ref.read(vaccinationRepositoryProvider).fetchByAnimal(animal.id);
      final consultations = await ref.read(consultationRepositoryProvider).fetchByAnimal(animal.id);
      final operations = await ref.read(operationRepositoryProvider).fetchByAnimal(animal.id);

      final bytes = await HealthBookPdf.build(
        animal: animal,
        vaccinations: vaccinations,
        consultations: consultations,
        operations: operations,
      );
      if (!context.mounted) return;
      await Printing.layoutPdf(onLayout: (_) async => bytes,
          name: 'carnet-sante-${animal.nom}.pdf');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur PDF : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Animal animal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet animal ?'),
        content: Text('${animal.nom} et tout son historique médical seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(animalRepositoryProvider).delete(animal.id);
                ref.invalidate(animalsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Animal supprimé'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _editAnimal(BuildContext context, WidgetRef ref, Animal animal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditAnimalSheet(animal: animal),
    );
  }
}

class _EditAnimalSheet extends ConsumerStatefulWidget {
  final Animal animal;
  const _EditAnimalSheet({required this.animal});

  @override
  ConsumerState<_EditAnimalSheet> createState() => _EditAnimalSheetState();
}

class _EditAnimalSheetState extends ConsumerState<_EditAnimalSheet> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _raceCtrl;
  late final TextEditingController _couleurCtrl;
  late final TextEditingController _poidsCtrl;
  late final TextEditingController _puceCtrl;
  late AnimalType _type;
  late Sexe _sexe;
  late bool _sterilise;
  late DateTime? _dateNaissance;
  Uint8List? _photoBytes;
  String _photoExt = 'jpg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.animal.nom);
    _raceCtrl = TextEditingController(text: widget.animal.race ?? '');
    _couleurCtrl = TextEditingController(text: widget.animal.couleur ?? '');
    _poidsCtrl = TextEditingController(
        text: widget.animal.poidsActuel?.toString() ?? '');
    _puceCtrl = TextEditingController(text: widget.animal.numeroPuce ?? '');
    _type = widget.animal.type;
    _sexe = widget.animal.sexe;
    _sterilise = widget.animal.sterilise;
    _dateNaissance = widget.animal.dateNaissance;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _raceCtrl.dispose();
    _couleurCtrl.dispose();
    _poidsCtrl.dispose();
    _puceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    setState(() {
      _photoBytes = bytes;
      _photoExt = ext.isEmpty ? 'jpg' : ext;
    });
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le nom est requis'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(animalRepositoryProvider);
      String? photoUrl = widget.animal.photoUrl;
      if (_photoBytes != null) {
        final user = ref.read(currentAuthUserProvider);
        if (user != null) {
          photoUrl =
              await repo.uploadPhotoBytes(_photoBytes!, _photoExt, user.id);
        }
      }
      await repo.update(widget.animal.id, {
        'nom': _nomCtrl.text.trim(),
        'type': _type.dbValue,
        'race': _raceCtrl.text.trim().isEmpty ? null : _raceCtrl.text.trim(),
        'sexe': _sexe.dbValue,
        'couleur':
            _couleurCtrl.text.trim().isEmpty ? null : _couleurCtrl.text.trim(),
        'poids_actuel':
            double.tryParse(_poidsCtrl.text.replaceAll(',', '.')),
        'numero_puce':
            _puceCtrl.text.trim().isEmpty ? null : _puceCtrl.text.trim(),
        'sterilise': _sterilise,
        'date_naissance':
            _dateNaissance?.toIso8601String().split('T').first,
        'photo_url': photoUrl,
      });
      ref.invalidate(animalsProvider);
      ref.invalidate(animalDetailProvider(widget.animal.id));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Animal modifié ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
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

  Widget _buildPhotoPicker() {
    final hasExisting =
        widget.animal.photoUrl != null && widget.animal.photoUrl!.isNotEmpty;
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primaryDark, width: 2),
              ),
              child: ClipOval(
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                    : hasExisting
                        ? CachedNetworkImage(
                            imageUrl: widget.animal.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Icon(
                                Icons.pets,
                                size: 40,
                                color: AppColors.primaryDark),
                            errorWidget: (_, _, _) => const Icon(
                                Icons.pets,
                                size: 40,
                                color: AppColors.primaryDark),
                          )
                        : const Icon(Icons.add_a_photo_outlined,
                            size: 36, color: AppColors.primaryDark),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
            Text('Modifier ${widget.animal.nom}',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            _buildPhotoPicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AnimalType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AnimalType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _raceCtrl,
              decoration: InputDecoration(
                labelText: 'Race (${_type.label})',
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Sexe>(
              initialValue: _sexe,
              decoration: const InputDecoration(
                labelText: 'Sexe',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: Sexe.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _sexe = v ?? _sexe),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _dateNaissance ?? DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                );
                if (p != null) setState(() => _dateNaissance = p);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                child: Text(_dateNaissance == null
                    ? 'Sélectionner'
                    : '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _poidsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _couleurCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Couleur',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _puceCtrl,
              decoration: const InputDecoration(
                labelText: 'N° puce',
                prefixIcon: Icon(Icons.qr_code_2),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _sterilise,
              onChanged: (v) => setState(() => _sterilise = v),
              title: const Text('Stérilisé(e)'),
              contentPadding: EdgeInsets.zero,
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
      ),
    );
  }
}

class _MedTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MedTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
