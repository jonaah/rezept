import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'main.dart' show MyApp; // Reuse the MyApp widget.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(const AppConfig(
    flavor: 'staging',
    apiBaseUrl: 'https://staging-api.example.com',
  ));
  // Defer repository initialization; it initializes lazily on first use.
  runApp(const MyApp());
}
