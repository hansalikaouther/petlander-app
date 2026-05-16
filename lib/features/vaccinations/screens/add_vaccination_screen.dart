import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/vaccination.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../animals/providers/animals_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../providers/vaccinations_providers.dart';

const _autreVaccin = '__autre__';

class AddVaccinationScreen extends ConsumerStatefulWidget {
  final String animalId;
  /// Optionnel : ID d'un vaccin du référentiel à pré-sélectionner (utilisé
  /// quand on arrive depuis l'écran "Vaccins recommandés").
  final String? prefilledVaccinId;
  const AddVaccinationScreen({
    super.key,
    required this.animalId,
    this.prefilledVaccinId,
  });

  @override
  ConsumerState<AddVaccinationScreen> createState() =>
      _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends ConsumerState<AddVaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lotCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customNomCtrl = TextEditingController();

  VaccinReference? _selectedVaccin;
  bool _isCustomVaccin = false;
  DateTime _dateVaccination = DateTime.now();
  DateTime? _dateRappel;
  bool _saving = false;
  bool _prefilledApplied = false;

  @override
  void dispose() {
    _lotCtrl.dispose();
    _notesCtrl.dispose();
    _customNomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isRappel}) async {
    final init = isRappel
        ? (_dateRappel ?? DateTime.now().add(const Duration(days: 365)))
        : _dateVaccination;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isRappel) {
          _dateRappel = picked;
        } else {
          _dateVaccination = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final nomVaccin = _isCustomVaccin
          ? _customNomCtrl.text.trim()
          : _selectedVaccin?.nomVaccin;

      final v = Vaccination(
        id: '',
        idAnimal: widget.animalId,
        idVaccin: _isCustomVaccin ? null : _selectedVaccin?.id,
        nomVaccin: nomVaccin,
        dateVaccination: _dateVaccination,
        dateRappel: _dateRappel,
        lotVaccin: _lotCtrl.text.trim().isEmpty ? null : _lotCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final created = await ref.read(vaccinationRepositoryProvider).create(v);
      ref.invalidate(vaccinationsByAnimalProvider(widget.animalId));

      // Notification locale 7 jours avant le rappel
      if (created.dateRappel != null) {
        final notifAt =
            created.dateRappel!.subtract(const Duration(days: 7));
        if (notifAt.isAfter(DateTime.now())) {
          await NotificationService.schedule(
            id: created.id.hashCode,
            title: 'Rappel vaccin dans 7 jours',
            body:
                '${created.nomVaccin ?? "Vaccin"} à renouveler le ${DateFormat('dd/MM/yyyy', 'fr_FR').format(created.dateRappel!)}',
            scheduledAt:
                DateTime(notifAt.year, notifAt.month, notifAt.day, 9, 0),
          );
        }
      }

      // Enregistre dans le centre de notifications
      final user = ref.read(currentAuthUserProvider);
      if (user != null) {
        try {
          await NotificationsRepository().create(
            userId: user.id,
            titre: 'Vaccin enregistré : ${nomVaccin ?? "Vaccin"}',
            contenu: created.dateRappel != null
                ? 'Rappel prévu le ${DateFormat('dd/MM/yyyy', 'fr_FR').format(created.dateRappel!)}'
                : null,
            type: 'vaccin',
          );
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vaccin enregistré'),
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
    final animalAsync = ref.watch(animalDetailProvider(widget.animalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau vaccin')),
      body: animalAsync.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (animal) {
          final referencesAsync =
              ref.watch(vaccinReferencesProvider(animal.type.dbValue));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Dropdown vaccins + option Autre ───
                  referencesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur référentiel : $e'),
                    data: (refs) {
                      // Pré-remplir si on vient de "Vaccins recommandés"
                      if (!_prefilledApplied &&
                          widget.prefilledVaccinId != null &&
                          _selectedVaccin == null) {
                        final match = refs.where(
                            (r) => r.id == widget.prefilledVaccinId).firstOrNull;
                        if (match != null) {
                          _prefilledApplied = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _selectedVaccin = match;
                              if (match.dureeValiditeMois != null) {
                                _dateRappel = DateTime(
                                  _dateVaccination.year,
                                  _dateVaccination.month +
                                      match.dureeValiditeMois!,
                                  _dateVaccination.day,
                                );
                              }
                            });
                          });
                        }
                      }
                      return DropdownButtonFormField<String>(
                      key: ValueKey(
                          _isCustomVaccin ? _autreVaccin : _selectedVaccin?.id),
                      initialValue:
                          _isCustomVaccin ? _autreVaccin : _selectedVaccin?.id,
                      decoration: const InputDecoration(
                        labelText: 'Vaccin *',
                        prefixIcon: Icon(Icons.vaccines),
                      ),
                      isExpanded: true,
                      items: [
                        ...refs.map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.nomVaccin,
                                  overflow: TextOverflow.ellipsis),
                            )),
                        const DropdownMenuItem(
                          value: _autreVaccin,
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Autre / Personnalisé'),
                          ]),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == _autreVaccin) {
                          setState(() {
                            _isCustomVaccin = true;
                            _selectedVaccin = null;
                          });
                        } else {
                          final ref2 = refs.firstWhere((r) => r.id == val);
                          setState(() {
                            _isCustomVaccin = false;
                            _selectedVaccin = ref2;
                            if (ref2.dureeValiditeMois != null &&
                                _dateRappel == null) {
                              _dateRappel = DateTime(
                                _dateVaccination.year,
                                _dateVaccination.month +
                                    ref2.dureeValiditeMois!,
                                _dateVaccination.day,
                              );
                            }
                          });
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Sélectionne un vaccin' : null,
                    );
                    },
                  ),
                  // Champ texte pour vaccin personnalisé
                  if (_isCustomVaccin) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du vaccin *',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ],
                  if (!_isCustomVaccin &&
                      _selectedVaccin?.dureeValiditeMois != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Calculé auto : ${_selectedVaccin!.dureeValiditeMois} mois après vaccination',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  const SizedBox(height: 14),
                  _DatePickerField(
                    label: 'Date de vaccination *',
                    icon: Icons.event,
                    date: _dateVaccination,
                    onTap: () => _pickDate(isRappel: false),
                  ),
                  const SizedBox(height: 14),
                  _DatePickerField(
                    label: 'Date de rappel',
                    icon: Icons.notifications_active_outlined,
                    date: _dateRappel,
                    onTap: () => _pickDate(isRappel: true),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lotCtrl,
                    decoration: const InputDecoration(
                      labelText: 'N° de lot',
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      alignLabelWithHint: true,
                    ),
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
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;
  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(
          date == null
              ? 'Sélectionner'
              : DateFormat('dd MMMM yyyy', 'fr_FR').format(date!),
          style: AppTextStyles.bodyMedium.copyWith(
            color: date == null ? AppColors.textSecondary : null,
          ),
        ),
      ),
    );
  }
}
