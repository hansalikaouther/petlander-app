import 'dart:io';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/document_medical.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/documents_providers.dart';

class DocumentsScreen extends ConsumerWidget {
  final String animalId;
  const DocumentsScreen({super.key, required this.animalId});

  static const _types = [
    'Ordonnance',
    'Résultat d\'examen',
    'Certificat',
    'Radio / imagerie',
    'Facture',
    'Autre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(documentsByAnimalProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Documents médicaux')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDocument(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(documentsByAnimalProvider(animalId)),
        child: async.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.folder_open,
                  title: 'Aucun document',
                  subtitle: 'Stocke ordonnances, certificats et résultats',
                ),
              ]);
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 50 * i),
                child: _DocumentCard(doc: list[i], animalId: animalId),
              ),
            );
          },
        ),
      ),
    );
  }

  void _addDocument(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddDocumentSheet(
        animalId: animalId,
        types: _types,
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final DocumentMedical doc;
  final String animalId;
  const _DocumentCard({required this.doc, required this.animalId});

  Future<void> _open() async {
    final uri = Uri.parse(doc.fichierUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer ce document ?',
      message: '"${doc.titre}" sera supprimé définitivement.',
      icon: Icons.delete_outline,
      isDestructive: true,
      confirmLabel: 'Supprimer',
    );
    if (ok != true) return;
    try {
      await ref.read(documentRepositoryProvider).delete(doc.id);
      ref.invalidate(documentsByAnimalProvider(animalId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Document supprimé'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  doc.isImage
                      ? CachedNetworkImage(
                          imageUrl: doc.fichierUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1)),
                          errorWidget: (_, _, _) => _placeholderIcon(),
                        )
                      : _placeholderIcon(),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 20),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.titre,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (doc.typeDocument != null)
                    Text(doc.typeDocument!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.description, size: 56, color: AppColors.primaryDark),
      ),
    );
  }
}

class _AddDocumentSheet extends ConsumerStatefulWidget {
  final String animalId;
  final List<String> types;
  const _AddDocumentSheet({required this.animalId, required this.types});

  @override
  ConsumerState<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends ConsumerState<_AddDocumentSheet> {
  final _titreCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedType;
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExt;
  bool _saving = false;

  Future<void> _pickFile() async {
    try {
      // withData: true → indispensable pour Web (path est null sur web)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      Uint8List? bytes = f.bytes;
      // Sur mobile, .bytes peut être null si withData n'est pas supporté → on lit le path.
      if (bytes == null && f.path != null && !kIsWeb) {
        bytes = await File(f.path!).readAsBytes();
      }
      if (bytes == null) {
        Fluttertoast.showToast(
            msg: 'Impossible de lire le fichier',
            backgroundColor: AppColors.danger);
        return;
      }
      setState(() {
        _fileBytes = bytes;
        _fileName = f.name;
        _fileExt = (f.extension ?? f.name.split('.').last).toLowerCase();
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Erreur sélection : $e', backgroundColor: AppColors.danger);
    }
  }

  Future<void> _save() async {
    if (_fileBytes == null || _fileExt == null) {
      Fluttertoast.showToast(msg: 'Sélectionne un fichier', backgroundColor: AppColors.danger);
      return;
    }
    if (_titreCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Titre requis', backgroundColor: AppColors.danger);
      return;
    }
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(documentRepositoryProvider);
      final url = await repo.uploadBytes(_fileBytes!, _fileExt!, user.id);
      await repo.create(DocumentMedical(
        id: '',
        idAnimal: widget.animalId,
        titre: _titreCtrl.text.trim(),
        typeDocument: _selectedType,
        fichierUrl: url,
        dateDocument: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      ref.invalidate(documentsByAnimalProvider(widget.animalId));
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: 'Document ajouté ✓',
          backgroundColor: AppColors.success,
          textColor: Colors.white,
        );
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nouveau document', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: Icon(_fileBytes == null ? Icons.upload_file : Icons.check),
              label: Text(_fileBytes == null
                  ? 'Choisir un fichier (PDF/image)'
                  : (_fileName ?? 'Fichier sélectionné')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: widget.types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
