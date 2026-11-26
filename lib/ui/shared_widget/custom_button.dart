import 'package:flutter/material.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/typography.dart';

/// Tombol kapsul lama — kini tampil seperti [AppButton] varian primary.
/// API tetap sama supaya pemanggil lama tidak perlu diubah.
class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 54,
    this.backgroundColor,
    this.borderRadius = radiusPill,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final glowColor = backgroundColor ?? primaryColor;

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled || isLoading ? 1 : 0.5,
        child: Pressable(
          onTap: enabled ? onPressed : null,
          child: Container(
            width: width ?? double.infinity,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: backgroundColor == null ? AppGradients.primary : null,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: enabled
                  ? AppShadows.glow(glowColor, strength: 0.28)
                  : null,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                    ),
                  )
                : IconTheme.merge(
                    data: const IconThemeData(color: Colors.white, size: 20),
                    child: DefaultTextStyle.merge(
                      style: AppText.button.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
