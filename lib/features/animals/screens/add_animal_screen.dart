import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/breed_suggestions.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/animals_providers.dart';

class AddAnimalScreen extends ConsumerStatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  ConsumerState<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends ConsumerState<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _raceCtrl = TextEditingController();
  final _couleurCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _puceCtrl = TextEditingController();

  AnimalType _type = AnimalType.chien;
  Sexe _sexe = Sexe.inconnu;
  DateTime? _dateNaissance;
  bool _sterilise = false;
  Uint8List? _photoBytes;
  String _photoExt = 'jpg';
  bool _saving = false;

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(animalRepositoryProvider);
      String? photoUrl;
      if (_photoBytes != null) {
        photoUrl =
            await repo.uploadPhotoBytes(_photoBytes!, _photoExt, user.id);
      }
      final animal = Animal(
        id: '',
        idUtilisateur: user.id,
        nom: _nomCtrl.text.trim(),
        type: _type,
        race: _raceCtrl.text.trim().isEmpty ? null : _raceCtrl.text.trim(),
        dateNaissance: _dateNaissance,
        sexe: _sexe,
        couleur:
            _couleurCtrl.text.trim().isEmpty ? null : _couleurCtrl.text.trim(),
        poidsActuel:
            double.tryParse(_poidsCtrl.text.replaceAll(',', '.')),
        photoUrl: photoUrl,
        numeroPuce:
            _puceCtrl.text.trim().isEmpty ? null : _puceCtrl.text.trim(),
        sterilise: _sterilise,
      );
      final created = await repo.create(animal);
      ref.invalidate(animalsProvider);

      // Programme une notif anniversaire annuelle si date de naissance connue
      if (created.dateNaissance != null) {
        final now = DateTime.now();
        var nextBirthday = DateTime(
          now.year,
          created.dateNaissance!.month,
          created.dateNaissance!.day,
          9,
        );
        if (nextBirthday.isBefore(now)) {
          nextBirthday = DateTime(
              now.year + 1, nextBirthday.month, nextBirthday.day, 9);
        }
        await NotificationService.schedule(
          id: 'bday-${created.id}'.hashCode,
          title: 'Joyeux anniversaire ${created.nom} !',
          body: 'Ton compagnon souffle sa bougie aujourd\'hui !',
          scheduledAt: nextBirthday,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${animal.nom} ajouté(e) ✓'),
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
      appBar: AppBar(title: const Text('Nouvel animal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoPicker(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.pets),
                  hintText: 'ex : Rex, Luna, Mimi...',
                ),
                validator: (v) => Validators.name(v, label: 'Le nom'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AnimalType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AnimalType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v ?? AnimalType.chien;
                  _raceCtrl.clear();
                }),
              ),
              const SizedBox(height: 14),
              _buildBreedAutocomplete(),
              const SizedBox(height: 14),
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
                onChanged: (v) =>
                    setState(() => _sexe = v ?? Sexe.inconnu),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(
                    _dateNaissance == null
                        ? 'Sélectionner'
                        : DateFormat('dd MMMM yyyy', 'fr_FR')
                            .format(_dateNaissance!),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _dateNaissance == null
                          ? AppColors.textSecondary
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _poidsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Poids (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        hintText: 'ex : 4.5',
                      ),
                      validator: Validators.weight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _couleurCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Couleur',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _puceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'N° puce électronique',
                  prefixIcon: Icon(Icons.qr_code_2),
                  hintText: '15 chiffres (ex : 250269802500001)',
                ),
                validator: Validators.chipNumber,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _sterilise,
                onChanged: (v) => setState(() => _sterilise = v),
                title: const Text('Stérilisé(e)'),
                contentPadding: EdgeInsets.zero,
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

  Widget _buildBreedAutocomplete() {
    final suggestions = BreedSuggestions.forType(_type);
    return Autocomplete<String>(
      key: ValueKey('breed_${_type.dbValue}'),
      initialValue: TextEditingValue(text: _raceCtrl.text),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) return suggestions;
        return suggestions.where((b) => b.toLowerCase().contains(query));
      },
      onSelected: (selection) => _raceCtrl.text = selection,
      fieldViewBuilder: (context, controller, focusNode, _) {
        if (controller.text != _raceCtrl.text) {
          controller.text = _raceCtrl.text;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Race (${_type.label})',
            prefixIcon: const Icon(Icons.label_outline),
            hintText: suggestions.isNotEmpty
                ? 'Tape pour rechercher parmi ${suggestions.length} races...'
                : 'Saisir librement',
          ),
          onChanged: (v) => _raceCtrl.text = v,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 220, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Text(opt, style: AppTextStyles.bodyMedium),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2),
            image: _photoBytes != null
                ? DecorationImage(
                    image: MemoryImage(_photoBytes!), fit: BoxFit.cover)
                : null,
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: _photoBytes == null
              ? const Icon(Icons.add_a_photo_outlined,
                  size: 40, color: AppColors.primaryDark)
              : null,
        ),
      ),
    );
  }
}
