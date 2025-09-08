/// Simple logger utility (placeholder for a more advanced solution).
class Logger {
  const Logger._();
  static void d(String message) {
    // ignore: avoid_print
    print('[DEBUG] $message');
  }
  static void e(String message, [Object? error, StackTrace? stack]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('  error: $error');
    }
    if (stack != null) {
      // ignore: avoid_print
      print(stack);
    }
  }
}

