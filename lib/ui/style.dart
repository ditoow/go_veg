import 'package:flutter/material.dart';

import 'package:vegetables_app/ui/typography.dart';

import 'color.dart';
import 'dimension.dart';

/// ============================================================================
/// SHADOWS & GRADIENTS (Redesign)
/// Bayangan berlapis yang lembut menggantikan border tebal supaya terasa
/// lebih "premium".
/// ============================================================================
class AppShadows {
  AppShadows._();

  /// Untuk kartu biasa di atas background terang.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: inkSoft.withValues(alpha: 0.045),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: inkSoft.withValues(alpha: 0.03),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// Untuk elemen yang melayang (nav bar, bottom bar, tombol utama).
  static List<BoxShadow> get floating => [
        BoxShadow(
          color: inkSoft.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: inkSoft.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Cahaya berwarna di bawah tombol/ikon utama.
  static List<BoxShadow> glow(Color color, {double strength = 0.32}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppGradients {
  AppGradients._();

  /// Hijau hutan gelap — dipakai untuk hero header & area premium.
  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor600, primaryColor800, primaryColor900],
    stops: [0.0, 0.55, 1.0],
  );

  /// Hijau utama untuk tombol.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, primaryColor700],
  );

  /// Lapisan gelap di atas foto agar teks terbaca.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x66000000)],
  );
}

/// ============================================================================
/// COMPONENT THEMES
/// ============================================================================
final ElevatedButtonThemeData elevatedButtonThemeData = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    foregroundColor: textButtonPrimary,
    backgroundColor: bgButtonPrimaryDefault,
    disabledForegroundColor: textDisabled,
    disabledBackgroundColor: bgDisabled,
    textStyle: AppText.button,
    minimumSize: const Size(0, 52),
    elevation: 0,
    splashFactory: NoSplash.splashFactory,
    shadowColor: Colors.transparent,
  ).copyWith(
    overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.08)),
  ),
);

final OutlinedButtonThemeData outlinedButtonThemeData = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    foregroundColor: textNeutralPrimary,
    side: const BorderSide(color: borderNeutral, width: 1.2),
    textStyle: AppText.button,
    minimumSize: const Size(0, 52),
    splashFactory: NoSplash.splashFactory,
  ).copyWith(
    overlayColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.04)),
  ),
);

ButtonStyle elevatedButtonLargeStyle = ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  textStyle: AppText.button,
  shape: const StadiumBorder(),
);

ButtonStyle outlinedButtonLargeStyle = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  textStyle: AppText.button,
  shape: const StadiumBorder(),
);

InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  hintStyle: AppText.body.copyWith(color: textDarkTertiary),
  labelStyle: AppText.captionStrong,
  floatingLabelStyle: AppText.captionStrong.copyWith(color: primaryColor),
  counterStyle: AppText.caption,
  errorStyle: AppText.caption.copyWith(color: errorColor),
  floatingLabelBehavior: FloatingLabelBehavior.never,
  prefixIconColor: WidgetStateColor.resolveWith(
    (states) =>
        states.contains(WidgetState.focused) ? primaryColor : textDarkTertiary,
  ),
  suffixIconColor: textDarkTertiary,
  fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return bgDisabled;
    if (states.contains(WidgetState.focused)) return Colors.white;
    return surfaceMuted;
  }),
  filled: true,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: Colors.transparent),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: Colors.transparent),
  ),
  focusColor: borderButtonOutlinedFocused,
  disabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: Colors.transparent),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: primaryColor, width: 1.4),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: borderFormDanger, width: 1.4),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMd),
    borderSide: const BorderSide(color: borderFormDanger),
  ),
);

AppBarTheme appbarTheme = AppBarTheme(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  titleTextStyle: AppText.h2,
  iconTheme: const IconThemeData(color: textNeutralPrimary),
);

TextButtonThemeData textButtonThemeData = TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: textButtonSecondaryDefault,
    textStyle: AppText.title,
    shape: const StadiumBorder(),
    splashFactory: NoSplash.splashFactory,
  ).copyWith(
    overlayColor: WidgetStateProperty.all(primaryColor.withValues(alpha: 0.06)),
  ),
);

SnackBarThemeData snackBarThemeData = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: forestDeep,
  contentTextStyle: AppText.bodyStrong.copyWith(color: Colors.white),
  elevation: 0,
  insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
);

const BottomSheetThemeData bottomSheetThemeData = BottomSheetThemeData(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  modalBackgroundColor: Colors.white,
  showDragHandle: false,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
  ),
);

DialogThemeData dialogThemeData = DialogThemeData(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius2xl - 4),
  ),
  titleTextStyle: AppText.h2,
  contentTextStyle: AppText.body,
);

/// Dekorasi input standar (dipakai oleh form lama).
InputDecoration inputDecoration([bool? enabled]) {
  return InputDecoration(enabled: enabled ?? true);
}
