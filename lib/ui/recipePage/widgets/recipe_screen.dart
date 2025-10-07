import 'dart:io';
import 'package:flutter/material.dart';
import '../view_model/recipe_view_model.dart';

class RecipeScreen extends StatefulWidget {
  final String recipeId;
  const RecipeScreen({super.key, required this.recipeId});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late final RecipeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = RecipeViewModel(recipeId: widget.recipeId);
    _vm.addListener(_onChanged);
    _vm.load();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen'),
        content: const Text('Möchtest du dieses Rezept wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await _vm.delete();
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezept gelöscht')));
    }
  }

  Widget _buildBody() {
    switch (_vm.status) {
      case RecipeViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case RecipeViewStatus.notFound:
        return const Center(child: Text('Rezept nicht gefunden.'));
      case RecipeViewStatus.ready:
        final r = _vm.recipe!;
        final local = r.imagePath != null && r.imagePath!.isNotEmpty ? File(r.imagePath!) : null;
        final hasLocal = local != null && local.existsSync();
        return RefreshIndicator(
          onRefresh: _vm.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasLocal || r.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasLocal
                        ? Image.file(local, height: 220, width: double.infinity, fit: BoxFit.cover)
                        : Image.network(
                            r.imageUrl!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                  ),
                const SizedBox(height: 16),
                Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
                if (r.servings != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_2, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(r.servings!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                if (r.totalTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${r.totalTime!.inMinutes} Minuten', style: const TextStyle(color: Colors.grey)),
                    ]),
                  ),
                if (r.description != null && r.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(r.description!),
                  ),
                const SizedBox(height: 20),
                if (r.ingredients.isNotEmpty) ...[
                  Text('Zutaten', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...r.ingredients.map((i) => Text('• $i')),
                  const SizedBox(height: 20),
                ],
                if (r.steps.isNotEmpty) ...[
                  Text('Zubereitung', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...r.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(e.value)),
                        ]),
                      )),
                ],
                if (r.sourceUrl != null) ...[
                  const SizedBox(height: 24),
                  Text('Quelle', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(r.sourceUrl!, style: const TextStyle(fontSize: 12, color: Colors.black)),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezept',
          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 50,
        actions: [
          if (_vm.status == RecipeViewStatus.ready) ...[
            IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/edit', arguments: widget.recipeId),
            ),
            IconButton(
              tooltip: 'Löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(),
      ),
    );
  }
}
