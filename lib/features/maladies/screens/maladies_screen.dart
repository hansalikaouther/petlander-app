import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/maladie_chronique.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/maladies_providers.dart';

const _maladiesPredefinies = [
  'Diabète',
  'Insuffisance rénale chronique',
  'Arthrose',
  'Épilepsie',
  'Hypothyroïdie',
  'Hyperthyroïdie',
  'Cardiopathie',
  'Insuffisance hépatique',
  'Maladie de Cushing',
  'Maladie d\'Addison',
  'Asthme',
  'Bronchite chronique',
  'Dermatite atopique',
  'Obésité',
  'Anémie chronique',
  'Cancer (préciser en notes)',
  'Cataracte',
  'Glaucome',
];

class MaladiesScreen extends ConsumerWidget {
  final String animalId;
  const MaladiesScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(animalMaladiesProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Maladies chroniques')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(animalMaladiesProvider(animalId)),
        child: list.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.medical_information_outlined,
                title: 'Aucune maladie chronique',
                subtitle: 'Ajoute-en une si nécessaire pour le suivi.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 60 * i),
                child: _MaladieCard(
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
      BuildContext context, WidgetRef ref, AnimalMaladie item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cette maladie ?'),
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
      await ref.read(maladieRepositoryProvider).detachFromAnimal(
            animalId: animalId,
            maladieId: item.idMaladie,
          );
      ref.invalidate(animalMaladiesProvider(animalId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Maladie retirée'),
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
      builder: (_) => _AddMaladieSheet(animalId: animalId),
    );
  }
}

class _MaladieCard extends StatelessWidget {
  final AnimalMaladie item;
  final VoidCallback onDelete;
  const _MaladieCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.25),
          child: const Icon(Icons.medical_information,
              color: AppColors.warning),
        ),
        title: Text(item.nom,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) Text(item.description!),
            if (item.dateDiagnostic != null)
              Text('Diagnostiquée : ${dateFmt.format(item.dateDiagnostic!)}',
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

class _AddMaladieSheet extends ConsumerStatefulWidget {
  final String animalId;
  const _AddMaladieSheet({required this.animalId});

  @override
  ConsumerState<_AddMaladieSheet> createState() => _AddMaladieSheetState();
}

class _AddMaladieSheetState extends ConsumerState<_AddMaladieSheet> {
  final _customCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedPredefined;
  bool _isAutre = false;
  DateTime? _dateDiagnostic;
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
        content: Text('Sélectionne ou indique une maladie'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(maladieRepositoryProvider);
      // Cherche dans le catalogue existant (correspondance exacte)
      final catalog = await repo.fetchCatalog();
      final existing = catalog
          .where((m) => m.nom.toLowerCase() == nom.toLowerCase())
          .firstOrNull;
      final id = existing?.id ?? await repo.createInCatalog(nom, null);
      await repo.attachToAnimal(
        animalId: widget.animalId,
        maladieId: id,
        dateDiagnostic: _dateDiagnostic,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      ref.invalidate(animalMaladiesProvider(widget.animalId));
      ref.invalidate(maladieCatalogProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maladie ajoutée ✓'),
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
            Text('Ajouter une maladie chronique',
                style: AppTextStyles.headlineMedium),
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
                labelText: 'Maladie *',
                prefixIcon: Icon(Icons.medical_information_outlined),
              ),
              hint: const Text('Sélectionner une maladie'),
              items: [
                ..._maladiesPredefinies.map((m) =>
                    DropdownMenuItem(value: m, child: Text(m))),
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
                  labelText: 'Précise la maladie *',
                  prefixIcon: Icon(Icons.edit_outlined),
                  hintText: 'Ex : Leishmaniose, Panleucopénie...',
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Date de diagnostic
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4))),
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_dateDiagnostic == null
                  ? 'Date de diagnostic (optionnel)'
                  : DateFormat('dd/MM/yyyy').format(_dateDiagnostic!)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateDiagnostic = picked);
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
