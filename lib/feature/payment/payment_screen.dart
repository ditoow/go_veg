import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_cubit.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentMethod {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  const _PaymentMethod({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const List<_PaymentMethod> _methods = [
    _PaymentMethod(
      title: 'QRIS',
      subtitle: 'Scan dengan aplikasi pembayaran apa saja',
      icon: Icons.qr_code_2_rounded,
      tint: primaryColor50,
    ),
    _PaymentMethod(
      title: 'Transfer Bank',
      subtitle: 'Pilih bank lalu bayar lewat Virtual Account',
      icon: Icons.account_balance_rounded,
      tint: pastelBlue,
    ),
    _PaymentMethod(
      title: 'E-Wallet',
      subtitle: 'Pilih e-wallet lalu lanjutkan pembayaran',
      icon: Icons.account_balance_wallet_rounded,
      tint: pastelOrange,
    ),
    _PaymentMethod(
      title: 'Bayar di Tempat',
      subtitle: 'Bayar tunai saat pesanan tiba',
      icon: Icons.payments_rounded,
      tint: pastelYellow,
    ),
  ];

  static const String _merchantName = 'GoVeg Demo Store';
  static const String _nmid = 'ID1024667788990';
  static const List<String> _banks = ['BCA', 'BNI', 'Mandiri', 'BRI'];
  static const List<String> _wallets = ['GoPay', 'OVO', 'DANA', 'ShopeePay'];
  static const Map<String, String> _virtualAccounts = {
    'BCA': '8808 0812 3456 7890',
    'BNI': '8810 0812 3456 7890',
    'Mandiri': '8950 8081 2345 6789',
    'BRI': '8888 0812 3456 7890',
  };
  static const Map<String, String> _walletNumbers = {
    'GoPay': '0812 3456 7890',
    'OVO': '0813 4567 8901',
    'DANA': '0814 5678 9012',
    'ShopeePay': '0815 6789 0123',
  };

  int _selectedIndex = 0;
  String _selectedBank = 'BCA';
  String _selectedWallet = 'GoPay';
  bool _isProcessing = false;
  int _totalItems = 0;
  int _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartCubit>().state;
    _totalItems = cart.totalItems;
    _totalPrice = cart.totalPrice;
  }

  String get _paymentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Pembayaran QRIS';
      case 1:
        return 'Transfer Bank $_selectedBank';
      case 2:
        return 'E-Wallet $_selectedWallet';
      default:
        return 'Bayar di Tempat';
    }
  }

  String get _paymentSubtitle {
    switch (_selectedIndex) {
      case 0:
        return 'Scan kode QRIS di bawah ini';
      case 1:
        return 'Gunakan nomor Virtual Account berikut';
      case 2:
        return 'Lanjutkan pembayaran lewat aplikasi e-wallet';
      default:
        return 'Pembayaran dilakukan saat pesanan tiba';
    }
  }

  Future<void> _handlePay() async {
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PaymentSheet(
        title: _paymentTitle,
        subtitle: _paymentSubtitle,
        content: _buildPaymentContent(),
        confirmLabel: _selectedIndex == 3
            ? 'Konfirmasi Pesanan'
            : 'Saya Sudah Bayar',
        onConfirm: () {
          Navigator.pop(sheetCtx);
          _processPayment();
        },
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    context.read<CartCubit>().clearCart();
    setState(() => _isProcessing = false);

    await _showSuccessDialog();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierColor: bgBackdrop,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
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
                  color: primaryColor50.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: primaryColor50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 28,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pembayaran Berhasil!',
                textAlign: TextAlign.center,
                style: AppText.h2,
              ),
              const SizedBox(height: 8),
              Text(
                'Terima kasih! Pesanan sayuran segar kamu sedang disiapkan oleh petani dan kurir kami.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Lihat Pesanan',
                trailingIcon: Icons.arrow_forward_rounded,
                height: 52,
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.darkStatusBar,
        child: Scaffold(
          backgroundColor: bgApp,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const AppPageHeader(
                  title: 'Pembayaran',
                  subtitle: 'Pilih metode pembayaran favoritmu',
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      Text('Metode Pembayaran', style: AppText.h3),
                      const SizedBox(height: 12),
                      ...List.generate(
                        _methods.length,
                        (index) => _buildMethodCard(index),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pesanan', style: AppText.h3),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Subtotal ($_totalItems item)',
            Text(formatRupiah(_totalPrice), style: AppText.bodyStrong),
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
              Expanded(child: Text('Total Pembayaran', style: AppText.title)),
              Text(
                formatRupiah(_totalPrice),
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

  Widget _buildMethodCard(int index) {
    final method = _methods[index];
    final isSelected = _selectedIndex == index;
    final hasDropdown = index == 1 || index == 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: isSelected ? primaryColor : hairline,
          width: isSelected ? 1.6 : 1.2,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: _isProcessing
                ? null
                : () => setState(() => _selectedIndex = index),
            pressedScale: 0.985,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: method.tint,
                    borderRadius: BorderRadius.circular(radiusMd),
                  ),
                  child: Icon(method.icon, color: primaryColor, size: 23),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.title, style: AppText.title),
                      const SizedBox(height: 3),
                      Text(
                        method.subtitle,
                        style: AppText.caption.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.white,
                    border: Border.all(
                      color: isSelected ? primaryColor : borderNeutral,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (isSelected && hasDropdown) ...[
            const SizedBox(height: 14),
            const Divider(color: hairline, height: 1, thickness: 1),
            const SizedBox(height: 12),
            if (index == 1)
              _buildDropdownField(
                label: 'Pilih bank',
                value: _selectedBank,
                items: _banks,
                onSelected: (value) => setState(() => _selectedBank = value),
              )
            else
              _buildDropdownField(
                label: 'Pilih e-wallet',
                value: _selectedWallet,
                items: _wallets,
                onSelected: (value) => setState(() => _selectedWallet = value),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          enabled: !_isProcessing,
          initialValue: value,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          constraints: const BoxConstraints(minWidth: 220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          onSelected: onSelected,
          itemBuilder: (context) => items
              .map(
                (item) => PopupMenuItem<String>(
                  value: item,
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(child: Text(item, style: AppText.bodyStrong)),
                      if (item == value)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: surfaceMuted,
              borderRadius: BorderRadius.circular(radiusMd),
              border: Border.all(color: hairline),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: AppText.bodyStrong)),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textDarkSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildQrisDetail();
      case 1:
        return _buildBankDetail();
      case 2:
        return _buildWalletDetail();
      default:
        return _buildCashDetail();
    }
  }

  Widget _buildQrisDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoHeader(
          icon: Icons.qr_code_2_rounded,
          tint: primaryColor50,
          title: 'QRIS',
          subtitle: _merchantName,
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radiusMd),
              border: Border.all(color: hairline),
            ),
            child: SizedBox(
              width: 176,
              height: 176,
              child: CustomPaint(painter: const _DummyQrPainter()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('NMID', _nmid),
        const SizedBox(height: 8),
        _buildDetailRow('Nominal', formatRupiah(_totalPrice)),
        const SizedBox(height: 12),
        Text(
          'Data QRIS dummy untuk pengujian pembayaran.',
          style: AppText.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBankDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoHeader(
          icon: Icons.account_balance_rounded,
          tint: pastelBlue,
          title: 'Bank $_selectedBank',
          subtitle: 'Virtual Account',
        ),
        const SizedBox(height: 16),
        Text('Nomor Virtual Account', style: AppText.caption),
        const SizedBox(height: 4),
        Text(
          _virtualAccounts[_selectedBank]!,
          style: AppText.bodyStrong.copyWith(
            fontSize: 16,
            letterSpacing: 1.2,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Nominal', formatRupiah(_totalPrice)),
        const SizedBox(height: 12),
        Text(
          'Nomor VA dummy untuk pengujian pembayaran.',
          style: AppText.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildWalletDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoHeader(
          icon: Icons.account_balance_wallet_rounded,
          tint: pastelOrange,
          title: _selectedWallet,
          subtitle: 'E-Wallet',
        ),
        const SizedBox(height: 16),
        Text('Nomor HP terdaftar', style: AppText.caption),
        const SizedBox(height: 4),
        Text(
          _walletNumbers[_selectedWallet]!,
          style: AppText.bodyStrong.copyWith(
            fontSize: 16,
            letterSpacing: 1.2,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Nominal', formatRupiah(_totalPrice)),
        const SizedBox(height: 12),
        Text(
          'Nomor e-wallet dummy untuk pengujian pembayaran.',
          style: AppText.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCashDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoHeader(
          icon: Icons.payments_rounded,
          tint: pastelYellow,
          title: 'Bayar di Tempat',
          subtitle: 'Pembayaran tunai',
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Nominal', formatRupiah(_totalPrice)),
        const SizedBox(height: 12),
        Text(
          'Siapkan uang tunai sebesar ${formatRupiah(_totalPrice)} saat pesanan tiba.',
          style: AppText.body.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildInfoHeader({
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          child: Icon(icon, color: primaryColor, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.caption)),
        const SizedBox(width: 12),
        Text(value, style: AppText.bodyStrong.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total tagihan', style: AppText.caption),
                    Text(
                      formatRupiah(_totalPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.price.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Bayar Sekarang',
                expand: false,
                height: 52,
                isLoading: _isProcessing,
                onPressed: _handlePay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _PaymentSheet({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  static const int _timeoutSeconds = 10 * 60;

  Timer? _timer;
  int _remainingSeconds = _timeoutSeconds;

  bool get _expired => _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds <= 60;
    final Color tone = _expired || isUrgent ? errorColor : secondaryColor700;
    final Color background = _expired || isUrgent ? red50 : pastelYellow;
    final Color border = _expired || isUrgent ? red100 : yellow100;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              Text(widget.title, style: AppText.h2),
              const SizedBox(height: 4),
              Text(widget.subtitle, style: AppText.body.copyWith(fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(radiusMd),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _expired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      size: 20,
                      color: tone,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _expired
                            ? 'Waktu pembayaran habis'
                            : 'Selesaikan pembayaran dalam',
                        style: AppText.captionStrong.copyWith(color: tone),
                      ),
                    ),
                    Text(
                      _countdownLabel,
                      style: AppText.title.copyWith(
                        fontSize: 16,
                        color: tone,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              widget.content,
              const SizedBox(height: 24),
              AppButton(
                label: _expired
                    ? 'Waktu Pembayaran Habis'
                    : widget.confirmLabel,
                icon: _expired
                    ? Icons.timer_off_outlined
                    : Icons.check_circle_outline_rounded,
                height: 54,
                onPressed: _expired ? null : widget.onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// QR dummy untuk keperluan pengujian tampilan pembayaran.
class _DummyQrPainter extends CustomPainter {
  const _DummyQrPainter();

  static const int _modules = 25;
  static const int _seed = 17;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / _modules;
    final Paint dark = Paint()..color = textNeutralPrimary;

    for (int row = 0; row < _modules; row++) {
      for (int col = 0; col < _modules; col++) {
        if (_insideFinder(row, col)) continue;
        final int hash =
            (row * 73856093) ^ (col * 19349663) ^ (_seed * 83492791);
        if ((hash & 1) == 0) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            dark,
          );
        }
      }
    }

    _drawFinder(canvas, dark, cell, 0, 0);
    _drawFinder(canvas, dark, cell, 0, _modules - 7);
    _drawFinder(canvas, dark, cell, _modules - 7, 0);
  }

  bool _insideFinder(int row, int col) {
    bool inBox(int startRow, int startCol) =>
        row >= startRow &&
        row < startRow + 7 &&
        col >= startCol &&
        col < startCol + 7;

    return inBox(0, 0) || inBox(0, _modules - 7) || inBox(_modules - 7, 0);
  }

  void _drawFinder(Canvas canvas, Paint dark, double cell, int row, int col) {
    final Rect outer = Rect.fromLTWH(
      col * cell,
      row * cell,
      cell * 7,
      cell * 7,
    );
    final Rect middle = Rect.fromLTWH(
      (col + 1) * cell,
      (row + 1) * cell,
      cell * 5,
      cell * 5,
    );
    final Rect inner = Rect.fromLTWH(
      (col + 2) * cell,
      (row + 2) * cell,
      cell * 3,
      cell * 3,
    );

    canvas.drawRect(outer, dark);
    canvas.drawRect(middle, Paint()..color = Colors.white);
    canvas.drawRect(inner, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
