import 'package:flutter/material.dart';
import 'package:vegetables_app/config/constant.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/typography.dart';

extension ToastExtension on BuildContext {
  void showCustomToast({
    required String title,
    required String message,
    required bool isSuccess,
    Duration? duration,
    SnackBarPosition? position,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    final tone = isSuccess ? primaryColor : errorColor;
    final toneBackground = isSuccess ? primaryColor50 : red50;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        margin: EdgeInsets.only(
          bottom:
              MediaQuery.of(this).size.height *
              (position == SnackBarPosition.top ? 0.75 : 0.10),
          left: 20,
          right: 20,
          top: kToolbarHeight,
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radiusLg),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: toneBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: tone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppText.title.copyWith(color: textNeutralPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        message,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: messenger.hideCurrentSnackBar,
                pressedScale: 0.88,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: textDarkTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
