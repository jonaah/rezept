import 'package:flutter/material.dart';
import 'package:rezept/data/repositories/category_repository.dart';
import 'package:rezept/data/repositories/recipe_repository.dart';
import 'package:rezept/domain/models/category.dart';
import 'package:rezept/domain/models/recipe.dart';
import 'package:rezept/ui/categories/widgets/category_create_sheet.dart';
import 'package:rezept/ui/mainPage/widgets/filter_mainpage.dart';
import 'package:rezept/ui/mainPage/widgets/recipe_grid_tile.dart';

class CategoryRecipesPage extends StatefulWidget {
  final Category category;
  const CategoryRecipesPage({super.key, required this.category});

  @override
  State<CategoryRecipesPage> createState() => _CategoryRecipesPageState();
}

class _CategoryRecipesPageState extends State<CategoryRecipesPage> {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String _filterQuery = '';
  late Category _category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _loading = true);
    try {
      await recipeRepository.init();
      final allRecipes = await recipeRepository.getAll();
      final categoryRecipes = allRecipes
          .where((r) => _category.recipeIds.contains(r.id))
          .toList();
      if (!mounted) return;
      setState(() {
        _recipes = categoryRecipes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden: $e')),
      );
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Rezepte in dieser Kategorie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      );
    }

    final list = _filteredRecipes;

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = (width / 200).floor();
          if (crossAxisCount < 2) crossAxisCount = 2;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Category description
              if (_category.description != null &&
                  _category.description!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _category.description!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Filter widget
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  _category.description != null ? 0 : 12,
                  12,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: FilterMainPage(
                    query: _filterQuery,
                    onChanged: (v) => setState(() => _filterQuery = v),
                  ),
                ),
              ),

              // Recipe grid
              if (list.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'Keine Treffer für "$_filterQuery"',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = list[index];
                        return RecipeGridTile(
                          recipe: r,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/recipe',
                            arguments: r.id,
                          ),
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

  Future<void> _editCategory() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => CategoryCreateSheet(category: _category),
    );
    if (result == true) {
      // Reload category and recipes
      await categoryRepository.init();
      final updatedCategory = await categoryRepository.getById(_category.id);
      if (updatedCategory != null) {
        setState(() => _category = updatedCategory);
        await _loadRecipes();
      }
    } else if (result == 'deleted') {
      // Category deleted, go back
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        toolbarHeight: 50,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editCategory,
            tooltip: 'Kategorie bearbeiten',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
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
