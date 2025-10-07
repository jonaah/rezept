// filepath: /Users/Jonah/FlutterApps/lib/ui/categories/widgets/category_create_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rezept/data/repositories/category_repository.dart';
import 'package:rezept/data/repositories/recipe_repository.dart';
import 'package:rezept/domain/models/category.dart';
import 'package:rezept/domain/models/recipe.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:rezept/ui/mainPage/widgets/recipe_grid_tile.dart';

class CategoryCreateSheet extends StatefulWidget {
  final Category? category; // null = create mode, otherwise edit mode
  const CategoryCreateSheet({super.key, this.category});

  @override
  State<CategoryCreateSheet> createState() => _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends State<CategoryCreateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _filterCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Recipe> _recipes = const [];
  final Set<String> _selectedRecipeIds = {};
  String _filterQuery = '';

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
    _initFormValues();
    _init();
  }

  void _initFormValues() {
    final cat = widget.category;
    if (cat != null) {
      // Edit mode: pre-fill with existing values
      _nameCtrl.text = cat.name;
      _descCtrl.text = cat.description ?? '';
      _selectedRecipeIds.addAll(cat.recipeIds);
      _iconKey = cat.iconKey;
      _imagePath = cat.imagePath;
      _colorValue = cat.colorValue;
    }
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
    _filterCtrl.dispose();
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
        id: widget.category?.id ?? UniqueKey().toString(), // Use existing ID or generate new
        name: _nameCtrl.text.trim(),
        recipeIds: _selectedRecipeIds.toList(),
        iconKey: _iconKey,
        imagePath: _imagePath,
        colorValue: _colorValue,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        createdAt: widget.category?.createdAt ?? DateTime.now(), // Preserve original creation date
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategorie löschen'),
        content: Text('Möchtest du die Kategorie "${widget.category?.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await categoryRepository.init();
      await categoryRepository.delete(widget.category!.id);
      if (mounted) Navigator.of(context).pop('deleted'); // Return 'deleted' to signal deletion
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Recipe> get _filteredRecipes {
    if (_filterQuery.trim().isEmpty) return _recipes;
    final q = _filterQuery.toLowerCase();
    return _recipes.where((r) {
      return r.title.toLowerCase().contains(q) ||
          (r.description?.toLowerCase().contains(q) ?? false) ||
          r.ingredients.any((i) => i.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final top = MediaQuery.of(context).padding.top; // Status bar height
    final isEditMode = widget.category != null;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottom, top: top), // Add top padding for status bar
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.white)],
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            surfaceTintColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            title: Text(
              isEditMode ? 'Edit Kategorie ' : 'Neue Kategorie',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              if (isEditMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _saving ? null : _delete,
                  tooltip: 'Kategorie löschen',
                ),
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, color: Colors.white,),
                label: const Text('Save', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Container(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = (width / 200).floor();
                      if (crossAxisCount < 2) crossAxisCount = 2;

                      return CustomScrollView(
                        slivers: [
                          // Form fields section
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                TextFormField(
                                  controller: _nameCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name ist erforderlich' : null,
                                ),
                                const SizedBox(height: 16),
                                Text('Icon', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _icons.map((opt) {
                                    final selected = _iconKey == opt.key;
                                    return ChoiceChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [Icon(opt.icon, size: 18, color: Colors.black), const SizedBox(width: 6), Text(opt.label, style: const TextStyle(color: Colors.black))],
                                      ),
                                      selected: selected,
                                      selectedColor: Theme.of(context).colorScheme.primary,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      onSelected: (_) => setState(() {
                                        _iconKey = (_iconKey == opt.key) ? null : opt.key;
                                      }),
                                      side: BorderSide(color: selected ? Colors.green : Colors.black),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Text('Bild', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
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
                                          border: Border.all(color: Colors.white),
                                        ),
                                        child: _imagePath == null
                                            ? const Icon(Icons.add_a_photo_outlined, color: Colors.black)
                                            : ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                              ),
                                      ),
                                    ),
                                    if (_imagePath != null) ...[
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: () => setState(() => _imagePath = null),
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        tooltip: 'Bild entfernen',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text('Farbe', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
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
                                            color: selected ? Colors.white : Colors.white54,
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Beschreibung',
                                    labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Rezepte hinzufügen (${_selectedRecipeIds.length})',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tippe auf ein Rezept, um es auszuwählen',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ]),
                            ),
                          ),

                          // Search filter
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            sliver: SliverToBoxAdapter(
                              child: Card(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _filterCtrl,
                                          onChanged: (v) => setState(() => _filterQuery = v),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Rezepte filtern (Titel, Beschreibung, Zutaten)',
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      if (_filterQuery.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.grey),
                                          tooltip: 'Filter löschen',
                                          onPressed: () {
                                            _filterCtrl.clear();
                                            setState(() => _filterQuery = '');
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Recipe grid
                          if (_filteredRecipes.isEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 32),
                                  child: Center(
                                    child: Text(
                                      _recipes.isEmpty
                                        ? 'Keine Rezepte verfügbar'
                                        : 'Keine Treffer für "$_filterQuery"',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final r = _filteredRecipes[index];
                                    final isSelected = _selectedRecipeIds.contains(r.id);

                                    return Stack(
                                      children: [
                                        RecipeGridTile(
                                          recipe: r,
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedRecipeIds.remove(r.id);
                                              } else {
                                                _selectedRecipeIds.add(r.id);
                                              }
                                            });
                                          },
                                        ),
                                        if (isSelected)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 4,
                                                    color: Colors.black26,
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                  childCount: _filteredRecipes.length,
                                ),
                              ),
                            ),

                          // Save button at bottom
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            sliver: SliverToBoxAdapter(
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check, color: Colors.white),
                                label: Text(
                                  isEditMode ? 'Änderungen speichern' : 'Kategorie erstellen',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ),
          ),
        ),
      );
  }
}
