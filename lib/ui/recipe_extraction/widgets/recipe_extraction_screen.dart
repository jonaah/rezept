import 'package:flutter/material.dart';
import '../../recipe_extraction/view_model/recipe_extraction_view_model.dart';

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
          key: const ValueKey('result'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(r.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ),
              Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
              if (r.servings != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_2, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(r.servings!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              if (r.description != null && r.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(r.description!),
                ),
              if (r.ingredients.isNotEmpty) ...[
                const Text('Zutaten', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...r.ingredients.map((i) => Text('\u2022 $i')),
                const SizedBox(height: 16),
              ],
              if (r.steps.isNotEmpty) ...[
                const Text('Schritte', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...r.steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${e.key + 1}. ${e.value}'),
                    )),
              ],
              const SizedBox(height: 16),
              if (r.totalTime != null) Text('Gesamtzeit: ${r.totalTime!.inMinutes} Minuten'),
              if (r.sourceUrl != null) Text('Quelle: ${r.sourceUrl}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezept Extraktion')),
      floatingActionButton: _vm.canSave
          ? FloatingActionButton.extended(
              onPressed: _vm.isSaving ? null : _save,
              icon: _vm.isSaving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Speichern'),
            )
          : null,
      body: Padding(
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
                TextButton(onPressed: _vm.status == RecipeExtractionStatus.loading ? null : _vm.reset, child: const Text('Zurücksetzen')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildResult())),
          ],
        ),
      ),
    );
  }
}
