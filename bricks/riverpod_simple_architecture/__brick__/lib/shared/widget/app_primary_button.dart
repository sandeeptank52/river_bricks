import 'package:flutter/material.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_colors_ext.dart';
import 'package:{{project_name.snakeCase()}}/core/theme/app_tokens.dart';

/// Primary CTA: brand pill button with enabled / disabled / loading states.
/// Themed exclusively through tokens (no color/dimension literals).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final colors = context.appColors;
    final enabled = onPressed != null && !isLoading;

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        disabledBackgroundColor: colors.primarySoft,
        foregroundColor: colors.textOnPrimary,
        disabledForegroundColor: colors.textSecondary,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spaceL,
          vertical: tokens.spaceM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusL),
        ),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      child: AnimatedSwitcher(
        duration: tokens.motionShort,
        child: isLoading
            ? SizedBox.square(
                dimension: tokens.iconM,
                child: CircularProgressIndicator(strokeWidth: tokens.strokeM),
              )
            : DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
      ),
    );
  }
}
