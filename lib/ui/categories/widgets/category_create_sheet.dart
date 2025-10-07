// filepath: /Users/Jonah/FlutterApps/lib/ui/categories/widgets/category_create_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rezept/data/repositories/category_repository.dart';
import 'package:rezept/data/repositories/recipe_repository.dart';
import 'package:rezept/domain/models/category.dart';
import 'package:rezept/domain/models/recipe.dart';
import 'package:icons_flutter/icons_flutter.dart';

class CategoryCreateSheet extends StatefulWidget {
  const CategoryCreateSheet({super.key});

  @override
  State<CategoryCreateSheet> createState() => _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends State<CategoryCreateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Recipe> _recipes = const [];
  final Set<String> _selectedRecipeIds = {};

  // Presentation selections
  String? _iconKey;
  String? _imagePath;
  int? _colorValue;

  bool _loading = true;
  bool _saving = false;

  final _icons = const <({String key, String label, IconData icon})>[
    (key: 'vegi', label: 'Vegi', icon: Icons.eco_outlined),
    (key: 'fleisch', label: 'Fleisch', icon: Icons.set_meal_outlined),
    (key: 'fisch', label: 'Fisch', icon : MaterialCommunityIcons.fishbowl_outline),
    (key: 'süss', label: 'Süss', icon: Icons.cake_outlined),
    (key: 'drink', label: 'Drink', icon: Icons.local_drink_outlined),
    (key: 'andere', label: 'Andere', icon: Icons.category_outlined),
  ];

  final _colors = const <int>[
    0xFFF44336, // red
    0xFFE91E63, // pink
    0xFF9C27B0, // purple
    0xFF3F51B5, // indigo
    0xFF03A9F4, // light blue
    0xFF009688, // teal
    0xFF4CAF50, // green
    0xFFFF9800, // orange
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await recipeRepository.init();
    final recs = await recipeRepository.getAll();
    if (!mounted) return;
    setState(() {
      _recipes = recs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
    if (xfile != null) {
      setState(() => _imagePath = xfile.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await categoryRepository.init();
      final c = Category(
        id: UniqueKey().toString(),
        name: _nameCtrl.text.trim(),
        recipeIds: _selectedRecipeIds.toList(),
        iconKey: _iconKey,
        imagePath: _imagePath,
        colorValue: _colorValue,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      await categoryRepository.upsert(c);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black26)],
        ),
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
              title: const Text('Neue Kategorie'),
              actions: [
                TextButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Text('Speichern'),
                ),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name ist erforderlich' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('Icon', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _icons.map((opt) {
                            final selected = _iconKey == opt.key;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [Icon(opt.icon, size: 18), const SizedBox(width: 6), Text(opt.label)],
                              ),
                              selected: selected,
                              onSelected: (_) => setState(() => _iconKey = opt.key),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text('Bild', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _saving ? null : _pickImage,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: _imagePath == null
                                    ? const Icon(Icons.add_a_photo_outlined)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _imagePath == null ? 'Kein Bild ausgewählt' : _imagePath!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Farbe', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _colors.map((c) {
                            final selected = _colorValue == c;
                            return GestureDetector(
                              onTap: () => setState(() => _colorValue = c),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(c),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected ? Colors.white : Colors.black26,
                                    width: selected ? 3 : 1,
                                  ),
                                  boxShadow: selected ? const [BoxShadow(blurRadius: 8, color: Colors.black26)] : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descCtrl,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Beschreibung',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Rezepte hinzufügen'),
                          initiallyExpanded: _recipes.isNotEmpty,
                          children: [
                            if (_recipes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Keine Rezepte verfügbar'),
                              )
                            else
                              ..._recipes.map((r) => CheckboxListTile(
                                    value: _selectedRecipeIds.contains(r.id),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedRecipeIds.add(r.id);
                                        } else {
                                          _selectedRecipeIds.remove(r.id);
                                        }
                                      });
                                    },
                                    title: Text(r.title),
                                    secondary: const Icon(Icons.restaurant_menu_outlined),
                                    controlAffinity: ListTileControlAffinity.leading,
                                  )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: const Text('Kategorie erstellen'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

