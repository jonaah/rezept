import 'package:flutter/material.dart';
import '../../../domain/models/recipe.dart';
import 'header_image.dart';

class RecipeGridTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  const RecipeGridTile({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = recipe.totalTime;
    final minutes = total?.inMinutes;

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
              child: RecipeHeaderImage(
                imageUrl: recipe.imageUrl,
                imagePath: recipe.imagePath,
                aspectRatio: 9 / 7,
              ),
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
