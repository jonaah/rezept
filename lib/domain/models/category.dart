// Domain model for a Category that groups recipes by IDs.
import 'dart:math';

class Category {
  final String id;
  String name;
  List<String> recipeIds;
  DateTime createdAt;
  // Optional presentation fields
  String? iconKey; // maps to a predefined icon in UI
  String? imagePath; // local image path
  int? colorValue; // ARGB int
  String? description;

  Category({
    required this.id,
    required this.name,
    List<String>? recipeIds,
    DateTime? createdAt,
    this.iconKey,
    this.imagePath,
    this.colorValue,
    this.description,
  })  : recipeIds = recipeIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recipeIds': recipeIds,
        'createdAt': createdAt.toIso8601String(),
        if (iconKey != null) 'iconKey': iconKey,
        if (imagePath != null) 'imagePath': imagePath,
        if (colorValue != null) 'colorValue': colorValue,
        if (description != null) 'description': description,
      };

  static Category fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? _generateId(),
        name: json['name']?.toString() ?? 'Kategorie',
        recipeIds: (json['recipeIds'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        iconKey: json['iconKey']?.toString(),
        imagePath: json['imagePath']?.toString(),
        colorValue: json['colorValue'] is int ? json['colorValue'] as int : int.tryParse(json['colorValue']?.toString() ?? ''),
        description: json['description']?.toString(),
      );

  Category copyWith({
    String? name,
    List<String>? recipeIds,
    String? iconKey,
    String? imagePath,
    int? colorValue,
    String? description,
  }) => Category(
        id: id,
        name: name ?? this.name,
        recipeIds: recipeIds ?? List<String>.from(this.recipeIds),
        createdAt: createdAt,
        iconKey: iconKey ?? this.iconKey,
        imagePath: imagePath ?? this.imagePath,
        colorValue: colorValue ?? this.colorValue,
        description: description ?? this.description,
      );

  static String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32).toRadixString(16);
    return 'cat-$ts-$rnd';
  }
}
