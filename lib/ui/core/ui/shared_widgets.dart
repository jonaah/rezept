// Shared UI widgets used across multiple features.
import 'package:flutter/material.dart';

class CenteredMessage extends StatelessWidget {
  final String message;
  const CenteredMessage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

