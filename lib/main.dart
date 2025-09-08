import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'routing/app_router.dart';
import 'ui/core/themes/app_theme.dart';
import 'data/repositories/recipe_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(const AppConfig(flavor: 'production', apiBaseUrl: 'https://api.example.com'));
  await recipeRepository.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}
