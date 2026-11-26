import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vegetables_app/feature/main_navigation/main_navigation.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Semua',
    'Dalam Proses',
    'Selesai',
    'Dibatalkan',
  ];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'VG-9204',
      'date': 'Hari ini, 08:30 WIB',
      'status': 'Dalam Proses',
      'statusLabel': 'Sedang Dikirim',
      'statusIcon': Icons.local_shipping_rounded,
      'mainProduct': 'Wortel Berastagi Segar',
      'extraProducts': '+ 2 sayuran lainnya',
      'imageUrl':
          'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=600&auto=format&fit=crop',
      'totalItems': 3,
      'totalPrice': 38500,
      'courierName': 'Pak Joko (Driver VegBox)',
      'eta': '~15-20 menit lagi',
      'step': 3, // 1: Dipetik, 2: Dikemas, 3: Diantar
    },
    {
      'id': 'VG-8910',
      'date': 'Kemarin, 09:15 WIB',
      'status': 'Selesai',
      'statusLabel': 'Selesai',
      'statusIcon': Icons.check_circle_rounded,
      'mainProduct': 'Bayam Hijau Organik',
      'extraProducts': '+ 1 sayuran lainnya',
      'imageUrl':
          'https://images.unsplash.com/photo-1576045057995-568f588f82fb?q=80&w=600&auto=format&fit=crop',
      'totalItems': 2,
      'totalPrice': 24000,
      'receivedBy': 'Diterima oleh Doni',
    },
    {
      'id': 'VG-8755',
      'date': '16 Okt 2026, 14:20 WIB',
      'status': 'Selesai',
      'statusLabel': 'Selesai',
      'statusIcon': Icons.check_circle_rounded,
      'mainProduct': 'Brokoli Hijau Super',
      'extraProducts': '+ 3 sayuran lainnya',
      'imageUrl':
          'https://images.unsplash.com/photo-1584270354949-c26b0d5b4a0c?q=80&w=600&auto=format&fit=crop',
      'totalItems': 4,
      'totalPrice': 54000,
      'receivedBy': 'Diterima oleh Doni',
    },
    {
      'id': 'VG-8412',
      'date': '10 Okt 2026, 11:00 WIB',
      'status': 'Dibatalkan',
      'statusLabel': 'Dibatalkan',
      'statusIcon': Icons.cancel_rounded,
      'mainProduct': 'Alpukat Mentega Super',
      'extraProducts': '',
      'imageUrl':
          'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?q=80&w=600&auto=format&fit=crop',
      'totalItems': 1,
      'totalPrice': 35000,
      'cancelReason': 'Stok panen subuh habis dari petani',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilterIndex == 0) return _orders;
    final selectedFilter = _filters[_selectedFilterIndex];
    return _orders.where((o) => o['status'] == selectedFilter).toList();
  }

  int _countFor(int filterIndex) {
    if (filterIndex == 0) return _orders.length;
    final filter = _filters[filterIndex];
    return _orders.where((o) => o['status'] == filter).length;
  }

  /// true jika dibuka via Navigator.push (bukan sebagai tab MainNavigation).
  bool get _isStandalone => ModalRoute.of(context)?.canPop ?? false;

  void _showSnack(String message, IconData icon) {
    showAppSnackBar(
      context,
      message,
      icon: icon,
      aboveNavBar: !_isStandalone,
    );
  }

  void _showTrackingModal(Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: bgBackdrop,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
      ),
      builder: (sheetContext) {
        return _TrackingSheet(
          order: order,
          onCallCourier: () => _showSnack(
            'Menghubungi ${order['courierName']}...',
            Icons.phone_in_talk_rounded,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredOrders;
    final active = _orders.where((o) => o['status'] == 'Dalam Proses').length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER (otomatis menampilkan tombol kembali jika di-push)
              AppPageHeader(
                overline: 'Riwayat belanja',
                title: 'Pesanan',
                subtitle: active > 0
                    ? '$active pesanan sedang berjalan'
                    : '${_orders.length} pesanan tercatat',
              ),

              const SizedBox(height: 16),

              // 2. FILTER STATUS
              _buildFilterPills(),

              const SizedBox(height: 8),

              // 3. DAFTAR PESANAN / KOSONG
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : _buildOrderList(list),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER PILLS — selaras dengan chip kategori di Beranda
  // ---------------------------------------------------------------------------
  Widget _buildFilterPills() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _FilterPill(
            label: _filters[index],
            count: _countFor(index),
            isSelected: _selectedFilterIndex == index,
            onTap: () => setState(() => _selectedFilterIndex = index),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DAFTAR PESANAN
  // ---------------------------------------------------------------------------
  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, navBarClearance),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final isInProgress = status == 'Dalam Proses';
    final isCancelled = status == 'Dibatalkan';
    final isDone = status == 'Selesai';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(order),
          const SizedBox(height: 16),
          _buildProductRow(order, muted: isCancelled),

          // Info status: progres pengiriman / penerima / alasan batal
          if (isInProgress) ...[
            const SizedBox(height: 16),
            _buildDeliveryStrip(order),
          ],
          if (isDone && order['receivedBy'] != null) ...[
            const SizedBox(height: 14),
            _NoteStrip(
              icon: Icons.verified_rounded,
              text: order['receivedBy'] as String,
              iconColor: primaryColor,
              textColor: textDarkSecondary,
              background: surfaceMuted,
            ),
          ],
          if (isCancelled && order['cancelReason'] != null) ...[
            const SizedBox(height: 14),
            _NoteStrip(
              icon: Icons.info_outline_rounded,
              text: 'Alasan: ${order['cancelReason']}',
              iconColor: errorColor,
              textColor: red700,
              background: red50,
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: hairline),
          const SizedBox(height: 14),

          _buildActions(
            order,
            isInProgress: isInProgress,
            isCancelled: isCancelled,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> order) {
    final tone = _statusToneOf(order);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${order['id']}', style: AppText.title),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: textDarkTertiary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      order['date'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusPill(
          label: order['statusLabel'] as String,
          icon: order['statusIcon'] as IconData?,
          color: tone.color,
          background: tone.background,
        ),
      ],
    );
  }

  Widget _buildProductRow(Map<String, dynamic> order, {required bool muted}) {
    final extra = (order['extraProducts'] as String?) ?? '';
    final totalItems = (order['totalItems'] as int?) ?? 1;
    final total = order['totalPrice'];

    return Row(
      children: [
        _OrderThumbnail(
          url: order['imageUrl'] as String,
          extraCount: totalItems - 1,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['mainProduct'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 14.5),
              ),
              const SizedBox(height: 2),
              Text(
                extra.isNotEmpty ? extra : '$totalItems item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Total', style: AppText.caption.copyWith(fontSize: 11.5)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      total is num ? formatRupiah(total) : 'Rp $total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.price.copyWith(
                        fontSize: 15.5,
                        color: muted ? textDarkTertiary : textNeutralPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStrip(Map<String, dynamic> order) {
    final step = (order['step'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Estimasi tiba '),
                      TextSpan(
                        text: '${order['eta'] ?? '-'}',
                        style: AppText.captionStrong.copyWith(
                          color: forestDeep,
                        ),
                      ),
                    ],
                  ),
                  style: AppText.caption.copyWith(color: textDarkSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniProgress(step: step),
        ],
      ),
    );
  }

  Widget _buildActions(
    Map<String, dynamic> order, {
    required bool isInProgress,
    required bool isCancelled,
  }) {
    if (isInProgress) {
      return Row(
        children: [
          Expanded(
            child: _CompactButton(
              label: 'Lacak Kurir',
              icon: Icons.near_me_rounded,
              style: _CompactStyle.dark,
              onTap: () => _showTrackingModal(order),
            ),
          ),
        ],
      );
    }

    if (!isCancelled) {
      return Row(
        children: [
          Expanded(
            child: _CompactButton(
              label: 'Beri Ulasan',
              icon: Icons.star_outline_rounded,
              style: _CompactStyle.outline,
              onTap: () => _showSnack(
                'Form ulasan untuk pesanan #${order['id']} segera dibuka!',
                Icons.rate_review_rounded,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactButton(
              label: 'Beli Lagi',
              icon: Icons.replay_rounded,
              style: _CompactStyle.tonal,
              onTap: () => _showSnack(
                '${order['mainProduct']} dimasukkan ke keranjang belanja!',
                Icons.shopping_basket_rounded,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _CompactButton(
            label: 'Belanja Sayur Lain',
            icon: Icons.storefront_rounded,
            style: _CompactStyle.tonal,
            onTap: () => MainNavigation.switchToTab(context, 0),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: navBarClearance),
        child: EmptyStateView(
          icon: Icons.receipt_long_rounded,
          title: 'Belum Ada Pesanan',
          message: 'Pesanan sayuran segar harianmu akan tercatat di sini.',
          actionLabel: 'Mulai Belanja',
          actionIcon: Icons.shopping_basket_rounded,
          onAction: () => MainNavigation.switchToTab(context, 0),
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS TONE — warna status dari palet
// =============================================================================
typedef _StatusTone = ({Color color, Color background});

_StatusTone _statusToneOf(Map<String, dynamic> order) {
  final status = (order['status'] as String?) ?? '';
  final label = ((order['statusLabel'] as String?) ?? '').toLowerCase();

  if (status == 'Selesai') {
    return (color: primaryColor, background: primaryColor50);
  }
  if (status == 'Dibatalkan') {
    return (color: errorColor, background: pastelRed);
  }
  // Dalam proses: biru jika sedang dikirim, oranye untuk tahap lainnya.
  if (label.contains('kirim')) {
    return (color: textInfoPressed, background: bgSurfaceInfo);
  }
  return (color: secondaryColor600, background: secondaryColor100);
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

/// Pill filter: terpilih = hijau hutan, lainnya putih dengan bayangan lembut.
class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: EdgeInsets.only(left: 18, right: count > 0 ? 8 : 18),
        decoration: BoxDecoration(
          color: isSelected ? forestDeep : Colors.white,
          borderRadius: BorderRadius.circular(radiusPill),
          boxShadow: isSelected
              ? AppShadows.glow(forestDeep, strength: 0.22)
              : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.title.copyWith(
                fontSize: 13,
                color: isSelected ? Colors.white : textNeutralPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 26,
                constraints: const BoxConstraints(minWidth: 26),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.16)
                      : surfaceMuted,
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
                child: Text(
                  '$count',
                  style: AppText.captionStrong.copyWith(
                    fontSize: 11,
                    height: 1.1,
                    color: isSelected ? Colors.white : textDarkSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Foto produk utama + badge jumlah item lainnya.
class _OrderThumbnail extends StatelessWidget {
  final String url;
  final int extraCount;

  const _OrderThumbnail({required this.url, required this.extraCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: VegImage(
              url: url,
              iconSize: 20,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
          if (extraCount > 0)
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: forestDeep,
                  borderRadius: BorderRadius.circular(radiusPill),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extraCount',
                  style: AppText.captionStrong.copyWith(
                    fontSize: 10.5,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Progres 3 tahap ringkas (Dipetik → Dikemas → Diantar) di kartu pesanan.
class _MiniProgress extends StatelessWidget {
  final int step;

  const _MiniProgress({required this.step});

  static const _labels = ['Dipetik', 'Dikemas', 'Diantar'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < step ? primaryColor : borderNeutral,
                    borderRadius: BorderRadius.circular(radiusPill),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style:
                      (i < step
                              ? AppText.captionStrong.copyWith(
                                  color: forestDeep,
                                )
                              : AppText.caption)
                          .copyWith(fontSize: 10.5, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Catatan kecil berlatar lembut (penerima / alasan batal).
class _NoteStrip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final Color background;

  const _NoteStrip({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.caption.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CompactStyle { dark, tonal, outline }

/// Tombol aksi kapsul ringkas di kartu pesanan.
class _CompactButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final _CompactStyle style;

  const _CompactButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.style = _CompactStyle.tonal,
  });

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (style) {
      case _CompactStyle.dark:
        bg = forestDeep;
        fg = Colors.white;
        shadow = AppShadows.glow(forestDeep, strength: 0.22);
        break;
      case _CompactStyle.tonal:
        bg = primaryColor50;
        fg = primaryColor700;
        break;
      case _CompactStyle.outline:
        bg = Colors.white;
        fg = textNeutralPrimary;
        border = Border.all(color: borderNeutral, width: 1.2);
        break;
    }

    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radiusPill),
          border: border,
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title.copyWith(fontSize: 13, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TRACKING SHEET — bottom sheet pelacakan pengiriman
// =============================================================================
class _TrackingSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onCallCourier;

  const _TrackingSheet({required this.order, required this.onCallCourier});

  static const _steps = [
    (
      title: 'Pesanan Dipetik Langsung',
      subtitle: 'Sayuran segar selesai dipanen dari kebun mitra',
      time: '06:15 WIB',
      isDone: true,
      isCurrent: false,
    ),
    (
      title: 'Quality Check & Pengemasan',
      subtitle: 'Dikemas higienis dengan ice pack di Hub VegBox',
      time: '07:30 WIB',
      isDone: true,
      isCurrent: false,
    ),
    (
      title: 'Kurir Sedang Menuju Lokasimu',
      subtitle: 'Dalam perjalanan membawa pesanan segar',
      time: '08:30 WIB',
      isDone: true,
      isCurrent: true,
    ),
    (
      title: 'Pesanan Sampai di Rumahmu',
      subtitle: 'Estimasi tiba dalam ~15 menit',
      time: '08:50 WIB',
      isDone: false,
      isCurrent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text('STATUS TERKINI', style: AppText.overline),
                  const SizedBox(height: 6),
                  Text('Pelacakan Pengiriman', style: AppText.h2),
                  const SizedBox(height: 2),
                  Text(
                    'No. Pesanan #${order['id']}',
                    style: AppText.caption,
                  ),

                  const SizedBox(height: 20),
                  _buildCourierCard(),

                  const SizedBox(height: 28),
                  Text('Perjalanan Pesanan', style: AppText.h3),
                  const SizedBox(height: 14),

                  // Timeline
                  for (int i = 0; i < _steps.length; i++)
                    _TimelineStep(
                      title: _steps[i].title,
                      subtitle: _steps[i].subtitle,
                      time: _steps[i].time,
                      isDone: _steps[i].isDone,
                      isCurrent: _steps[i].isCurrent,
                      nextDone: i < _steps.length - 1 && _steps[i + 1].isDone,
                      isFirst: i == 0,
                      isLast: i == _steps.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu hijau hutan berisi estimasi tiba & info kurir.
  Widget _buildCourierCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: AppShadows.glow(forestDeep, strength: 0.22),
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -40, child: _decorCircle(150, 0.06)),
          Positioned(bottom: -36, left: -24, child: _decorCircle(96, 0.05)),
          Positioned(
            top: 6,
            right: -12,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.eco_rounded,
                size: 96,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMASI TIBA',
                  style: AppText.overline.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order['eta'] ?? '-'}',
                  style: AppText.h1.copyWith(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${order['courierName'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kurir resmi VegBox Express',
                            style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppCircleButton(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: primaryColor,
                      onTap: onCallCourier,
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

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Satu langkah timeline: titik hijau penuh (selesai), titik bercincin
/// bercahaya (saat ini), titik kosong (menunggu) + garis penghubung.
class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isDone;
  final bool isCurrent;
  final bool nextDone;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDone,
    required this.isCurrent,
    required this.nextDone,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final topLine = isFirst
        ? Colors.transparent
        : (isDone ? primaryColor : borderNeutral);
    final bottomLine = isLast
        ? Colors.transparent
        : (nextDone ? primaryColor : borderNeutral);

    final Color titleColor = isCurrent
        ? forestDeep
        : (isDone ? textNeutralPrimary : textDarkTertiary);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolom titik & garis
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(width: 2, height: 8, color: topLine),
                _buildDot(),
                Expanded(child: Container(width: 2, color: bottomLine)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Konten langkah
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: isCurrent ? primaryColor50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppText.title.copyWith(
                              fontSize: 13.5,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          time,
                          style: isCurrent
                              ? AppText.captionStrong.copyWith(
                                  fontSize: 11,
                                  color: primaryColor,
                                )
                              : AppText.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.caption.copyWith(
                        color: isDone ? textDarkSecondary : textDarkTertiary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 10),
                      const StatusPill(
                        label: 'Sedang berlangsung',
                        icon: Icons.radio_button_checked_rounded,
                        background: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor100, width: 4),
          boxShadow: AppShadows.glow(primaryColor, strength: 0.35),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: isDone
            ? Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              )
            : Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderNeutral, width: 2),
                ),
              ),
      ),
    );
  }
}
