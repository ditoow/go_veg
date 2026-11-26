import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vegetables_app/ui/app_back_button.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/typography.dart';

/// ============================================================================
/// APP WIDGETS — komponen dasar desain "Botanical Luxe".
/// Semua layar memakai komponen ini supaya tampilannya konsisten.
/// ============================================================================

/// Format angka ke Rupiah: 3500 -> "Rp 3.500"
String formatRupiah(num value) =>
    'Rp ${NumberFormat('#,###', 'id_ID').format(value)}';

// ---------------------------------------------------------------------------
// Pressable — efek mengecil halus saat ditekan (pengganti ripple).
// ---------------------------------------------------------------------------
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppCircleButton — tombol ikon bulat dengan badge opsional.
// ---------------------------------------------------------------------------
enum CircleButtonStyle {
  /// Putih + bayangan lembut (di atas background terang)
  light,

  /// Putih transparan (di atas header hijau gelap / foto)
  glass,

  /// Hijau hutan gelap
  dark,

  /// Hijau muda dengan ikon hijau
  tonal,
}

class AppCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final CircleButtonStyle style;
  final double size;
  final double iconSize;
  final int? badgeCount;
  final Color? iconColor;

  const AppCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.style = CircleButtonStyle.light,
    this.size = 44,
    this.iconSize = 20,
    this.badgeCount,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (style) {
      case CircleButtonStyle.light:
        bg = Colors.white;
        fg = textNeutralPrimary;
        shadow = AppShadows.soft;
        break;
      case CircleButtonStyle.glass:
        bg = Colors.white.withValues(alpha: 0.14);
        fg = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.22));
        break;
      case CircleButtonStyle.dark:
        bg = forestDeep;
        fg = Colors.white;
        break;
      case CircleButtonStyle.tonal:
        bg = primaryColor50;
        fg = primaryColor;
        break;
    }

    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border,
              boxShadow: shadow,
            ),
            child: Icon(icon, size: iconSize, color: iconColor ?? fg),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: -3,
              right: -3,
              child: CountBadge(count: badgeCount!),
            ),
        ],
      ),
    );
  }
}

/// Badge angka kecil berwarna oranye (aksen sekunder palet).
class CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const CountBadge({super.key, required this.count, this.color = secondaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppPageHeader — header halaman yang seragam.
// ---------------------------------------------------------------------------
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? overline;
  final Widget? trailing;

  /// null = otomatis (tampil jika halaman bisa di-pop)
  final bool? showBack;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.overline,
    this.trailing,
    this.showBack,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 8),
  });

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? (ModalRoute.of(context)?.canPop ?? false);

    if (canPop) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            AppBackButton(onTap: onBack),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h2,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null) ...[
                  Text(overline!.toUpperCase(), style: AppText.overline),
                  const SizedBox(height: 6),
                ],
                Text(title, style: AppText.h1),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppText.body.copyWith(fontSize: 13)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionHeader — judul section dengan overline & aksi opsional.
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null) ...[
                  Text(overline!.toUpperCase(), style: AppText.overline),
                  const SizedBox(height: 4),
                ],
                Text(title, style: AppText.h2),
              ],
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppText.captionStrong.copyWith(
                        color: primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppCard — kartu putih dengan sudut membulat & bayangan lembut.
// ---------------------------------------------------------------------------
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool elevated;
  final bool outlined;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = radiusXl,
    this.color = Colors.white,
    this.gradient,
    this.onTap,
    this.elevated = true,
    this.outlined = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: outlined ? Border.all(color: hairline, width: 1.2) : null,
        boxShadow: elevated ? AppShadows.soft : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Pressable(onTap: onTap, pressedScale: 0.985, child: card);
  }
}

