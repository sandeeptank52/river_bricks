import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';

/// Bottom-sheet scaffold: title row + optional action + body.
/// Themed exclusively through tokens.
class AppBottomSheetScaffold extends StatelessWidget {
  const AppBottomSheetScaffold({
    required this.child,
    this.title,
    this.action,
    super.key,
  });

  final Widget child;
  final Widget? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceM,
          tokens.spaceS,
          tokens.spaceM,
          tokens.spaceM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || action != null)
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: tokens.spaceS),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          child: title!,
                        ),
                      ),
                    if (action != null)
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: action,
                        ),
                      ),
                  ],
                ),
              ),
            Flexible(
              fit: FlexFit.loose,
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
