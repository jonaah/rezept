import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/recipe.dart';

class RecipeEditor extends StatelessWidget {
  final Recipe recipe;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onServingsChanged;
  final ValueChanged<String> onImageUrlChanged;

  final VoidCallback onAddIngredient;
  final void Function(int) onRemoveIngredient;
  final void Function(int, String) onUpdateIngredient;

  final VoidCallback onAddStep;
  final void Function(int) onRemoveStep;
  final void Function(int, String) onUpdateStep;

  const RecipeEditor({
    super.key,
    required this.recipe,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onServingsChanged,
    required this.onImageUrlChanged,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onUpdateIngredient,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onUpdateStep,
  });

  Widget _buildEditableList({
    required BuildContext context,
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required void Function(int, String) onChange,
    String hintText = '',
  }) {
    return Card(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Hinzufügen', style: TextStyle(color: Colors.white))),
              ],
            ),
            const SizedBox(height: 6),
            if (items.isEmpty)
              Text('Noch keine Einträge. Tippe auf "Hinzufügen".', style: TextStyle(color: Colors.white))
            else
              ...items.asMap().entries.map((e) {
                final idx = e.key;
                final val = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('$title-$idx-${recipe.id}'),
                          initialValue: val,
                          onChanged: (v) => onChange(idx, v),
                          maxLines: null,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            hintText: hintText.isNotEmpty ? hintText : '$title $idx',
                            hintStyle: const TextStyle(color: Colors.white54),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Entfernen',
                        onPressed: () => onRemove(idx),
                        icon: const Icon(Icons.delete_outline, color: Colors.white,),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final local = r.imagePath != null && r.imagePath!.isNotEmpty ? File(r.imagePath!) : null;
    final hasLocal = local != null && local.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLocal || (r.imageUrl != null && r.imageUrl!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasLocal
                  ? Image.file(local!, height: 180, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(
                      r.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Card(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            margin: const EdgeInsets.only(top: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('title-${r.id}'),
                  initialValue: r.title,
                  onChanged: onTitleChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('servings-${r.id}'),
                        initialValue: r.servings ?? '',
                        onChanged: onServingsChanged,
                        decoration: const InputDecoration(
                            labelText: 'Portionen / Menge',
                            labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('image-${r.id}'),
                        initialValue: r.imageUrl ?? '',
                        onChanged: onImageUrlChanged,
                        decoration: const InputDecoration(
                            labelText: 'Bild-URL',
                            labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('desc-${r.id}'),
                  initialValue: r.description ?? '',
                  onChanged: onDescriptionChanged,
                  maxLines: null,
                  decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
              ],
            ),
          ),
        ),
      ),
        _buildEditableList(
          context: context,
          title: 'Zutaten',
          items: r.ingredients,
          onAdd: onAddIngredient,
          onRemove: onRemoveIngredient,
          onChange: onUpdateIngredient,
          hintText: 'z. B. 200 g Mehl',
        ),
        _buildEditableList(
          context: context,
          title: 'Schritte',
          items: r.steps,
          onAdd: onAddStep,
          onRemove: onRemoveStep,
          onChange: onUpdateStep,
          hintText: 'z. B. Backofen vorheizen …',
        ),
      ],
    );
  }
}
