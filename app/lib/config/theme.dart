import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ==================== COLOR PALETTE ====================

/// Primary brand colors - Deep Indigo (Premium Heritage)
const Color kPrimaryColor = Color(0xFF4A5899);        // Royal Indigo
const Color kPrimaryLight = Color(0xFF7B86C8);        // Soft Periwinkle
const Color kPrimaryDark = Color(0xFF2D3561);         // Midnight Indigo

/// Secondary colors - Rose Gold & Copper
const Color kSecondaryColor = Color(0xFFB87E85);      // Dusty Rose
const Color kSecondaryLight = Color(0xFFE5B5BA);      // Pale Blush
const Color kSecondaryDark = Color(0xFF8A5A5F);       // Deep Mauve

/// Accent colors - Vibrant Amber & Teal
const Color kAccentColor = Color(0xFFFF8C42);         // Warm Amber
const Color kAccentLight = Color(0xFFFFB976);         // Golden Peach
const Color kAccentDark = Color(0xFFE66A1E);          // Deep Orange

/// Gender-based colors (softer, more modern)
const Color kMaleColor = Color(0xFF5B9BD5);           // Soft Blue
const Color kMaleColorLight = Color(0xFFD6E9F8);      // Pale Blue
const Color kFemaleColor = Color(0xFFE8799A);         // Soft Rose
const Color kFemaleColorLight = Color(0xFFFCE4EC);    // Pale Rose
const Color kOtherColor = Color(0xFF9575CD);          // Soft Violet
const Color kOtherColorLight = Color(0xFFEDE7F6);     // Pale Violet

/// Neutral colors - Rich sophisticated tones
const Color kBackgroundColor = Color(0xFFFAF9F8);     // Creamy White
const Color kSurfaceColor = Color(0xFFFFFFFF);        // Pure White
const Color kSurfaceSecondary = Color(0xFFF5F3F2);   // Warm Linen
const Color kDividerColor = Color(0xFFE6E3E1);        // Soft Taupe
const Color kTextPrimary = Color(0xFF1C1917);         // Rich Black
const Color kTextSecondary = Color(0xFF78716C);       // Warm Stone
const Color kTextDisabled = Color(0xFFA8A29E);        // Light Stone

/// Status colors (refined)
const Color kSuccessColor = Color(0xFF40C057);        // Fresh Green
const Color kWarningColor = Color(0xFFFFB020);        // Warm Amber
const Color kErrorColor = Color(0xFFE03E3E);          // Clean Red
const Color kInfoColor = Color(0xFF339AF0);           // Clear Blue

/// Relationship type colors
const Color kRelationshipParent = Color(0xFF7C5CFC);  // Vivid Purple
const Color kRelationshipChild = Color(0xFF20C997);   // Teal Mint
const Color kRelationshipSpouse = Color(0xFFE8549A);  // Deep Rose
const Color kRelationshipSibling = Color(0xFF5C7CFA); // Periwinkle

/// Sidebar colors
const Color kSidebarBg = Color(0xFF2D3561);           // Midnight Indigo (sidebar bg)
const Color kSidebarBgLight = Color(0xFF4A5899);      // Royal Indigo (sidebar hover)
const Color kSidebarText = Color(0xFFE8E7F3);         // Pale Lavender Text
const Color kSidebarActive = Color(0xFF7B86C8);       // Active Periwinkle

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
  static const double borderRadiusXl = 20.0;
  
  static const double cardElevation = 0.0;
  static const double cardElevationHovered = 4.0;
  
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;

  // Sidebar
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
  
  // Responsive breakpoints
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
}

// ==================== GRADIENTS ====================

