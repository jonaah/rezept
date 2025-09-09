import 'dart:ui';

import 'package:flutter/material.dart';
import '../view_model/mainPageViewModel.dart';
import 'recipe_grid_tile.dart';

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

    return RefreshIndicator(
      onRefresh: _vm.load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = (width / 200).floor();
          if (crossAxisCount < 2) crossAxisCount = 2;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _vm.recipes.length,
            itemBuilder: (context, index) {
              final r = _vm.recipes[index];
              return RecipeGridTile(
                recipe: r,
                onTap: () => Navigator.of(context).pushNamed('/recipe', arguments: r.id),
              );
            },
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
        title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
            textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            tooltip: 'Rezept Extraktion',
            onPressed: () => Navigator.of(context).pushNamed('/extract'),
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration:  BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.background, Theme.of(context).colorScheme.secondary],
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