// ---------------------------------------------------------------------------
// AppButton — tombol utama berbentuk kapsul.
// ---------------------------------------------------------------------------
enum AppButtonVariant { primary, dark, outline, tonal, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final AppButtonVariant variant;
  final double height;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.height = 56,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    Color? bg;
    Gradient? gradient;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case AppButtonVariant.primary:
        gradient = AppGradients.primary;
        fg = Colors.white;
        shadow = enabled ? AppShadows.glow(primaryColor, strength: 0.28) : null;
        break;
      case AppButtonVariant.dark:
        bg = forestDeep;
        fg = Colors.white;
        shadow = enabled ? AppShadows.glow(forestDeep, strength: 0.25) : null;
        break;
      case AppButtonVariant.outline:
        bg = Colors.white;
        fg = textNeutralPrimary;
        border = Border.all(color: borderNeutral, width: 1.2);
        break;
      case AppButtonVariant.tonal:
        bg = primaryColor50;
        fg = primaryColor700;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = primaryColor;
        break;
      case AppButtonVariant.danger:
        bg = red50;
        fg = errorColor;
        border = Border.all(color: red100);
        break;
    }

    final content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button.copyWith(color: fg),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(trailingIcon, size: 20, color: fg),
              ],
            ],
          );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled || isLoading ? 1 : 0.5,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: expand ? double.infinity : null,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bg,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radiusPill),
            border: border,
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QuantityStepper — pengatur jumlah ( −  2  + ).
// ---------------------------------------------------------------------------
class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.value,
    this.onIncrement,
    this.onDecrement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = compact ? 28.0 : 36.0;
    final icon = compact ? 16.0 : 18.0;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            size: btn,
            iconSize: icon,
            onTap: onDecrement,
            filled: false,
          ),
          SizedBox(
            width: compact ? 30 : 38,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: compact ? 13 : 15),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: btn,
            iconSize: icon,
            onTap: onIncrement,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool filled;

  const _StepButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? primaryColor : Colors.white,
          shape: BoxShape.circle,
          boxShadow: filled ? null : AppShadows.soft,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: filled
              ? Colors.white
              : (disabled ? textDarkTertiary : textNeutralPrimary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VegImage — gambar produk dari jaringan dengan placeholder yang rapi.
// ---------------------------------------------------------------------------
class VegImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;

  const VegImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _VegPlaceholder(iconSize: iconSize);

    final image = url.trim().isEmpty
        ? placeholder
        : LayoutBuilder(
            builder: (context, constraints) {
              // Decode gambar sesuai ukuran tampil (bukan resolusi asli)
              // supaya hemat memori & tidak bikin frame tersendat.
              // Dibulatkan ke kelipatan 360px agar ukuran yang berubah tiap
              // frame (mis. animasi Hero) tidak memicu decode berulang.
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final width = constraints.maxWidth.isFinite
                  ? ((constraints.maxWidth * dpr) / 360).ceil() * 360
                  : null;
              return Image.network(
                url,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: width,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _VegPlaceholder(iconSize: iconSize, loading: true);
                },
                errorBuilder: (context, error, stack) => placeholder,
              );
            },
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _VegPlaceholder extends StatelessWidget {
  final double iconSize;
  final bool loading;

  const _VegPlaceholder({required this.iconSize, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor50, Color(0xFFF6FAF7)],
        ),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: loading ? 0.35 : 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: iconSize * 1.9,
            height: iconSize * 1.9,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco_rounded,
              size: iconSize,
              color: primaryColor300,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EmptyStateView — tampilan kosong / error yang elegan.
// ---------------------------------------------------------------------------
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color tone;
  final Color toneBackground;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.tone = primaryColor,
    this.toneBackground = primaryColor50,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: toneBackground.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: toneBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: tone),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: AppText.h2),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: AppText.body),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              expand: false,
              height: 50,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// StatusPill — label status kecil berbentuk kapsul.
// ---------------------------------------------------------------------------
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.color = primaryColor,
    this.background = primaryColor50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.captionStrong.copyWith(
              color: color,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppTextField — input dengan label di atas & ikon.
// ---------------------------------------------------------------------------
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTap,
    this.focusNode,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppText.captionStrong.copyWith(color: textNeutralPrimary),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          onTap: onTap,
          autofillHints: autofillHints,
          cursorColor: primaryColor,
          style: AppText.bodyStrong,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 10),
                    child: Icon(prefixIcon, size: 20),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SheetHandle — garis kecil di atas bottom sheet.
// ---------------------------------------------------------------------------
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: borderNeutral,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Snackbar seragam
// ---------------------------------------------------------------------------
enum AppSnackType { success, error, info }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.success,
  IconData? icon,

  /// true jika halaman berada di dalam MainNavigation (ada floating nav bar)
  bool aboveNavBar = false,
}) {
  final Color bg = switch (type) {
    AppSnackType.success => forestDeep,
    AppSnackType.error => const Color(0xFF7F1D1D),
    AppSnackType.info => textNeutralPrimary,
  };
  final IconData effectiveIcon = icon ??
      switch (type) {
        AppSnackType.success => Icons.check_rounded,
        AppSnackType.error => Icons.error_outline_rounded,
        AppSnackType.info => Icons.info_outline_rounded,
      };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 0,
      duration: const Duration(milliseconds: 1800),
      margin: EdgeInsets.fromLTRB(20, 0, 20, aboveNavBar ? 108 : 24),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      content: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(effectiveIcon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppText.bodyStrong.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
