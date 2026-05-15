import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../animals/providers/animals_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../veterinarians/providers/vets_providers.dart';
import '../providers/appointments_providers.dart';

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

class AddAppointmentScreen extends ConsumerStatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motifCustomCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Animal? _selectedAnimal;
  Veterinaire? _selectedVet;
  String? _selectedMotif;
  bool _isCustomMotif = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  AppointmentStatus _status = AppointmentStatus.planifie;
  bool _enableNotification = true;
  bool _saving = false;

  @override
  void dispose() {
    _motifCustomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  DateTime get _combinedDateTime => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionne un animal'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final apt = Appointment(
        id: '',
        idAnimal: _selectedAnimal!.id,
        idUtilisateur: user.id,
        idVeterinaire: _selectedVet?.id,
        dateHeure: _combinedDateTime,
        motif: _motifValue,
        statut: _status,
        notification: _enableNotification,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      final created = await ref.read(appointmentRepositoryProvider).create(apt);

      // Notification locale 24h avant le RDV
      if (_enableNotification) {
        final notifAt = created.dateHeure.subtract(const Duration(hours: 24));
        if (notifAt.isAfter(DateTime.now())) {
          await NotificationService.schedule(
            id: created.id.hashCode,
            title: 'RDV demain : ${_selectedAnimal!.nom}',
            body: created.motif ??
                'Tu as un rendez-vous vétérinaire prévu demain à ${DateFormat('HH:mm').format(created.dateHeure)}',
            scheduledAt: notifAt,
          );
        }
      }

      // Enregistre dans le centre de notifications Supabase
      try {
        await NotificationsRepository().create(
          userId: user.id,
          titre: 'RDV planifié : ${_selectedAnimal!.nom}',
          contenu:
              '${created.motif ?? "Rendez-vous"} — ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(created.dateHeure)}',
          type: 'rdv',
        );
      } catch (_) {}

      ref.invalidate(appointmentsProvider);
      ref.invalidate(upcomingAppointmentsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rendez-vous enregistré'),
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
    final animalsAsync = ref.watch(animalsProvider);
    final vetsAsync = ref.watch(vetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau rendez-vous')),
      body: animalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (animals) {
          if (animals.isEmpty) {
            return EmptyState(
              icon: Icons.pets,
              title: 'Aucun animal enregistré',
              subtitle: 'Ajoute d\'abord un animal pour planifier un rendez-vous',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Animal>(
                    initialValue: _selectedAnimal,
                    decoration: const InputDecoration(
                      labelText: 'Animal *',
                      prefixIcon: Icon(Icons.pets),
                    ),
                    isExpanded: true,
                    items: animals
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text('${a.nom} (${a.type.label})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAnimal = v),
                    validator: (v) => v == null ? 'Sélectionne un animal' : null,
                  ),
                  const SizedBox(height: 14),
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
                          value: null,
                          child: Text('Aucun'),
                        ),
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
                            child: Text(
                              DateFormat('dd MMM yyyy', 'fr_FR').format(_date),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Heure *',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              _time.format(context),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ─── Motif avec liste déroulante ───
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
                  DropdownButtonFormField<AppointmentStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: AppointmentStatus.values
                        .where((s) => s != AppointmentStatus.passe)
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _status = v ?? AppointmentStatus.planifie),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _enableNotification,
                    onChanged: (v) => setState(() => _enableNotification = v),
                    title: const Text('Rappel 24h avant'),
                    subtitle: const Text('Notification locale automatique'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
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
