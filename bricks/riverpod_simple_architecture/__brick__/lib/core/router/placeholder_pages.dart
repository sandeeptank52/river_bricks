import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/router/route_placeholder_page.dart';

/// Generated placeholder pages — one per route in the scaffold's route table.
/// Feature goals replace each with a real page under
/// `lib/features/<feature>/view/` (keeping the route NAME identical), then
/// delete the placeholder class here.
{{#routes}}

@RoutePage()
class {{pascal_name}}Page extends StatelessWidget {
  const {{pascal_name}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoutePlaceholderPage(
      icon: Icons.widgets_outlined,
      title: '{{name}}',
    );
  }
}
{{/routes}}
