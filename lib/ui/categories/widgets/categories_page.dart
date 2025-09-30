import 'package:flutter/material.dart';
import 'package:rezept/ui/categories/view_model/categories_view_model.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoriesViewModel _vm;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = CategoriesViewModel();
    _vm.addListener(_onChanged);
    _vm.init();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        toolbarHeight: 50,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kategorien',
          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.secondary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (_vm.loading)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(
              onRefresh: _vm.load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                labelText: 'Neue Kategorie',
                                hintText: 'z.B. Pasta, Vegan, Dessert',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _submit,
                            child: const Text('Hinzufügen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_vm.categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Noch keine Kategorien angelegt')),
                    )
                  else
                    ..._vm.categories.map((c) => Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'rename') {
                                  final name = await _promptRename(c.name);
                                  if (name != null) await _vm.renameCategory(c, name);
                                } else if (v == 'delete') {
                                  await _vm.deleteCategory(c);
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                                PopupMenuItem(value: 'delete', child: Text('Löschen')),
                              ],
                            ),
                            children: [
                              if (_vm.recipes.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Keine Rezepte zum Zuweisen'),
                                )
                              else
                                ..._vm.recipes.map((r) => CheckboxListTile(
                                      value: _vm.isAssigned(c, r),
                                      onChanged: (_) => _vm.toggleAssignment(c, r),
                                      title: Text(r.title),
                                      secondary: const Icon(Icons.restaurant_menu_outlined),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    )),
                            ],
                          ),
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _vm.addCategory(name);
    _controller.clear();
    setState(() {});
  }

  Future<String?> _promptRename(String current) async {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategorie umbenennen'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Speichern')),
        ],
      ),
    );
  }
}
