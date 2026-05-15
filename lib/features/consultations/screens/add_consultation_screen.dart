import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/consultation.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../veterinarians/providers/vets_providers.dart';
import '../providers/consultations_providers.dart';

const _motifSuggestions = [
  'Consultation annuelle',
  'Vaccination',
  'Urgence / Douleur',
  'Blessure / Plaie',
  'Diarrhée / Vomissements',
  'Problème dermatologique',
  'Problème respiratoire',
  'Contrôle post-opératoire',
  'Stérilisation / Castration',
  'Soins dentaires',
  'Parasites (puces / tiques)',
  'Problème oculaire',
  'Problème auriculaire',
  'Trouble comportemental',
];
const _autreMotif = '__autre__';

class AddConsultationScreen extends ConsumerStatefulWidget {
  final String animalId;
  const AddConsultationScreen({super.key, required this.animalId});

  @override
  ConsumerState<AddConsultationScreen> createState() => _AddConsultationScreenState();
}

class _AddConsultationScreenState extends ConsumerState<AddConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifCustomCtrl = TextEditingController();
  final _diagnosticCtrl = TextEditingController();
  final _observationCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();

  String? _selectedMotif;
  bool _isCustomMotif = false;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  Veterinaire? _selectedVet;
  bool _saving = false;

  @override
  void dispose() {
    _motifCustomCtrl.dispose();
    _diagnosticCtrl.dispose();
    _observationCtrl.dispose();
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  DateTime get _dateTime => DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String? get _motifValue {
    if (_isCustomMotif) {
      final t = _motifCustomCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return (_selectedMotif == null || _selectedMotif == _autreMotif)
        ? null
        : _selectedMotif;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final c = Consultation(
        id: '',
        idAnimal: widget.animalId,
        idVeterinaire: _selectedVet?.id,
        dateConsultation: _dateTime,
        motif: _motifValue,
        diagnostic: _diagnosticCtrl.text.trim().isEmpty ? null : _diagnosticCtrl.text.trim(),
        observation: _observationCtrl.text.trim().isEmpty ? null : _observationCtrl.text.trim(),
        poids: double.tryParse(_poidsCtrl.text.replaceAll(',', '.')),
        taille: double.tryParse(_tailleCtrl.text.replaceAll(',', '.')),
        temperature: double.tryParse(_tempCtrl.text.replaceAll(',', '.')),
      );
      await ref.read(consultationRepositoryProvider).create(c);
      ref.invalidate(consultationsByAnimalProvider(widget.animalId));

      // Enregistre dans le centre de notifications
      final user = ref.read(currentAuthUserProvider);
      if (user != null) {
        try {
          await NotificationsRepository().create(
            userId: user.id,
            titre: 'Consultation enregistrée',
            contenu: _motifValue != null
                ? '${_motifValue!} — ${DateFormat('dd/MM/yyyy', 'fr_FR').format(_dateTime)}'
                : DateFormat('dd/MM/yyyy', 'fr_FR').format(_dateTime),
            type: 'consultation',
          );
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Consultation enregistrée'),
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
    final vetsAsync = ref.watch(vetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle consultation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    const DropdownMenuItem<Veterinaire?>(value: null, child: Text('Aucun')),
                    ...vets.map((v) => DropdownMenuItem<Veterinaire?>(
                          value: v,
                          child: Text('Dr ${v.nom}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedVet = v),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormat('dd MMM yyyy', 'fr_FR').format(_date),
                            style: AppTextStyles.bodyMedium),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_time.format(context),
                            style: AppTextStyles.bodyMedium),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ─── Motif avec suggestions ───
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedMotif),
                initialValue: _selectedMotif,
                decoration: const InputDecoration(
                  labelText: 'Motif *',
                  prefixIcon: Icon(Icons.subject),
                ),
                isExpanded: true,
                items: [
                  ..._motifSuggestions.map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))),
                  const DropdownMenuItem(
                    value: _autreMotif,
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Autre / Personnalisé'),
                    ]),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _selectedMotif = v;
                  _isCustomMotif = (v == _autreMotif);
                }),
                validator: (v) => v == null ? 'Sélectionne un motif' : null,
              ),
              if (_isCustomMotif) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _motifCustomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motif personnalisé *',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Saisis le motif' : null,
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _diagnosticCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Diagnostic',
                  prefixIcon: Icon(Icons.assignment_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observationCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observations',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Text('Mesures cliniques',
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _poidsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Poids (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        hintText: 'ex : 4.5',
                      ),
                      validator: Validators.weight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tailleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Taille (cm)',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tempCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Temp (°C)',
                        prefixIcon: Icon(Icons.thermostat),
                        hintText: '35 – 43',
                      ),
                      validator: Validators.temperature,
                    ),
                  ),
                ],
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
