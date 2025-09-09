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
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Hinzufügen')),
              ],
            ),
            const SizedBox(height: 6),
            if (items.isEmpty)
              Text('Noch keine Einträge. Tippe auf "Hinzufügen".', style: TextStyle(color: Colors.grey[600]))
            else
              ...items.asMap().entries.map((e) {
                final idx = e.key;
                final val = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('$title-$idx-${recipe.id}'),
                          initialValue: val,
                          onChanged: (v) => onChange(idx, v),
                          maxLines: null,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: hintText.isNotEmpty ? hintText : '$title $idx',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Entfernen',
                        onPressed: () => onRemove(idx),
                        icon: const Icon(Icons.delete_outline),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                r.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('title-${r.id}'),
                  initialValue: r.title,
                  onChanged: onTitleChanged,
                  decoration: const InputDecoration(labelText: 'Titel', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('servings-${r.id}'),
                        initialValue: r.servings ?? '',
                        onChanged: onServingsChanged,
                        decoration: const InputDecoration(labelText: 'Portionen / Menge', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('image-${r.id}'),
                        initialValue: r.imageUrl ?? '',
                        onChanged: onImageUrlChanged,
                        decoration: const InputDecoration(labelText: 'Bild-URL', border: OutlineInputBorder()),
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
                  decoration: const InputDecoration(labelText: 'Beschreibung', border: OutlineInputBorder()),
                ),
              ],
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