class AppGradients {
  /// Sidebar gradient — midnight to royal indigo
  static const LinearGradient sidebar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kSidebarBg, Color(0xFF3A4478)],
  );

  /// Header accent gradient
  static const LinearGradient headerAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [kPrimaryDark, kPrimaryColor],
  );

  /// Primary button gradient - Indigo to Periwinkle
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kPrimaryColor, Color(0xFF6875B0)],
  );

  /// Card header gradient (subtle lavender)
  static const LinearGradient cardHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F7FC), Color(0xFFFFFFFF)],
  );

  /// Hero section gradient for landing - Deep indigo to rose
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F3D), kPrimaryDark, kPrimaryColor, Color(0xFF7B86C8)],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  /// Rich hero gradient with deep contrast
  static const LinearGradient heroRich = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF151A2E), Color(0xFF2D3561), Color(0xFF4A5899), Color(0xFF7B86C8)],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Sunset warm gradient for CTA sections - Indigo to amber
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D3561), Color(0xFF4A5899), Color(0xFFFF8C42)],
  );

  /// Features section subtle gradient - Lavender to blush
  static const LinearGradient featuresBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F7FC), Color(0xFFFAF5F6), Color(0xFFFAF9F8)],
  );

  /// Glass overlay gradient
  static const LinearGradient glassOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x30FFFFFF), Color(0x10FFFFFF)],
  );

  /// Warm accent gradient (amber to peach)
  static const LinearGradient warmAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kAccentColor, kAccentLight],
  );
}

// ==================== TYPOGRAPHY ====================

class AppTextStyles {
  // Using Playfair Display for elegant headings (heritage feel)
  // Using Inter for modern, readable body text
  
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );
  
  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    height: 1.22,
  );
  
  static TextStyle headlineLarge = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  static TextStyle headlineMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.3,
  );
  
  static TextStyle headlineSmall = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );
  
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );
  
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static TextStyle labelSmall = GoogleFonts.inter(
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
    surface: kSurfaceColor,
    onSurface: kTextPrimary,
    surfaceContainerHighest: kSurfaceSecondary,
    onSurfaceVariant: kTextSecondary,
    outline: kDividerColor,
    outlineVariant: Color(0xFFF0F2F5),
    shadow: Color(0x1A000000),
    scrim: Colors.black54,
    inverseSurface: Color(0xFF2D3136),
    onInverseSurface: Color(0xFFF4F5F7),
    inversePrimary: kPrimaryLight,
    surfaceTint: Colors.transparent,
  ),
  
  // Typography
  textTheme: TextTheme(
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
  
  // AppBar Theme — Modern white with subtle border
  appBarTheme: AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: kSurfaceColor,
    foregroundColor: kTextPrimary,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.3,
    ),
    iconTheme: const IconThemeData(color: kTextSecondary, size: 22),
    actionsIconTheme: const IconThemeData(color: kTextSecondary, size: 22),
  ),
  
  // Card Theme — Flat with subtle border, modern feel
  cardTheme: CardThemeData(
    elevation: AppSizing.cardElevation,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusLg),
      side: const BorderSide(color: kDividerColor, width: 1),
    ),
    color: kSurfaceColor,
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    clipBehavior: Clip.antiAlias,
  ),
  
  // Button Themes — No longer full-width by default
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(160, AppSizing.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      ),
      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
    ),
  ),
  
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      minimumSize: const Size(160, AppSizing.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      side: const BorderSide(color: kPrimaryColor, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.borderRadius),
      ),
      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
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
  
  // Input Decoration Theme — softer, modern
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kErrorColor, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kErrorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    hintStyle: const TextStyle(color: kTextDisabled, fontSize: 14),
    labelStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500),
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
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kSurfaceColor,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: kTextDisabled,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: AppTextStyles.labelSmall,
    unselectedLabelStyle: AppTextStyles.labelSmall,
  ),
  
  // Floating Action Button Theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: kAccentColor,
    foregroundColor: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  
  // Scaffold Background
  scaffoldBackgroundColor: kBackgroundColor,
  
  // Tab Bar Theme
  tabBarTheme: TabBarThemeData(
    labelColor: kPrimaryColor,
    unselectedLabelColor: kTextSecondary,
    indicatorColor: kPrimaryColor,
    labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
    unselectedLabelStyle: AppTextStyles.labelLarge,
    indicator: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
      color: kPrimaryColor.withValues(alpha: 0.1),
    ),
  ),

  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: kSurfaceColor,
    elevation: 8,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusXl),
    ),
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: kTextPrimary),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: kTextSecondary),
  ),
  
  // Snackbar Theme
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2D3136),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizing.borderRadius),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 4,
  ),
  
  // Progress Indicator Theme
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: kPrimaryColor,
    linearTrackColor: Color(0xFFE8ECF0),
    circularTrackColor: Color(0xFFE8ECF0),
  ),

  // Tooltip Theme
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF2D3136),
      borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
    ),
    textStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
