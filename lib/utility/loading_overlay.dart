import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/typography.dart';

class LoadingOverlay {
  LoadingOverlay();

  OverlayEntry? _overlay;

  void show(BuildContext context) {
    if (_overlay == null) {
      _overlay = OverlayEntry(
        builder: (context) => PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              hide();
            }
          },
          child: _OverlayBackdrop(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radiusXl),
                boxShadow: AppShadows.floating,
              ),
              alignment: Alignment.center,
              child: const _BrandSpinner(size: 52),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlay!);
    }
  }

  void showProcess(
    BuildContext context, {
    String? title,
    String? message,
    String? image,
  }) {
    if (_overlay == null) {
      _overlay = OverlayEntry(
        builder: (context) => _OverlayBackdrop(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius2xl - 4),
              boxShadow: AppShadows.floating,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (image != null)
                  Image.asset(
                    image,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stack) =>
                        const _ProcessBadge(),
                  )
                else
                  const _ProcessBadge(),
                const SizedBox(height: 22),
                Text(
                  'SEDANG DIPROSES',
                  style: AppText.overline,
                ),
                const SizedBox(height: 8),
                Text(
                  title ?? 'Tunggu sebentar',
                  textAlign: TextAlign.center,
                  style: AppText.h2,
                ),
                const SizedBox(height: 6),
                Text(
                  message ?? 'Sedang memproses...',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radiusPill),
                  child: const LinearProgressIndicator(
                    minHeight: 5,
                    color: primaryColor,
                    backgroundColor: primaryColor50,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlay!);
    }
  }

  void hide() {
    if (_overlay != null) {
      _overlay?.remove();
      _overlay = null;
    }
  }
}

// -----------------------------------------------------------------------------
// Komponen privat
// -----------------------------------------------------------------------------

/// Latar gelap lembut dengan sedikit blur di belakang konten overlay.
class _OverlayBackdrop extends StatelessWidget {
  final Widget child;

  const _OverlayBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: inkSoft.withValues(alpha: 0.45),
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Spinner hijau dengan ikon daun di tengah.
class _BrandSpinner extends StatelessWidget {
  final double size;

  const _BrandSpinner({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              color: primaryColor,
              backgroundColor: primaryColor50,
            ),
          ),
          Icon(Icons.eco_rounded, size: size * 0.4, color: primaryColor),
        ],
      ),
    );
  }
}

/// Ilustrasi proses pembayaran (pengganti gambar aset).
class _ProcessBadge extends StatelessWidget {
  const _ProcessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: const BoxDecoration(
        color: primaryColor50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(primaryColor, strength: 0.3),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
