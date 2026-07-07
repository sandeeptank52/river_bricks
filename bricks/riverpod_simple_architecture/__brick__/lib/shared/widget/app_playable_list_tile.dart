import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';

/// List tile with a play/pause affordance. Themed exclusively through tokens.
class AppPlayableListTile extends StatelessWidget {
  const AppPlayableListTile({
    required this.title,
    required this.isPlaying,
    required this.onPressed,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool isPlaying;
  final VoidCallback? onPressed;

  /// Optional trailing control (e.g. a per-item action button). The leading
  /// avatar stays the play/pause toggle bound to [onPressed].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);

    return Card(
      margin: EdgeInsetsDirectional.symmetric(vertical: tokens.spaceXs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusM),
      ),
      child: ListTile(
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spaceM,
          vertical: tokens.spaceS,
        ),
        onTap: onPressed,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        trailing: trailing,
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
      ),
    );
  }
}
