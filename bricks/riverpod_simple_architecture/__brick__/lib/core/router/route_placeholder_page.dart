import 'package:flutter/material.dart';

/// Trivial scaffold used by the generated placeholder routes until feature
/// goals replace them with real pages.
class RoutePlaceholderPage extends StatelessWidget {
  const RoutePlaceholderPage({required this.icon, this.title, super.key});

  final IconData icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title == null ? null : Text(title!)),
      body: Center(child: Icon(icon, size: 64)),
    );
  }
}
