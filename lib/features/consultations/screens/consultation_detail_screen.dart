import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/consultation.dart';
import '../../../shared/models/examen.dart';
import '../../../shared/models/traitement.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../auth/providers/auth_providers.dart';
import '../../treatments/providers/treatments_providers.dart';
import '../providers/consultations_providers.dart';
import '../providers/examens_providers.dart';

class ConsultationDetailScreen extends ConsumerWidget {
  final String consultationId;
  final String animalId;
  const ConsultationDetailScreen({
    super.key,
    required this.consultationId,
    required this.animalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationAsync = ref.watch(consultationDetailProvider(consultationId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: consultationAsync.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (c) => _buildContent(context, ref, c),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Consultation c) {
    final dateFmt = DateFormat('EEEE d MMMM yyyy • HH:mm', 'fr_FR');
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // En-tête principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.4),
                AppColors.secondary.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.motif ?? 'Consultation',
                  style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Text(dateFmt.format(c.dateConsultation),
                  style: AppTextStyles.bodySmall),
              if (c.veterinaireNom != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('Dr ${c.veterinaireNom}', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (c.diagnostic != null) _section('Diagnostic', c.diagnostic!),
        if (c.observation != null) _section('Observations', c.observation!),
        if (c.poids != null || c.taille != null || c.temperature != null)
          _measurementsCard(c),
        const SizedBox(height: 24),
        _treatmentsSection(context, ref),
        const SizedBox(height: 24),
        _examsSection(context, ref),
      ],
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(content, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _measurementsCard(Consultation c) {
    final items = <Widget>[];
    if (c.poids != null) {
      items.add(_metric(Icons.monitor_weight_outlined,
          '${c.poids!.toStringAsFixed(1)} kg', 'Poids'));
    }
    if (c.taille != null) {
      items.add(_metric(Icons.straighten,
          '${c.taille!.toStringAsFixed(1)} cm', 'Taille'));
    }
    if (c.temperature != null) {
      items.add(_metric(Icons.thermostat,
          '${c.temperature!.toStringAsFixed(1)}°C', 'Température'));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: items
            .map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: m,
                )))
            .toList(),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentDark),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _treatmentsSection(BuildContext context, WidgetRef ref) {
    final async = ref.watch(treatmentsByConsultationProvider(consultationId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Traitements', style: AppTextStyles.headlineMedium)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              onPressed: () => _addTreatmentDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Erreur : $e'),
          data: (list) => list.isEmpty
              ? Text('Aucun traitement', style: AppTextStyles.bodySmall)
              : Column(children: list.map((t) => _TreatmentTile(t: t)).toList()),
        ),
      ],
    );
  }

  Widget _examsSection(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examensByConsultationProvider(consultationId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Examens', style: AppTextStyles.headlineMedium)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              onPressed: () => _addExamDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Erreur : $e'),
          data: (list) => list.isEmpty
              ? Text('Aucun examen', style: AppTextStyles.bodySmall)
              : Column(children: list.map((e) => _ExamenTile(e: e)).toList()),
        ),
      ],
    );
  }

  void _addTreatmentDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddTreatmentSheet(
        animalId: animalId,
        consultationId: consultationId,
      ),
    );
  }

  void _addExamDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddExamenSheet(consultationId: consultationId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette consultation ?'),
        content: const Text('Les traitements et examens liés seront aussi supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(consultationRepositoryProvider).delete(consultationId);
                ref.invalidate(consultationsByAnimalProvider(animalId));
                if (context.mounted) {
                  Fluttertoast.showToast(
                    msg: 'Supprimée',
                    backgroundColor: AppColors.success,
                    textColor: Colors.white,
                  );
                  context.pop();
                }
              } catch (e) {
                Fluttertoast.showToast(msg: 'Erreur : $e', backgroundColor: AppColors.danger);
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _TreatmentTile extends ConsumerWidget {
  final Traitement t;
  const _TreatmentTile({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    final progress = t.progressRatio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.4),
                  child: const Icon(Icons.medication_outlined,
                      color: AppColors.secondaryDark, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.nomMedicament ?? 'Traitement',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                if (t.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('En cours',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            if (t.posologie != null) ...[
              const SizedBox(height: 6),
              Text(t.posologie!, style: AppTextStyles.bodySmall),
            ],
            if (t.dateDebut != null && t.dateFin != null) ...[
              const SizedBox(height: 8),
              Text('${dateFmt.format(t.dateDebut!)} → ${dateFmt.format(t.dateFin!)}',
                  style: AppTextStyles.caption),
              if (progress != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: AppColors.success,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
            if (t.photoOrdoUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: t.photoOrdoUrl!,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExamenTile extends ConsumerWidget {
  final Examen e;
  const _ExamenTile({required this.e});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.info.withValues(alpha: 0.3),
          child: const Icon(Icons.science_outlined, color: AppColors.info),
        ),
        title: Text(e.typeExamen,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${dateFmt.format(e.date)}${e.compteRendu != null ? "\n${e.compteRendu}" : ""}',
            style: AppTextStyles.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
        isThreeLine: e.compteRendu != null,
      ),
    );
  }
}

// ===== Sheets pour ajout rapide =====

class _AddTreatmentSheet extends ConsumerStatefulWidget {
  final String animalId;
  final String consultationId;
  const _AddTreatmentSheet({required this.animalId, required this.consultationId});

  @override
  ConsumerState<_AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends ConsumerState<_AddTreatmentSheet> {
  final _nomCtrl = TextEditingController();
  final _posologieCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  DateTime _debut = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 7));
  File? _photoFile;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photoFile = File(picked.path));
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Nom du médicament requis', backgroundColor: AppColors.danger);
      return;
    }
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(treatmentRepositoryProvider);
      String? ordoUrl;
      if (_photoFile != null) {
        ordoUrl = await repo.uploadOrdo(_photoFile!, user.id);
      }
      final t = Traitement(
        id: '',
        idAnimal: widget.animalId,
        idConsultation: widget.consultationId,
        nomMedicament: _nomCtrl.text.trim(),
        posologie: _posologieCtrl.text.trim().isEmpty ? null : _posologieCtrl.text.trim(),
        dureeTraitement: _dureeCtrl.text.trim().isEmpty ? null : _dureeCtrl.text.trim(),
        dateDebut: _debut,
        dateFin: _fin,
        photoOrdoUrl: ordoUrl,
      );
      await repo.create(t);
      ref.invalidate(treatmentsByConsultationProvider(widget.consultationId));
      ref.invalidate(treatmentsByAnimalProvider(widget.animalId));
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: 'Traitement ajouté ✓',
            backgroundColor: AppColors.success, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Erreur : $e', backgroundColor: AppColors.danger);
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
            Text('Nouveau traitement', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Médicament *',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _posologieCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Posologie',
                prefixIcon: Icon(Icons.list_alt),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dureeCtrl,
              decoration: const InputDecoration(
                labelText: 'Durée (texte libre)',
                prefixIcon: Icon(Icons.timer_outlined),
                hintText: 'Ex : 7 jours',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _debut,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (p != null) setState(() => _debut = p);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Début'),
                      child: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(_debut)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _fin,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (p != null) setState(() => _fin = p);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fin'),
                      child: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(_fin)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: Icon(_photoFile == null ? Icons.add_a_photo_outlined : Icons.check),
              label: Text(_photoFile == null ? 'Photo ordonnance' : 'Photo sélectionnée'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddExamenSheet extends ConsumerStatefulWidget {
  final String consultationId;
  const _AddExamenSheet({required this.consultationId});

  @override
  ConsumerState<_AddExamenSheet> createState() => _AddExamenSheetState();
}

class _AddExamenSheetState extends ConsumerState<_AddExamenSheet> {
  final _typeCtrl = TextEditingController();
  final _crCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  Future<void> _save() async {
    if (_typeCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Type d\'examen requis', backgroundColor: AppColors.danger);
      return;
    }
    setState(() => _saving = true);
    try {
      final e = Examen(
        id: '',
        idConsultation: widget.consultationId,
        typeExamen: _typeCtrl.text.trim(),
        date: _date,
        compteRendu: _crCtrl.text.trim().isEmpty ? null : _crCtrl.text.trim(),
      );
      await ref.read(examenRepositoryProvider).create(e);
      ref.invalidate(examensByConsultationProvider(widget.consultationId));
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: 'Examen ajouté ✓',
            backgroundColor: AppColors.success, textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Erreur : $e', backgroundColor: AppColors.danger);
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
          Text('Nouvel examen', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _typeCtrl,
            decoration: const InputDecoration(
              labelText: 'Type d\'examen *',
              prefixIcon: Icon(Icons.science_outlined),
              hintText: 'Ex : Prise de sang, Radio, Échographie...',
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
          TextField(
            controller: _crCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Compte rendu',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
