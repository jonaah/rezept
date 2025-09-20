import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.primary,
        overlayColor: Colors.white,
        overlayOpacity: 0.12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.link, color: Colors.white),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: 'Rezept aus Internet extrahieren',
            labelBackgroundColor: Colors.white,
            labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            onTap: () => Navigator.of(context).pushNamed('/extract'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.create, color: Colors.white),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: 'Eigenes Rezept erstellen',
            labelBackgroundColor: Colors.white,
            labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            onTap: () => Navigator.of(context).pushNamed('/create'),
          ),
        ],
      ),
    );
  }
}
