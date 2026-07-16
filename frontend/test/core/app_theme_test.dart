import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application theme uses one explicit visual system', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.navigationBarTheme.indicatorColor, AppColors.primaryFixed);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
  });
}
