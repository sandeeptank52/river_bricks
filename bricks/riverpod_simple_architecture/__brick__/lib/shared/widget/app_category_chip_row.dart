import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';

@immutable
class AppCategoryChipItem {
  const AppCategoryChipItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// Wrapping single-select chip row. Themed exclusively through tokens.
class AppCategoryChipRow extends StatelessWidget {
  const AppCategoryChipRow({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<AppCategoryChipItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : tokens.maxControlWidth;

        return Wrap(
          spacing: tokens.spaceS,
          runSpacing: tokens.spaceS,
          children: [
            for (final item in items)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                child: ChoiceChip(
                  label: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: item.id == selectedId,
                  onSelected: (_) => onSelected(item.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
