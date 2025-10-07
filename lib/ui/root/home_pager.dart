// filepath: /Users/Jonah/FlutterApps/lib/ui/root/home_pager.dart
import 'package:flutter/material.dart';
import 'package:rezept/ui/categories/widgets/categories_page.dart';
import 'package:rezept/ui/mainPage/widgets/mainpage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rezept/ui/categories/widgets/category_create_sheet.dart';

/// Hosts the main and categories pages in a horizontally swipable pager.
class HomePager extends StatefulWidget {
  const HomePager({super.key});

  @override
  State<HomePager> createState() => _HomePagerState();
}

class _HomePagerState extends State<HomePager> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      _controller.animateToPage(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return false;
    }
    return true;
  }

  void _openCreateCategorySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CategoryCreateSheet(),
    );
  }

  Widget _buildFab() {
    if (_index == 0) {
      // MainPage actions: same SpeedDial as before
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.primary,
        overlayColor: Colors.black,
        overlayOpacity: 0.1,
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
      );
    }

    // Categories add button
    return FloatingActionButton(
      onPressed: _openCreateCategorySheet,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.category, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PageView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          onPageChanged: (i) => setState(() => _index = i),
          children: const [
            KeyedSubtree(key: PageStorageKey('main_page'), child: MainPage(title: 'Recipe')),
            KeyedSubtree(key: PageStorageKey('categories_page'), child: CategoriesPage()),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }
}
