import 'package:flutter/material.dart';
import '../ui/mainPage/widgets/mainPage.dart';
import '../ui/recipe_extraction/widgets/recipe_extraction_screen.dart';
import '../ui/recipePage/widgets/recipe_screen.dart';

/// Basic router placeholder. Replace with go_router / auto_route as needed.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainPage(title: 'Home'));
      case '/extract':
        return MaterialPageRoute(builder: (_) => const RecipeExtractionScreen());
      case '/recipe':
        final id = settings.arguments as String?;
        if (id == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text('Kein Rezept ID übergeben'))),
          );
        }
        return MaterialPageRoute(builder: (_) => RecipeScreen(recipeId: id));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
