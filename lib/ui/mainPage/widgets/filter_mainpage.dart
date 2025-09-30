import 'package:flutter/material.dart';

class FilterMainPage extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;
  const FilterMainPage({super.key, required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
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
                controller: TextEditingController(text: query)
                  ..selection = TextSelection.fromPosition(TextPosition(offset: query.length)),
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Rezepte filtern (Titel, Beschreibung, Zutaten)',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: 'Filter löschen',
                onPressed: () => onChanged(''),
              ),
          ],
        ),
      ),
    );
  }
}

