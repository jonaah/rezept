// Domain model for a Recipe.
import 'dart:math';

class Recipe {
  final String id;
  String title;
  String? description;
  List<String> ingredients;
  List<String> steps;
  String? imageUrl;
  Duration? prepTime;
  Duration? cookTime;
  DateTime createdAt;
  String? sourceUrl;
  String? servings; // textual representation of servings / yield

  Recipe({
    required this.id,
    required this.title,
    this.description,
    List<String>? ingredients,
    List<String>? steps,
    this.imageUrl,
    this.prepTime,
    this.cookTime,
    DateTime? createdAt,
    this.sourceUrl,
    this.servings,
  })  : ingredients = ingredients ?? <String>[],
        steps = steps ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  Duration? get totalTime {
    if (prepTime == null && cookTime == null) return null;
    return (prepTime ?? Duration.zero) + (cookTime ?? Duration.zero);
  }

  static Recipe fromJsonLd(Map<String, dynamic> json, {String? sourceUrl}) {
    String title = json['name']?.toString() ?? 'Unbenanntes Rezept';
    String? description = json['description']?.toString();

    List<String> ingredients = [];
    final ingRaw = json['recipeIngredient'];
    if (ingRaw is List) {
      ingredients = ingRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    List<String> steps = [];
    final instrRaw = json['recipeInstructions'];
    if (instrRaw is List) {
      steps = instrRaw
          .map((e) {
            if (e is Map && e['text'] != null) return e['text'].toString();
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (instrRaw is String) {
      steps = instrRaw.split(RegExp(r'\n+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    Duration? parseDuration(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(str.toUpperCase());
      if (match != null) {
        final h = int.tryParse(match.group(1) ?? '0') ?? 0;
        final m = int.tryParse(match.group(2) ?? '0') ?? 0;
        return Duration(hours: h, minutes: m);
      }
      return null;
    }

    final image = () {
      final img = json['image'];
      if (img is String) return img;
      if (img is List && img.isNotEmpty) return img.first.toString();
      if (img is Map && img['url'] != null) return img['url'].toString();
      return null;
    }();

    final servings = () {
      final ry = json['recipeYield'] ?? json['yield'];
      if (ry == null) return null;
      if (ry is List && ry.isNotEmpty) return ry.first.toString();
      return ry.toString();
    }();

    return Recipe(
      id: _generateId(),
      title: title,
      description: description,
      ingredients: ingredients,
      steps: steps,
      imageUrl: image,
      prepTime: parseDuration(json['prepTime']),
      cookTime: parseDuration(json['cookTime']),
      sourceUrl: sourceUrl,
      servings: servings,
    );
  }

  // Serialization for persistence
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'steps': steps,
        'imageUrl': imageUrl,
        'prepTimeMinutes': prepTime?.inMinutes,
        'cookTimeMinutes': cookTime?.inMinutes,
        'createdAt': createdAt.toIso8601String(),
        'sourceUrl': sourceUrl,
        'servings': servings,
      }..removeWhere((_, v) => v == null);

  static Recipe fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id']?.toString() ?? _generateId(),
        title: json['title']?.toString() ?? 'Unbenanntes Rezept',
        description: json['description']?.toString(),
        ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
        steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
        imageUrl: json['imageUrl']?.toString(),
        prepTime: _minsToDuration(json['prepTimeMinutes']),
        cookTime: _minsToDuration(json['cookTimeMinutes']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        sourceUrl: json['sourceUrl']?.toString(),
        servings: json['servings']?.toString(),
      );

  static Duration? _minsToDuration(dynamic v) {
    if (v == null) return null;
    final m = int.tryParse(v.toString());
    if (m == null) return null;
    return Duration(minutes: m);
  }

  Recipe copyWith({
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    String? imageUrl,
    Duration? prepTime,
    Duration? cookTime,
    String? sourceUrl,
    String? servings,
  }) => Recipe(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        ingredients: ingredients ?? List<String>.from(this.ingredients),
        steps: steps ?? List<String>.from(this.steps),
        imageUrl: imageUrl ?? this.imageUrl,
        prepTime: prepTime ?? this.prepTime,
        cookTime: cookTime ?? this.cookTime,
        createdAt: createdAt,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        servings: servings ?? this.servings,
      );

  static String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32).toRadixString(16);
    return '$ts-$rnd';
  }
}
