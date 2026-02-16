import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==================== COLOR PALETTE ====================

/// Primary brand colors - inspired by family tree and nature
const Color kPrimaryColor = Color(0xFF2E7D32);        // Forest Green
const Color kPrimaryLight = Color(0xFF60AD5E);        // Light Green
const Color kPrimaryDark = Color(0xFF005005);         // Dark Green

/// Secondary colors
const Color kSecondaryColor = Color(0xFF1565C0);      // Ocean Blue
const Color kSecondaryLight = Color(0xFF5E92F3);      // Light Blue
const Color kSecondaryDark = Color(0xFF003C8F);       // Dark Blue

/// Accent colors for highlights and CTAs
const Color kAccentColor = Color(0xFFFF8F00);         // Amber
const Color kAccentLight = Color(0xFFFFC046);         // Light Amber
const Color kAccentDark = Color(0xFFC56000);          // Dark Amber

/// Gender-based colors
const Color kMaleColor = Color(0xFF64B5F6);           // Blue
const Color kMaleColorLight = Color(0xFFBBDEFB);      // Light Blue
const Color kFemaleColor = Color(0xFFF06292);         // Pink
const Color kFemaleColorLight = Color(0xFFF8BBD0);    // Light Pink
const Color kOtherColor = Color(0xFF9575CD);          // Purple
const Color kOtherColorLight = Color(0xFFD1C4E9);     // Light Purple

/// Neutral colors
const Color kBackgroundColor = Color(0xFFF5F7FA);     // Light Gray Background
const Color kSurfaceColor = Color(0xFFFFFFFF);        // White
const Color kDividerColor = Color(0xFFE0E0E0);        // Gray Divider
const Color kTextPrimary = Color(0xFF212121);          // Dark Gray
const Color kTextSecondary = Color(0xFF757575);        // Medium Gray
const Color kTextDisabled = Color(0xFFBDBDBD);         // Light Gray

/// Status colors
const Color kSuccessColor = Color(0xFF4CAF50);        // Green
const Color kWarningColor = Color(0xFFFFA726);        // Orange
const Color kErrorColor = Color(0xFFEF5350);          // Red
const Color kInfoColor = Color(0xFF29B6F6);           // Light Blue

/// Relationship type colors
const Color kRelationshipParent = Color(0xFF7E57C2);  // Purple
const Color kRelationshipChild = Color(0xFF26A69A);   // Teal
const Color kRelationshipSpouse = Color(0xFFEC407A);  // Deep Pink
const Color kRelationshipSibling = Color(0xFF5C6BC0); // Indigo

// ==================== SPACING & SIZING ====================

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppSizing {
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  
  static const double avatarSm = 40.0;
  static const double avatarMd = 60.0;
  static const double avatarLg = 80.0;
  static const double avatarXl = 120.0;
  
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  
  static const double borderRadius = 12.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusLg = 16.0;
  
  static const double cardElevation = 2.0;
  static const double cardElevationHovered = 8.0;
  
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;
}

// ==================== TYPOGRAPHY ====================

class AppTextStyles {
  static const String fontFamily = 'Roboto';
  
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}

