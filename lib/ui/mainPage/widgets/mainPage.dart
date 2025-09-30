import 'dart:ui';

import 'package:flutter/material.dart';
import '../view_model/mainPageViewModel.dart';
import 'recipe_grid_tile.dart';
import 'recipe_tile_recommendation.dart';
import 'filter_mainpage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});
  final String title;

  @override
  State<MainPage> createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  late final MainPageViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = MainPageViewModel();
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
    if (_vm.recipes.isEmpty) {
      return const Center(child: Text('Keine Rezepte vorhanden'));
    }

    final rec = _vm.dailyRecommendation;
    final list = _vm.filteredRecipes;

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
              if (rec != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  sliver: SliverToBoxAdapter(
                    child: RecipeTileRecommendation(
                      recipe: rec,
                      onTap: () => Navigator.of(context).pushNamed('/recipe', arguments: rec.id),
                    ),
                  ),
                ),
              // Filter widget between recommendation and grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverToBoxAdapter(
                  child: FilterMainPage(
                    query: _vm.filterQuery,
                    onChanged: (v) => _vm.filterQuery = v,
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'Keine Treffer für "${_vm.filterQuery}"',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
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
                          onTap: () => Navigator.of(context).pushNamed('/recipe', arguments: r.id),
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
        backgroundColor:  Theme.of(context).colorScheme.primary,
        centerTitle: true,
        toolbarHeight: 50,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
            textAlign: TextAlign.center,

        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration:  BoxDecoration(
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
      // floatingActionButton removed; provided by HomePager
    );
  }
}
