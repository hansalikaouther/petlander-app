import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/growth_record.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/growth_providers.dart';

class GrowthScreen extends ConsumerWidget {
  final String animalId;
  const GrowthScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(growthByAnimalProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de croissance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeasurement(context, ref, animalId),
        icon: const Icon(Icons.add),
        label: const Text('Mesure'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(growthByAnimalProvider(animalId)),
        child: async.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.show_chart,
                  title: 'Aucune mesure enregistrée',
                  subtitle: 'Pèse ton animal régulièrement pour suivre sa courbe',
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _summaryCards(list),
                const SizedBox(height: 20),
                _chartCard(context, 'Poids (kg)', list, (g) => g.poids, AppColors.primary),
                const SizedBox(height: 20),
                _chartCard(context, 'Taille (cm)', list, (g) => g.taille, AppColors.accent),
                const SizedBox(height: 20),
                Text('Historique', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                ...list.reversed.map((g) => _GrowthTile(record: g, animalId: animalId)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addMeasurement(BuildContext context, WidgetRef ref, String animalId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGrowthSheet(animalId: animalId),
    );
  }

  Widget _summaryCards(List<GrowthRecord> list) {
    final lastWithWeight = list.lastWhereOrNull((g) => g.poids != null);
    final firstWithWeight = list.firstWhereOrNull((g) => g.poids != null);
    final delta = (lastWithWeight?.poids != null && firstWithWeight?.poids != null)
        ? lastWithWeight!.poids! - firstWithWeight!.poids!
        : null;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Dernière pesée',
            lastWithWeight?.poids != null
                ? '${lastWithWeight!.poids!.toStringAsFixed(1)} kg'
                : '—',
            Icons.monitor_weight_outlined,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Évolution totale',
            delta != null
                ? '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} kg'
                : '—',
            delta != null && delta >= 0 ? Icons.trending_up : Icons.trending_down,
            delta != null && delta >= 0 ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headlineMedium),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, String title, List<GrowthRecord> data,
      double? Function(GrowthRecord) sel, Color color) {
    final points = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final v = sel(data[i]);
      if (v != null) points.add(FlSpot(i.toDouble(), v));
    }

    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart, color: color),
            const SizedBox(width: 8),
            Text('$title — aucune donnée', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    final dateFmt = DateFormat('dd/MM', 'fr_FR');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (data.length / 4).clamp(1, 999).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dateFmt.format(data[i].date),
                              style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T) test) {
    T? found;
    for (final e in this) {
      if (test(e)) found = e;
    }
    return found;
  }
}

// ── Tuile historique ─────────────────────────────────────────────────────────
class _GrowthTile extends ConsumerWidget {
  final GrowthRecord record;
  final String animalId;
  const _GrowthTile({required this.record, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Photo ou icône
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: record.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: record.photoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _photoPlaceholder(),
                      errorWidget: (_, _, _) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFmt.format(record.date),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (record.poids != null)
                        '${record.poids!.toStringAsFixed(1)} kg',
                      if (record.taille != null)
                        '${record.taille!.toStringAsFixed(1)} cm',
                      if (record.obs != null) record.obs!,
                    ].join(' • '),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final ok = await ConfirmDialog.show(
                  context: context,
                  title: 'Supprimer cette mesure ?',
                  message:
                      'La mesure du ${DateFormat('dd MMM yyyy', 'fr_FR').format(record.date)} sera supprimée.',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                  confirmLabel: 'Supprimer',
                );
                if (ok != true) return;
                await ref.read(growthRepositoryProvider).delete(record.id);
                ref.invalidate(growthByAnimalProvider(animalId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.monitor_weight_outlined,
          color: AppColors.primary, size: 28),
    );
  }
}

// ── Sheet ajout mesure ───────────────────────────────────────────────────────
class _AddGrowthSheet extends ConsumerStatefulWidget {
  final String animalId;
  const _AddGrowthSheet({required this.animalId});

  @override
  ConsumerState<_AddGrowthSheet> createState() => _AddGrowthSheetState();
}

class _AddGrowthSheetState extends ConsumerState<_AddGrowthSheet> {
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  Uint8List? _photoBytes;
  String _photoExt = 'jpg';
  bool _saving = false;

  @override
  void dispose() {
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _photoBytes = bytes;
      _photoExt = ext.isEmpty ? 'jpg' : ext;
    });
  }

  Future<String?> _uploadPhoto() async {
    if (_photoBytes == null) return null;
    const uuid = Uuid();
    final path = 'growth/${uuid.v4()}.$_photoExt';
    await SupabaseService.client.storage
        .from('animals')
        .uploadBinary(path, _photoBytes!,
            fileOptions: FileOptions(contentType: 'image/$_photoExt'));
    return SupabaseService.client.storage.from('animals').getPublicUrl(path);
  }

  Future<void> _save() async {
    final poids = double.tryParse(_poidsCtrl.text.replaceAll(',', '.'));
    final taille = double.tryParse(_tailleCtrl.text.replaceAll(',', '.'));
    if (poids == null && taille == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saisis au moins poids ou taille'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final photoUrl = await _uploadPhoto();
      final ic = (poids != null && taille != null && taille > 0)
          ? (poids / ((taille / 100) * (taille / 100)))
          : null;
      final g = GrowthRecord(
        id: '',
        idAnimal: widget.animalId,
        date: _date,
        poids: poids,
        taille: taille,
        indiceCorporel: ic,
        obs: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      await ref.read(growthRepositoryProvider).create(g);
      ref.invalidate(growthByAnimalProvider(widget.animalId));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(
          content: Text('Mesure ajoutée'),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nouvelle mesure', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            // Sélecteur de date
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
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
            // Photo optionnelle
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: _photoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(_photoBytes!, fit: BoxFit.cover,
                            width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppColors.primary, size: 32),
                          const SizedBox(height: 6),
                          Text('Ajouter une photo (optionnel)',
                              style: AppTextStyles.caption),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _poidsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tailleCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Taille (cm)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observations',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Enregistrer',
              icon: Icons.check,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
