import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/allergie.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/allergies_providers.dart';

const _allergiesPredefinies = [
  'Allergie alimentaire (poulet)',
  'Allergie alimentaire (bœuf)',
  'Allergie alimentaire (agneau)',
  'Allergie alimentaire (poisson)',
  'Allergie alimentaire (produits laitiers)',
  'Allergie alimentaire (gluten/blé)',
  'Allergie aux puces (DAPP)',
  'Allergie au pollen',
  'Allergie aux acariens',
  'Allergie aux moisissures',
  'Allergie au latex',
  'Allergie médicamenteuse',
  'Allergie aux produits de nettoyage',
  'Allergie aux acariens de stockage',
];

class AllergiesScreen extends ConsumerWidget {
  final String animalId;
  const AllergiesScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(animalAllergiesProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Allergies')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(animalAllergiesProvider(animalId)),
        child: list.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.healing,
                title: 'Aucune allergie connue',
                subtitle: 'Bonne nouvelle ! Ajoute-en une si nécessaire.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 60 * i),
                child: _AllergieCard(
                  item: items[i],
                  onDelete: () => _delete(context, ref, items[i]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, AnimalAllergie item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette allergie ?'),
        content: Text('${item.nom} sera retirée de l\'animal.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(allergieRepositoryProvider).detachFromAnimal(
            animalId: animalId,
            allergieId: item.idAllergie,
          );
      ref.invalidate(animalAllergiesProvider(animalId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Allergie retirée'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddAllergieSheet(animalId: animalId),
    );
  }
}

class _AllergieCard extends StatelessWidget {
  final AnimalAllergie item;
  final VoidCallback onDelete;
  const _AllergieCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.25),
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger),
        ),
        title: Text(item.nom,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.observation != null) Text(item.observation!),
            if (item.dateDetection != null)
              Text('Détectée : ${dateFmt.format(item.dateDetection!)}',
                  style: AppTextStyles.caption),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text('Notes : ${item.notes!}',
                  style: AppTextStyles.caption),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _AddAllergieSheet extends ConsumerStatefulWidget {
  final String animalId;
  const _AddAllergieSheet({required this.animalId});

  @override
  ConsumerState<_AddAllergieSheet> createState() => _AddAllergieSheetState();
}

class _AddAllergieSheetState extends ConsumerState<_AddAllergieSheet> {
  final _customCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedPredefined;
  bool _isAutre = false;
  DateTime? _dateDetection;
  bool _saving = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _nomFinal =>
      _isAutre ? _customCtrl.text.trim() : (_selectedPredefined ?? '');

  Future<void> _save() async {
    final nom = _nomFinal;
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionne ou indique une allergie'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(allergieRepositoryProvider);
      // Cherche dans le catalogue existant (correspondance exacte)
      final catalog = await repo.fetchCatalog();
      final existing = catalog.where(
          (a) => a.nom.toLowerCase() == nom.toLowerCase()).firstOrNull;
      final id = existing?.id ?? await repo.createInCatalog(nom, null);
      await repo.attachToAnimal(
        animalId: widget.animalId,
        allergieId: id,
        dateDetection: _dateDetection,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      ref.invalidate(animalAllergiesProvider(widget.animalId));
      ref.invalidate(allergieCatalogProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Allergie ajoutée ✓'),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ajouter une allergie', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('Sélectionne dans la liste ou choisis "Autre"',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            // Liste déroulante prédéfinie
            DropdownButtonFormField<String>(
              key: ValueKey(_isAutre ? 'autre' : (_selectedPredefined ?? '')),
              initialValue: _isAutre ? 'autre' : _selectedPredefined,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Allergie *',
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
              hint: const Text('Sélectionner une allergie'),
              items: [
                ..._allergiesPredefinies.map((a) =>
                    DropdownMenuItem(value: a, child: Text(a))),
                const DropdownMenuItem(
                  value: 'autre',
                  child: Text('Autre / Personnalisé',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ],
              onChanged: (v) => setState(() {
                if (v == 'autre') {
                  _isAutre = true;
                  _selectedPredefined = null;
                } else {
                  _isAutre = false;
                  _selectedPredefined = v;
                  _customCtrl.clear();
                }
              }),
            ),
            // Champ texte libre si "Autre"
            if (_isAutre) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Précise l\'allergie *',
                  prefixIcon: Icon(Icons.edit_outlined),
                  hintText: 'Ex : Allergie aux arachides',
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Date de détection
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4))),
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_dateDetection == null
                  ? 'Date de détection (optionnel)'
                  : DateFormat('dd/MM/yyyy').format(_dateDetection!)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateDetection = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.notes_outlined),
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
