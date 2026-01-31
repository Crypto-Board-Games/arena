import 'package:flutter/material.dart';

/// Dangple Design System Colors
/// 
/// 모든 UI 구현은 본 문서의 컬러 토큰을 기준으로 하며, 임의의 색상 사용을 금지한다.
/// Hex 값 직접 사용 금지, 반드시 정의된 토큰 이름을 사용할 것.
class AppTheme {
  // ============================================
  // 1. Brand & Primary Colors
  // ============================================
  
  /// Primary / Active - #67A4FF
  static const Color main = Color(0xFF67A4FF);
  
  /// Primary Disabled - #67A4FF with 50% opacity
  static Color get mainDisabled => main.withOpacity(0.5);
  
  /// Secondary Accent - #297FFF
  static const Color sub = Color(0xFF297FFF);
  
  // ============================================
  // 2. Semantic Colors
  // ============================================
  
  /// Success / Positive - #00CC66
  static const Color green = Color(0xFF00CC66);
  
  /// Error / Warning / Negative - #FF5757
  static const Color red = Color(0xFFFF5757);
  
  /// Error Sub / Background
  static Color get redSub => red.withOpacity(0.2);
  
  // ============================================
  // 3. Base Colors
  // ============================================
  
  /// Absolute Black
  static const Color black = Color(0xFF000000);
  
  /// Absolute White
  static const Color white = Color(0xFFFFFFFF);
  
  /// Toast / Popup Background - #555555
  static const Color toastPopup = Color(0xFF555555);
  
  // ============================================
  // 4. Light Mode Colors
  // ============================================
  
  // Text Colors (Light)
  /// Primary Text - #262626
  static const Color fontPrimaryLight = Color(0xFF262626);
  
  /// Secondary Text - #333333
  static const Color fontSecondaryLight = Color(0xFF333333);
  
  /// Tertiary Text - #555555
  static const Color fontTertiaryLight = Color(0xFF555555);
  
  /// Guide / Hint - #777777
  static const Color fontGuideLight = Color(0xFF777777);
  
  /// Hidden / Subtle - #999999
  static const Color fontHideLight = Color(0xFF999999);
  
  /// Disabled Text - #B0B0B0
  static const Color fontDisabledLight = Color(0xFFB0B0B0);
  
  // Background & Border (Light)
  /// App Background - #FFFFFF
  static const Color bgBasicLight = Color(0xFFFFFFFF);
  
  /// Card / Section - #F4F4F4
  static const Color bgContentsLight = Color(0xFFF4F4F4);
  
  /// Divider / Border - #D9D9D9
  static const Color bgBorderLight = Color(0xFFD9D9D9);
  
  /// Disabled BG - #CCCCCC
  static const Color bgDisabledLight = Color(0xFFCCCCCC);
  
  // ============================================
  // 5. Dark Mode Colors
  // ============================================
  
  // Text Colors (Dark)
  /// Primary Text - #FFFFFF
  static const Color fontPrimaryDark = Color(0xFFFFFFFF);
  
  /// Secondary Text - #EBEEF5
  static const Color fontSecondaryDark = Color(0xFFEBEEF5);
  
  /// Tertiary Text - #DEE3EE
  static const Color fontTertiaryDark = Color(0xFFDEE3EE);
  
  /// Guide / Hint - #C7CDDB
  static const Color fontGuideDark = Color(0xFFC7CDDB);
  
  /// Hidden / Subtle - #AFB5C3
  static const Color fontHideDark = Color(0xFFAFB5C3);
  
  /// Disabled Text - #818897
  static const Color fontDisabledDark = Color(0xFF818897);
  
  // Background & Border (Dark)
  /// App Background - #15171A
  static const Color bgBasicDark = Color(0xFF15171A);
  
  /// Card / Section - #21252A
  static const Color bgContentsDark = Color(0xFF21252A);
  
  /// Divider / Border - #575C68
  static const Color bgBorderDark = Color(0xFF575C68);
  
  /// Disabled BG - #6B717F
  static const Color bgDisabledDark = Color(0xFF6B717F);
  
  // ============================================
  // 6. Game-specific Colors (Legacy Support)
  // ============================================
  
  /// 오목판 배경색
  static const Color boardColor = Color(0xFFDEB887);
  
  /// 오목판 선 색상
  static const Color boardLineColor = Color(0xFF3E2723);
  
  /// 흑돌 색상
  static const Color blackStone = Color(0xFF1A1A1A);
  
  /// 백돌 색상
  static const Color whiteStone = Color(0xFFFAFAFA);
  
  // ============================================
  // 7. Legacy Aliases (for backward compatibility)
  // ============================================
  
  @deprecated
  static const Color primary = main;
  
  @deprecated
  static const Color accent = sub;
  
  @deprecated
  static const Color background = bgBasicDark;
  
  @deprecated
  static const Color surface = bgContentsDark;
  
  @deprecated
  static const Color surfaceLight = bgContentsDark;
  
  @deprecated
  static const Color textPrimary = fontPrimaryDark;
  
  @deprecated
  static const Color textSecondary = fontSecondaryDark;
  
  @deprecated
  static const Color success = green;
  
  @deprecated
  static const Color error = red;
  
  // ============================================
  // 8. Theme Data
  // ============================================
  
  /// Dark Theme (Default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: main,
        secondary: sub,
        surface: bgContentsDark,
        background: bgBasicDark,
        error: red,
        onPrimary: white,
        onSecondary: white,
        onSurface: fontPrimaryDark,
        onBackground: fontPrimaryDark,
        onError: white,
      ),
      scaffoldBackgroundColor: bgBasicDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgContentsDark,
        foregroundColor: fontPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: bgContentsDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: main,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: main,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fontPrimaryDark,
          side: const BorderSide(color: bgBorderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgContentsDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: main, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: fontGuideDark),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: fontPrimaryDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: fontPrimaryDark,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: fontPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: fontPrimaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: fontPrimaryDark,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: fontSecondaryDark,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: fontTertiaryDark,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: bgBorderDark,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: toastPopup,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: main,
        secondary: sub,
        surface: bgContentsLight,
        background: bgBasicLight,
        error: red,
        onPrimary: white,
        onSecondary: white,
        onSurface: fontPrimaryLight,
        onBackground: fontPrimaryLight,
        onError: white,
      ),
      scaffoldBackgroundColor: bgBasicLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgContentsLight,
        foregroundColor: fontPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: bgContentsLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: main,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: main,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fontPrimaryLight,
          side: const BorderSide(color: bgBorderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgContentsLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: main, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: fontGuideLight),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: fontPrimaryLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: fontPrimaryLight,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: fontPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: fontPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: fontPrimaryLight,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: fontSecondaryLight,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: fontTertiaryLight,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: bgBorderLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: toastPopup,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