// ==================== THEME DATA ====================

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  
  // Color Scheme
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: kPrimaryColor,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryLight,
    onPrimaryContainer: kPrimaryDark,
    secondary: kSecondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: kSecondaryLight,
    onSecondaryContainer: kSecondaryDark,
    tertiary: kAccentColor,
    onTertiary: Colors.white,
    tertiaryContainer: kAccentLight,
    onTertiaryContainer: kAccentDark,
    error: kErrorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: kBackgroundColor,
    onBackground: kTextPrimary,
    surface: kSurfaceColor,
    onSurface: kTextPrimary,
    surfaceVariant: Color(0xFFF3F3F3),
    onSurfaceVariant: kTextSecondary,
    outline: kDividerColor,
    outlineVariant: Color(0xFFE8E8E8),
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: kPrimaryLight,
    surfaceTint: kPrimaryColor,
  ),
  
  // Typography
  textTheme: const TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),
  
  // AppBar Theme
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 2,
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      letterSpacing: 0.15,
    ),
    iconTheme: IconThemeData(color: Colors.white, size: 24),
    actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
  ),
  
  // Card Theme
  cardTheme: CardThemeData(
    elevation: AppSizing.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
    ),
    color: kSurfaceColor,
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    clipBehavior: Clip.antiAlias,
  ),
  
  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, AppSizing.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      minimumSize: const Size(double.infinity, AppSizing.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      side: const BorderSide(color: kPrimaryColor, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPrimaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
      ),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),
  
  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      borderSide: const BorderSide(color: kDividerColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      borderSide: const BorderSide(color: kDividerColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      borderSide: const BorderSide(color: kErrorColor, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      borderSide: const BorderSide(color: kErrorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    hintStyle: const TextStyle(color: kTextDisabled),
    labelStyle: const TextStyle(color: kTextSecondary),
    floatingLabelStyle: const TextStyle(color: kPrimaryColor),
  ),
  
  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: kBackgroundColor,
    selectedColor: kPrimaryLight,
    labelStyle: AppTextStyles.labelMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
    ),
  ),
  
  // Divider Theme
  dividerTheme: const DividerThemeData(
    color: kDividerColor,
    thickness: 1,
    space: 1,
  ),
  
  // Icon Theme
  iconTheme: const IconThemeData(
    color: kTextSecondary,
    size: AppSizing.iconMd,
  ),
  
  // List Tile Theme
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    iconColor: kTextSecondary,
    textColor: kTextPrimary,
  ),
  
  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kSurfaceColor,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: kTextSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: AppTextStyles.labelSmall,
    unselectedLabelStyle: AppTextStyles.labelSmall,
  ),
  
  // Floating Action Button Theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kAccentColor,
    foregroundColor: Colors.white,
    elevation: 6,
    shape: CircleBorder(),
  ),
  
  // Scaffold Background
  scaffoldBackgroundColor: kBackgroundColor,
  
  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: kSurfaceColor,
    elevation: 24,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusLg),
    ),
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: kTextPrimary),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: kTextSecondary),
  ),
  
  // Snackbar Theme
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFF323232),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  
  // Progress Indicator Theme
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: kPrimaryColor,
    linearTrackColor: kDividerColor,
    circularTrackColor: kDividerColor,
  ),
);

// ==================== UTILITY FUNCTIONS ====================

/// Get gender-specific color
Color getGenderColor(String gender, {bool light = false}) {
  switch (gender.toLowerCase()) {
    case 'male':
      return light ? kMaleColorLight : kMaleColor;
    case 'female':
      return light ? kFemaleColorLight : kFemaleColor;
    default:
      return light ? kOtherColorLight : kOtherColor;
  }
}

/// Get relationship type color
Color getRelationshipColor(String relationshipType) {
  final type = relationshipType.toUpperCase();
  if (type.contains('FATHER') || type.contains('MOTHER') || type.contains('PARENT')) {
    return kRelationshipParent;
  } else if (type.contains('CHILD') || type.contains('SON') || type.contains('DAUGHTER')) {
    return kRelationshipChild;
  } else if (type.contains('SPOUSE') || type.contains('WIFE') || type.contains('HUSBAND')) {
    return kRelationshipSpouse;
  } else if (type.contains('SIBLING') || type.contains('BROTHER') || type.contains('SISTER')) {
    return kRelationshipSibling;
  }
  return kTextSecondary;
}

/// Get status color
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'verified':
    case 'approved':
    case 'active':
      return kSuccessColor;
    case 'pending':
    case 'review':
      return kWarningColor;
    case 'rejected':
    case 'inactive':
      return kErrorColor;
    default:
      return kInfoColor;
  }
}
