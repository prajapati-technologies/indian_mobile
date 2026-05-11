import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches Indian Information web (`home.blade.php`, profile, etc.).
abstract final class AppColors {
  static const Color brandNavy = Color(0xFF0B2C5F);
  static const Color brandNavyHover = Color(0xFF0A254F);
  static const Color brandOrange = Color(0xFFFF6A00);
  /// `--brand-green` on web news cards
  static const Color brandGreen = Color(0xFF138808);
  static const Color pageBackground = Color(0xFFF3F7FD);
  static const Color textPrimary = Color(0xFF1F2F46);
  static const Color textMuted = Color(0xFF5C6B82);
  static const Color borderLight = Color(0xFFDFE9F8);
  static const Color cardMutedBg = Color(0xFFF9FBFF);
  static const Color sideLinkBg = Color(0xFFF8FBFF);
}

ThemeData buildIndianInformationTheme() {
  const navy = AppColors.brandNavy;
  const orange = AppColors.brandOrange;

  final colorScheme = ColorScheme.light(
    primary: navy,
    onPrimary: Colors.white,
    primaryContainer: AppColors.cardMutedBg,
    onPrimaryContainer: navy,
    secondary: orange,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderLight,
    surfaceContainerHighest: AppColors.cardMutedBg,
  );

  final baseText = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: baseText.copyWith(
      titleLarge: baseText.titleLarge?.copyWith(color: AppColors.textPrimary),
      titleMedium: baseText.titleMedium?.copyWith(color: AppColors.textPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.textPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: AppColors.textMuted),
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      shape: Border(
        bottom: BorderSide(color: orange, width: 3),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: navy.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: navy.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      indicatorColor: orange.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? navy : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? navy : AppColors.textMuted,
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: const TextStyle(
        color: navy,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: navy,
      textColor: AppColors.textPrimary,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
  );
}
