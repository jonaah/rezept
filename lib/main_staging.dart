import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'main.dart' show MyApp; // Reuse the MyApp widget.
import 'data/repositories/recipe_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(const AppConfig(
    flavor: 'staging',
    apiBaseUrl: 'https://staging-api.example.com',
  ));
  await recipeRepository.init();
  runApp(const MyApp());
}
