import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../recipe_extraction/view_model/recipe_extraction_view_model.dart';
import '../../shared/recipe_editor.dart';

class RecipeExtractionScreen extends StatefulWidget {
  const RecipeExtractionScreen({super.key});

  @override
  State<RecipeExtractionScreen> createState() => _RecipeExtractionScreenState();
}

class _RecipeExtractionScreenState extends State<RecipeExtractionScreen> {
  late final RecipeExtractionViewModel _vm;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = RecipeExtractionViewModel();
    _vm.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extract() async => _vm.extract();

  Future<void> _save() async {
    final ok = await _vm.saveCurrent();
    if (!mounted) return;
    if (ok) {
      final id = _vm.recipe!.id;
      // Navigate to detail page
      Navigator.of(context).pushNamed('/recipe', arguments: id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezept gespeichert.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speichern fehlgeschlagen')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keine Bildauswahl getroffen.')));
        return;
      }
      await _vm.setLocalImage(File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bildauswahl fehlgeschlagen: $e')));
    }
  }

  Widget _buildResult() {
    switch (_vm.status) {
      case RecipeExtractionStatus.idle:
        return const Text('Bitte eine Rezept-URL eingeben.');
      case RecipeExtractionStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case RecipeExtractionStatus.error:
        return Text('Fehler: ${_vm.errorMessage}', style: const TextStyle(color: Colors.red));
      case RecipeExtractionStatus.success:
        final r = _vm.recipe!;
        return SingleChildScrollView(
          key: ValueKey('result-${r.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Bild auswählen'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: (r.imagePath != null || (r.imageUrl != null && r.imageUrl!.isNotEmpty)) ? _vm.removeImage : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Bild entfernen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecipeEditor(
                recipe: r,
                onTitleChanged: _vm.updateTitle,
                onDescriptionChanged: _vm.updateDescription,
                onServingsChanged: _vm.updateServings,
                onImageUrlChanged: _vm.updateImageUrl,
                onAddIngredient: _vm.addIngredient,
                onRemoveIngredient: _vm.removeIngredient,
                onUpdateIngredient: _vm.updateIngredient,
                onAddStep: _vm.addStep,
                onRemoveStep: _vm.removeStep,
                onUpdateStep: _vm.updateStep,
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rezept Extraktion',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white
          ),
        ),
        backgroundColor:  Theme.of(context).colorScheme.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: _vm.canSave
          ? FloatingActionButton.extended(
              onPressed: _vm.isSaving ? null : _save,
              icon: _vm.isSaving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Speichern'),
            )
          : null,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Rezept URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _vm.setUrl,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _vm.canExtract ? _extract : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Extrahieren'),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildResult(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
