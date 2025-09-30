import 'package:flutter/material.dart';
import '../../../domain/models/recipe.dart';
import 'header_image.dart';

class RecipeTileRecommendation extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  const RecipeTileRecommendation({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    final minutes = recipe.totalTime?.inMinutes;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // This line was missing children: []
          children: [
            Stack(
              children: [
                RecipeHeaderImage(
                  imageUrl: recipe.imageUrl,
                  imagePath: recipe.imagePath,
                  aspectRatio: 16 / 6,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Empfehlung des Tages',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                recipe.title,
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
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    minutes != null ? '$minutes Min' : '—',
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