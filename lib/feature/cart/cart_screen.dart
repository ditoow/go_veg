import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_cubit.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_state.dart';
import 'package:vegetables_app/feature/cart/model/cart_item_model.dart';
import 'package:vegetables_app/feature/detail/detail_screen.dart';
import 'package:vegetables_app/feature/main_navigation/main_navigation.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  /// Jarak bawah checkout bar: tepat di atas floating nav bar MainNavigation
  /// (nav bar: bottom 16 + tinggi 70, lalu jarak 14).
  static const double _checkoutBarBottom = 100;
  static const double _checkoutBarHeight = 72;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final isEmpty = state.items.isEmpty;

              return Column(
                children: [
                  AppPageHeader(
                    showBack: false,
                    overline: 'Belanjaan kamu',
                    title: 'Keranjang',
                    subtitle: isEmpty
                        ? null
                        : '${state.totalItems} item · ${state.items.length} produk',
                    trailing: isEmpty
                        ? null
                        : _ClearCartButton(
                            onTap: () => _showClearDialog(context),
                          ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  ),
                  Expanded(
                    child: isEmpty
                        ? _buildEmptyCart(context)
                        : _buildCartContent(context, state),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: navBarClearance - 24),
        child: EmptyStateView(
          icon: Icons.shopping_basket_outlined,
          title: 'Keranjang masih kosong',
          message:
              'Yuk, temukan sayur segar pilihanmu dan tambahkan ke keranjang.',
          actionLabel: 'Mulai Belanja',
          actionIcon: Icons.eco_rounded,
          onAction: () => MainNavigation.switchToTab(context, 0),
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartState state) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            _checkoutBarBottom + _checkoutBarHeight + 28 + bottomInset,
          ),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // Daftar item keranjang
            for (final item in state.items)
              Padding(
                key: ValueKey(item.vegetable.id),
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCartCard(context, item),
              ),

            const SizedBox(height: 10),

            // Ringkasan pembayaran
            _buildSummaryCard(state),
          ],
        ),

        // Fade lembut agar konten tidak "bertabrakan" dengan bar melayang
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _checkoutBarBottom + _checkoutBarHeight + 36 + bottomInset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgApp.withValues(alpha: 0),
                    bgApp.withValues(alpha: 0.92),
                    bgApp,
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
        ),

        // Sticky checkout bar — tepat di atas floating nav bar
        Positioned(
          left: 20,
          right: 20,
          bottom: _checkoutBarBottom + bottomInset,
          child: _buildCheckoutBar(context, state),
        ),
      ],
    );
  }

  Widget _buildCartCard(BuildContext context, CartItemModel item) {
    final veg = item.vegetable;
    final cart = context.read<CartCubit>();

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Foto sayuran
          Pressable(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(vegetable: veg),
                ),
              );
            },
            child: SizedBox(
              width: 88,
              height: 88,
              child: VegImage(
                url: veg.gambar,
                borderRadius: BorderRadius.circular(radiusMd),
                iconSize: 26,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Detail produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            veg.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatRupiah(veg.harga)} / item',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      pressedScale: 0.85,
                      onTap: () => cart.removeItem(veg.id),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: textDarkTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatRupiah(item.subtotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.price.copyWith(
                          fontSize: 15.5,
                          color: textNeutralPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    QuantityStepper(
                      compact: true,
                      value: item.quantity,
                      onDecrement: () =>
                          cart.updateQuantity(veg.id, item.quantity - 1),
                      onIncrement: () =>
                          cart.updateQuantity(veg.id, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartState state) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Belanja', style: AppText.h3),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Subtotal (${state.totalItems} item)',
            Text(formatRupiah(state.totalPrice), style: AppText.bodyStrong),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Ongkos kirim',
            const StatusPill(
              label: 'Gratis',
              icon: Icons.local_shipping_rounded,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: hairline, height: 1, thickness: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Total Pembayaran', style: AppText.title),
              ),
              Text(
                formatRupiah(state.totalPrice),
                style: AppText.price.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, Widget value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.body.copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 12),
        value,
      ],
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartState state) {
    return Container(
      height: _checkoutBarHeight,
      padding: const EdgeInsets.fromLTRB(24, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Total tagihan', style: AppText.caption),
                Text(
                  formatRupiah(state.totalPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.price.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: 'Checkout',
            trailingIcon: Icons.arrow_forward_rounded,
            expand: false,
            height: 52,
            onPressed: () => _handleCheckout(context),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: bgBackdrop,
      builder: (dialogCtx) => _ThemedDialog(
        icon: Icons.check_rounded,
        title: 'Pesanan Berhasil!',
        message:
            'Terima kasih! Pesanan sayuran segar kamu sedang disiapkan oleh petani dan kurir kami.',
        actions: AppButton(
          label: 'Lihat Pesanan',
          trailingIcon: Icons.arrow_forward_rounded,
          height: 52,
          onPressed: () {
            Navigator.pop(dialogCtx);
            context.read<CartCubit>().clearCart();
            MainNavigation.switchToTab(
              context,
              3,
            ); // Pindah ke riwayat pesanan
          },
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: bgBackdrop,
      builder: (dialogCtx) => _ThemedDialog(
        icon: Icons.delete_sweep_rounded,
        tone: errorColor,
        toneBackground: red50,
        title: 'Kosongkan Keranjang?',
        message: 'Semua produk dalam keranjang belanja akan dihapus.',
        actions: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Batal',
                variant: AppButtonVariant.outline,
                height: 50,
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Kosongkan',
                variant: AppButtonVariant.danger,
                height: 50,
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.read<CartCubit>().clearCart();
                  showAppSnackBar(
                    context,
                    'Keranjang berhasil dikosongkan',
                    type: AppSnackType.info,
                    icon: Icons.delete_sweep_rounded,
                    aboveNavBar: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol kapsul "Kosongkan" di header.
class _ClearCartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearCartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        decoration: BoxDecoration(
          color: red50,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: errorColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Kosongkan',
              style: AppText.captionStrong.copyWith(color: errorColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog bergaya "Botanical Luxe": ikon bulat, judul, pesan, aksi.
class _ThemedDialog extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color toneBackground;
  final String title;
  final String message;
  final Widget actions;

  const _ThemedDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.tone = primaryColor,
    this.toneBackground = primaryColor50,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius2xl - 4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: toneBackground.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: toneBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: tone),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            actions,
          ],
        ),
      ),
    );
  }
}
