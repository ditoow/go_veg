import 'package:flutter/material.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/typography.dart';

class DialogUtils {
  static Color get _barrierColor => inkSoft.withValues(alpha: 0.45);

  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: _barrierColor,
      builder: (BuildContext context) {
        return _DialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: primaryColor50,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        color: primaryColor,
                        backgroundColor: primaryColor100,
                      ),
                    ),
                    const Icon(
                      Icons.eco_rounded,
                      size: 22,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('MOHON TUNGGU', style: AppText.overline),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: _barrierColor,
      builder: (BuildContext context) {
        return _DialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DialogIcon(
                icon: Icons.close_rounded,
                color: errorColor,
                outer: red50,
                inner: red100,
              ),
              const SizedBox(height: 18),
              Text(
                'Terjadi Kesalahan',
                textAlign: TextAlign.center,
                style: AppText.h2,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.dark,
                height: 52,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void showCancelTrxDialog(
    BuildContext context,
    void Function()? onPressed,
  ) {
    showDialog(
      context: context,
      barrierColor: _barrierColor,
      builder: (context) {
        return _DialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DialogIcon(
                icon: Icons.credit_card_off_rounded,
                color: secondaryColor600,
                outer: secondaryColor50,
                inner: secondaryColor100,
              ),
              const SizedBox(height: 18),
              Text(
                'Batalkan Transaksi?',
                textAlign: TextAlign.center,
                style: AppText.h2,
              ),
              const SizedBox(height: 8),
              Text(
                'Langkah anda tinggal sedikit lagi, apakah anda yakin ingin '
                'membatalkan transaksi saat ini?',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Ya, Sekarang',
                variant: AppButtonVariant.danger,
                height: 52,
                onPressed: onPressed,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Tidak Sekarang',
                variant: AppButtonVariant.outline,
                height: 52,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

// -----------------------------------------------------------------------------
// Komponen privat
// -----------------------------------------------------------------------------

/// Kerangka dialog putih membulat yang seragam.
class _DialogShell extends StatelessWidget {
  final Widget child;

  const _DialogShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius2xl - 4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: child,
        ),
      ),
    );
  }
}

/// Ikon dalam dua lingkaran berwarna lembut.
class _DialogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color outer;
  final Color inner;

  const _DialogIcon({
    required this.icon,
    required this.color,
    required this.outer,
    required this.inner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(color: outer, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(color: inner, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
