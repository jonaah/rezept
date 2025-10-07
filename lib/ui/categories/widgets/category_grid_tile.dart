import 'dart:io';

import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:rezept/domain/models/category.dart';

class CategoryGridTile extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  const CategoryGridTile({super.key, required this.category, this.onTap});

  IconData _iconForKey(String? key) {
    switch (key) {
      case 'vegi':
        return Icons.eco_outlined;
      case 'fleisch':
        return Icons.set_meal_outlined;
      case 'fisch':
        return MaterialCommunityIcons.fishbowl_outline;
      case 'süss':
        return Icons.cake_outlined;
      case 'drink':
        return Icons.local_drink_outlined;
      case 'andere':
        return Icons.category_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = category.recipeIds.length;
    final String? img = category.imagePath;
    final int? colorValue = category.colorValue;
    final bool hasImage = img != null && img.isNotEmpty && File(img).existsSync();

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 9 / 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(File(img!), fit: BoxFit.cover)
                    else
                      Container(color: colorValue != null ? Color(colorValue) : Theme.of(context).colorScheme.surfaceContainerHighest),
                    // Gradient overlay for better text contrast near the bottom
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.25),
                          ],
                          stops: const [0.0, 0.7, 0.85, 1.0],
                        ),
                      ),
                    ),
                    if (!hasImage)
                      Center(
                        child: Icon(
                          _iconForKey(category.iconKey),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    count == 1 ? '1 Rezept' : '$count Rezepte',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
