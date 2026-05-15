import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/veterinaire.dart';
import '../../../shared/widgets/animal_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../animals/providers/animals_providers.dart';
import '../../appointments/providers/appointments_providers.dart';
import '../../veterinarians/providers/vets_providers.dart';

/// Recherche globale dans l'app : animaux, vétérinaires, RDV.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _match(String? text) {
    if (_query.isEmpty) return false;
    if (text == null) return false;
    return text.toLowerCase().contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final animals = ref.watch(animalsProvider).valueOrNull ?? [];
    final vets = ref.watch(vetsProvider).valueOrNull ?? [];
    final rdvs = ref.watch(appointmentsProvider).valueOrNull ?? [];

    final foundAnimals =
        animals.where((a) => _match(a.nom) || _match(a.race)).toList();
    final foundVets = vets
        .where((v) =>
            _match(v.nom) || _match(v.specialite) || _match(v.adresse))
        .toList();
    final foundRdvs = rdvs
        .where((r) =>
            _match(r.motif) ||
            _match(r.animalNom) ||
            _match(r.veterinaireNom))
        .toList();

    final hasQuery = _query.isNotEmpty;
    final emptyResults = hasQuery &&
        foundAnimals.isEmpty &&
        foundVets.isEmpty &&
        foundRdvs.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un animal, véto, RDV...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: !hasQuery
          ? const EmptyState(
              icon: Icons.search,
              title: 'Recherche globale',
              subtitle:
                  'Tape le nom d\'un animal, d\'un vétérinaire ou\nle motif d\'un rendez-vous',
            )
          : emptyResults
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'Aucun résultat',
                  subtitle: 'Rien trouvé pour "$_query"',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (foundAnimals.isNotEmpty)
                      _section(
                        title: 'Animaux (${foundAnimals.length})',
                        children: foundAnimals
                            .asMap()
                            .entries
                            .map((e) => FadeInLeft(
                                  delay: Duration(milliseconds: 60 * e.key),
                                  child: _AnimalTile(animal: e.value),
                                ))
                            .toList(),
                      ),
                    if (foundVets.isNotEmpty)
                      _section(
                        title: 'Vétérinaires (${foundVets.length})',
                        children: foundVets
                            .asMap()
                            .entries
                            .map((e) => FadeInLeft(
                                  delay: Duration(milliseconds: 60 * e.key),
                                  child: _VetTile(vet: e.value),
                                ))
                            .toList(),
                      ),
                    if (foundRdvs.isNotEmpty)
                      _section(
                        title: 'Rendez-vous (${foundRdvs.length})',
                        children: foundRdvs
                            .asMap()
                            .entries
                            .map((e) => FadeInLeft(
                                  delay: Duration(milliseconds: 60 * e.key),
                                  child: _RdvTile(rdv: e.value),
                                ))
                            .toList(),
                      ),
                  ],
                ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(title.toUpperCase(),
                style: AppTextStyles.caption.copyWith(letterSpacing: 1.2)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  final Animal animal;
  const _AnimalTile({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AnimalIcon(type: animal.type, size: 40),
        title: Text(animal.nom,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
            [animal.type.label, if (animal.race != null) animal.race!]
                .join(' • ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/animals/${animal.id}'),
      ),
    );
  }
}

class _VetTile extends StatelessWidget {
  final Veterinaire vet;
  const _VetTile({required this.vet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.4),
          child: const Icon(Icons.medical_services_outlined,
              color: AppColors.accentDark),
        ),
        title: Text('Dr ${vet.nom}',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (vet.specialite != null) vet.specialite!,
          if (vet.adresse != null) vet.adresse!,
        ].join(' • ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/vets'),
      ),
    );
  }
}

class _RdvTile extends StatelessWidget {
  final Appointment rdv;
  const _RdvTile({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM • HH:mm', 'fr_FR');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.3),
          child: const Icon(Icons.event, color: AppColors.warning),
        ),
        title: Text(rdv.motif ?? 'Consultation',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (rdv.animalNom != null) rdv.animalNom!,
          if (rdv.veterinaireNom != null) 'Dr ${rdv.veterinaireNom}',
          fmt.format(rdv.dateHeure),
        ].join(' • ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/appointments'),
      ),
    );
  }
}
