import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/operation.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../veterinarians/providers/vets_providers.dart';
import '../providers/operations_providers.dart';

const _typeOperationSuggestions = [
  'Stérilisation (femelle)',
  'Castration (mâle)',
  'Ablation de tumeur',
  'Fracture / Orthopédie',
  'Extraction dentaire',
  'Chirurgie digestive',
  'Chirurgie oculaire',
  'Chirurgie cutanée',
  'Amputation',
  'Laparotomie exploratrice',
  'Hernie',
  'Calculs urinaires',
];
const _autreTypeOp = '__autre__';

class OperationsScreen extends ConsumerWidget {
  final String animalId;
  const OperationsScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(operationsByAnimalProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Opérations chirurgicales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOperation(context, ref, animalId),
        icon: const Icon(Icons.add),
        label: const Text('Opération'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(operationsByAnimalProvider(animalId)),
        child: async.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.healing,
                  title: 'Aucune opération',
                  subtitle: 'Enregistre la première opération chirurgicale',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 50 * i),
                child: _OperationCard(op: list[i], animalId: animalId),
              ),
            );
          },
        ),
      ),
    );
  }

  void _addOperation(BuildContext context, WidgetRef ref, String animalId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddOperationSheet(animalId: animalId),
    );
  }
}

class _OperationCard extends ConsumerWidget {
  final Operation op;
  final String animalId;
  const _OperationCard({required this.op, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.3),
                  child: const Icon(Icons.healing, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(op.typeOperation,
                          style: AppTextStyles.headlineMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text(dateFmt.format(op.dateOperation),
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  onPressed: () async {
                    final ok = await ConfirmDialog.show(
                      context: context,
                      title: 'Supprimer cette opération ?',
                      message:
                          '"${op.typeOperation}" sera retiré de l\'historique chirurgical.',
                      icon: Icons.delete_outline,
                      isDestructive: true,
                      confirmLabel: 'Supprimer',
                    );
                    if (ok != true) return;
                    await ref.read(operationRepositoryProvider).delete(op.id);
                    ref.invalidate(operationsByAnimalProvider(animalId));
                  },
                ),
              ],
            ),
            if (op.duree != null || op.veterinaireNom != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  if (op.duree != null)
                    _chip(Icons.timer_outlined, op.duree!),
                  if (op.veterinaireNom != null)
                    _chip(Icons.person_outline, 'Dr ${op.veterinaireNom}'),
                ],
              ),
            ],
            if (op.compteRendu != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(op.compteRendu!, style: AppTextStyles.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption),
        ],
      );
}

class _AddOperationSheet extends ConsumerStatefulWidget {
  final String animalId;
  const _AddOperationSheet({required this.animalId});

  @override
  ConsumerState<_AddOperationSheet> createState() => _AddOperationSheetState();
}

class _AddOperationSheetState extends ConsumerState<_AddOperationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _typeCustomCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _crCtrl = TextEditingController();

  String? _selectedType;
  bool _isCustomType = false;
  DateTime _date = DateTime.now();
  Veterinaire? _selectedVet;
  bool _saving = false;

  @override
  void dispose() {
    _typeCustomCtrl.dispose();
    _dureeCtrl.dispose();
    _crCtrl.dispose();
    super.dispose();
  }

  String? get _typeValue {
    if (_isCustomType) {
      final t = _typeCustomCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return (_selectedType == null || _selectedType == _autreTypeOp)
        ? null
        : _selectedType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final op = Operation(
        id: '',
        idAnimal: widget.animalId,
        idVeterinaire: _selectedVet?.id,
        typeOperation: _typeValue ?? '',
        dateOperation: _date,
        duree: _dureeCtrl.text.trim().isEmpty ? null : _dureeCtrl.text.trim(),
        compteRendu: _crCtrl.text.trim().isEmpty ? null : _crCtrl.text.trim(),
      );
      await ref.read(operationRepositoryProvider).create(op);
      ref.invalidate(operationsByAnimalProvider(widget.animalId));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(
          content: Text('Opération enregistrée'),
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
    final vetsAsync = ref.watch(vetsProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nouvelle opération', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              // ─── Type d'opération avec suggestions ───
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedType),
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type d\'opération *',
                  prefixIcon: Icon(Icons.healing),
                ),
                isExpanded: true,
                items: [
                  ..._typeOperationSuggestions.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))),
                  const DropdownMenuItem(
                    value: _autreTypeOp,
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Autre / Personnalisé'),
                    ]),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _selectedType = v;
                  _isCustomType = (v == _autreTypeOp);
                }),
                validator: (v) =>
                    v == null ? 'Sélectionne un type d\'opération' : null,
              ),
              if (_isCustomType) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _typeCustomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type personnalisé *',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (v) => Validators.required(v, label: 'Le type'),
                ),
              ],
              const SizedBox(height: 12),
              vetsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (vets) => DropdownButtonFormField<Veterinaire?>(
                  initialValue: _selectedVet,
                  decoration: const InputDecoration(
                    labelText: 'Vétérinaire',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<Veterinaire?>(
                        value: null, child: Text('Aucun')),
                    ...vets.map((v) => DropdownMenuItem<Veterinaire?>(
                          value: v,
                          child: Text('Dr ${v.nom}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedVet = v),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (p != null) setState(() => _date = p);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dureeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Durée',
                  prefixIcon: Icon(Icons.timer_outlined),
                  hintText: 'Ex : 45 min',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _crCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Compte rendu',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  alignLabelWithHint: true,
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
        ),
      ),
    );
  }
}
