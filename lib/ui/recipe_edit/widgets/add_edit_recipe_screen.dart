// filepath: /Users/Jonah/FlutterApps/lib/ui/recipe_edit/widgets/add_edit_recipe_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/recipe_editor.dart';
import '../view_model/create_edit_recipe_view_model.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final String? recipeId; // null => create new
  const AddEditRecipeScreen({super.key, this.recipeId});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  late final CreateEditRecipeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = CreateEditRecipeViewModel(recipeId: widget.recipeId);
    _vm.addListener(_onChanged);
    _vm.init();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    super.dispose();
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

  Future<void> _save() async {
    final ok = await _vm.save();
    if (!mounted) return;
    if (ok) {
      final id = _vm.recipe!.id;
      Navigator.of(context).pushReplacementNamed('/recipe', arguments: id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezept gespeichert.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speichern fehlgeschlagen')));
    }
  }

  Widget _buildBody() {
    switch (_vm.status) {
      case CreateEditStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CreateEditStatus.error:
        return Center(child: Text(_vm.errorMessage ?? 'Fehler', style: const TextStyle(color: Colors.red)));
      case CreateEditStatus.ready:
        final r = _vm.recipe!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white,),
                    label: const Text('Bild auswählen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: (r.imagePath != null || (r.imageUrl != null && r.imageUrl!.isNotEmpty)) ? _vm.removeImage : null,
                    icon: const Icon(Icons.delete_outline, color: Colors.white,),
                    label: const Text('Bild entfernen', style: TextStyle(color: Colors.white),),
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
              const SizedBox(height: 80),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recipeId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Rezept bearbeiten' : 'Rezept erstellen', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 50,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _vm.canSave ? _save : null,
        icon: _vm.isSaving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
        label: const Text('Speichern'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }
}
