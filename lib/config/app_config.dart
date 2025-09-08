/// Simple application configuration / flavor data holder.
class AppConfig {
  final String flavor;
  final String apiBaseUrl;
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  static late AppConfig instance;
  static void init(AppConfig config) => instance = config;
}

