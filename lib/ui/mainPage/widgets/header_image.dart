import 'dart:io';
import 'package:flutter/material.dart';

class RecipeHeaderImage extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final double aspectRatio;
  const RecipeHeaderImage({super.key, required this.imageUrl, required this.imagePath, this.aspectRatio = 9 / 7});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final localFile = imagePath != null && imagePath!.isNotEmpty ? File(imagePath!) : null;
    final hasLocal = localFile != null && localFile.existsSync();
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasLocal)
            Image.file(localFile, fit: BoxFit.cover)
          else if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => _placeholder(ctx),
            )
          else
            _placeholder(context),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bg.withOpacity(0.0),
                  bg.withOpacity(0.8),
                  bg,
                ],
                stops: const [0.0, 0.7, 0.85, 1.0],
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
