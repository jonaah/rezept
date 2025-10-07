import 'package:flutter/material.dart';
import 'package:rezept/ui/categories/view_model/categories_view_model.dart';
import 'package:rezept/ui/categories/widgets/category_grid_tile.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoriesViewModel _vm;

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
    super.dispose();
  }

  Widget _buildBody() {
    if (_vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.categories.isEmpty) {
      return const Center(child: Text('Noch keine Kategorien angelegt'));
    }

    final list = _vm.categories;

    return RefreshIndicator(
      onRefresh: _vm.load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = (width / 200).floor();
          if (crossAxisCount < 2) crossAxisCount = 2;
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = list[index];
                      return Stack(
                        children: [
                          CategoryGridTile(
                            category: c,
                            onTap: null, // No navigation specified
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.transparent,
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onSelected: (v) async {
                                  if (v == 'rename') {
                                    final name = await _promptRename(c.name);
                                    if (name != null) await _vm.renameCategory(c, name);
                                  } else if (v == 'delete') {
                                    await _vm.deleteCategory(c);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: const Icon(Icons.edit, color: Colors.black87),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
          _buildBody(),
        ],
      ),
    );
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
