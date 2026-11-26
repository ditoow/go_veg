import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/typography.dart';

class AppTheme {
  /// Status bar transparan dengan ikon gelap (untuk halaman berlatar terang).
  static const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Status bar transparan dengan ikon terang (untuk header hijau gelap).
  static const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData get light => _build();

  /// Mode gelap belum didesain — sementara memakai tema terang.
  static ThemeData get dark => _build();

  static ThemeData _build() {
    final textTheme = TextTheme(
      displayLarge: AppText.display,
      displayMedium: AppText.display.copyWith(fontSize: 24),
      displaySmall: AppText.h1,
      headlineLarge: AppText.h1,
      headlineMedium: AppText.h2,
      headlineSmall: AppText.h3,
      titleLarge: AppText.h3,
      titleMedium: AppText.title,
      titleSmall: AppText.captionStrong.copyWith(color: textNeutralPrimary),
      bodyLarge: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: AppText.body.copyWith(color: textNeutralPrimary),
      bodySmall: AppText.caption,
      labelLarge: AppText.button,
      labelMedium: AppText.captionStrong,
      labelSmall: AppText.caption.copyWith(fontSize: 11),
    );

    return ThemeData(
      fontFamily: 'Poppins',
      useMaterial3: true,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryColor50,
        onPrimaryContainer: primaryColor900,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryColor50,
        onSecondaryContainer: secondaryColor700,
        error: errorColor,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: textNeutralPrimary,
        surfaceTint: Colors.transparent,
        outline: borderNeutral,
        outlineVariant: hairline,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: bgApp,
      canvasColor: bgApp,
      dividerTheme: const DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      outlinedButtonTheme: outlinedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      inputDecorationTheme: inputDecorationTheme,
      appBarTheme: appbarTheme,
      snackBarTheme: snackBarThemeData,
      bottomSheetTheme: bottomSheetThemeData,
      dialogTheme: dialogThemeData,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : borderNeutral,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
