import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_colors_ext.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';

/// Selectable card with a brand-primary border/tint when selected.
/// Themed exclusively through tokens.
class AppSelectableCard extends StatelessWidget {
  const AppSelectableCard({
    required this.selected,
    required this.child,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  static const containerKey = ValueKey('app_selectable_card_container');

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final tokens = AppTokens.of(context);

    return Semantics(
      selected: selected,
      button: onTap != null,
      label: semanticLabel,
      child: AnimatedContainer(
        key: containerKey,
        duration: tokens.motionShort,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? colors.selectedTint : colors.surfaceCard,
          borderRadius: BorderRadius.circular(tokens.radiusM),
          border: Border.all(
            color: selected ? colors.primary : colors.cardBorder,
            width: selected ? tokens.strokeM : tokens.strokeS,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(tokens.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radiusM),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.spaceM),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
