import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/pet_card.dart';
import '../providers/animals_providers.dart';

class AnimalsListScreen extends ConsumerWidget {
  const AnimalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animals = ref.watch(animalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes animaux')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/animals/add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(animalsProvider),
        child: animals.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.bodyMedium)),
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                title: 'Aucun animal',
                subtitle: 'Ajoute ton premier compagnon avec le bouton +',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 60 * i),
                child: PetCard(
                  animal: list[i],
                  onTap: () => context.push('/animals/${list[i].id}'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
