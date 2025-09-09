import 'package:flutter/material.dart';
import '../../../domain/models/recipe.dart';

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
        child: Container(
          constraints: BoxConstraints(minHeight: 230), // Minimum height for 3 lines
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderImage(imageUrl: recipe.imageUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Spacer(),
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
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final String? imageUrl;
  const _HeaderImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AspectRatio(
      aspectRatio: 9 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => _placeholder(ctx),
          )
              : _placeholder(context),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bg.withOpacity(0.0),
                  bg.withOpacity(0.7),
                  bg,
                ],
                stops: [0.0, 0.7, 0.85, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      color: bg,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
      ),
    );
  }
}
