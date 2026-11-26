import 'package:flutter/material.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/style.dart';

/// Tombol kembali yang seragam di seluruh aplikasi.
class AppBackButton extends StatefulWidget {
  final VoidCallback? onTap;

  /// true jika diletakkan di atas foto (detail produk)
  final bool isFrosted;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const AppBackButton({
    super.key,
    this.onTap,
    this.isFrosted = false,
    this.iconColor,
    this.backgroundColor,
    this.size = 44.0,
    this.iconSize = 18.0,
  });

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ??
        (widget.isFrosted
            ? Colors.white.withValues(alpha: 0.94)
            : Colors.white);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap ?? () => Navigator.maybePop(context),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.iconColor ?? textNeutralPrimary,
            size: widget.iconSize,
          ),
        ),
      ),
    );
  }
}
