import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Semua',
    'Pesanan',
    'Promo & Panen',
    'Info Sistem',
  ];

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Pesanan Sedang Dikirim',
      'message':
          'Paket sayur organik #VG-8921 sedang dalam perjalanan ke alamatmu bersama kurir.',
      'time': '10 menit lalu',
      'group': 'Hari Ini',
      'category': 'Pesanan',
      'icon': Icons.local_shipping_outlined,
      'iconColor': primaryColor,
      'bgColor': pastelMint,
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Panen Subuh Tiba! Diskon 20%',
      'message':
          'Sayuran bayam, brokoli, dan wortel baru saja dipanen subuh ini langsung dari petani Ambarawa.',
      'time': '06.30 WIB',
      'group': 'Hari Ini',
      'category': 'Promo & Panen',
      'icon': Icons.eco_outlined,
      'iconColor': primaryColor,
      'bgColor': pastelMint,
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'Voucher Gratis Ongkir Aktif',
      'message':
          'Klaim voucher potongan ongkos kirim hingga Rp 15.000 untuk belanja kebutuhan sayur harianmu.',
      'time': 'Kemarin, 14.15',
      'group': 'Kemarin',
      'category': 'Promo & Panen',
      'icon': Icons.discount_outlined,
      'iconColor': secondaryColor600,
      'bgColor': pastelOrange,
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'Pesanan Selesai #VG-8910',
      'message':
          'Terima kasih telah berbelanja di VegBox! Jangan lupa beri ulasan kesegaran sayuranmu.',
      'time': 'Kemarin, 09.00',
      'group': 'Kemarin',
      'category': 'Pesanan',
      'icon': Icons.check_circle_outline_rounded,
      'iconColor': primaryColor,
      'bgColor': pastelMint,
      'isRead': true,
    },
    {
      'id': '5',
      'title': 'Akun Berhasil Diverifikasi',
      'message':
          'Nomor HP dan email kamu telah aktif untuk keamanan transaksi belanja yang lebih baik.',
      'time': '18 Okt 2026',
      'group': 'Terdahulu',
      'category': 'Info Sistem',
      'icon': Icons.security_rounded,
      'iconColor': infoColor,
      'bgColor': pastelBlue,
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _notifications;
    final selectedFilter = _filters[_selectedFilterIndex];
    return _notifications
        .where((n) => n['category'] == selectedFilter)
        .toList();
  }

  static bool _isUnread(Map<String, dynamic> item) =>
      !((item['isRead'] as bool?) ?? true);

  int get _unreadCount => _notifications.where(_isUnread).length;

  /// Jumlah notifikasi belum dibaca untuk tiap filter (ditampilkan di pill).
  int _unreadCountFor(int filterIndex) {
    final filter = _filters[filterIndex];
    return _notifications
        .where(
          (n) =>
              _isUnread(n) && (filterIndex == 0 || n['category'] == filter),
        )
        .length;
  }

  /// true jika dibuka via Navigator.push (bukan sebagai tab MainNavigation).
  bool get _isStandalone => ModalRoute.of(context)?.canPop ?? false;

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isRead'] = true;
      }
    });

    showAppSnackBar(
      context,
      'Semua notifikasi ditandai telah dibaca',
      icon: Icons.done_all_rounded,
      aboveNavBar: !_isStandalone,
    );
  }

  void _markAsRead(Map<String, dynamic> item) {
    if (!_isUnread(item)) return;
    setState(() {
      item['isRead'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredNotifications;
    final unread = _unreadCount;

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
                overline: 'Kabar terbaru',
                title: 'Notifikasi',
                subtitle: unread > 0
                    ? '$unread notifikasi belum dibaca'
                    : 'Semua notifikasi sudah dibaca',
                trailing: _MarkAllReadButton(
                  enabled: unread > 0,
                  onTap: _markAllAsRead,
                ),
              ),

              const SizedBox(height: 16),

              // 2. FILTER KATEGORI
              _buildFilterPills(),

              const SizedBox(height: 8),

              // 3. DAFTAR NOTIFIKASI / KOSONG
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(list),
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
            count: _unreadCountFor(index),
            isSelected: _selectedFilterIndex == index,
            onTap: () => setState(() => _selectedFilterIndex = index),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DAFTAR — dikelompokkan per waktu (Hari Ini, Kemarin, Terdahulu)
  // ---------------------------------------------------------------------------
  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      groups.putIfAbsent(item['group'] as String, () => []).add(item);
    }
    final entries = groups.entries.toList();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, navBarClearance),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 26),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildGroup(entry.key, entry.value);
      },
    );
  }

  Widget _buildGroup(String title, List<Map<String, dynamic>> items) {
    final unread = items.where(_isUnread).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppText.overline.copyWith(color: textDarkTertiary),
                ),
              ),
              if (unread > 0)
                Text(
                  '$unread baru',
                  style: AppText.captionStrong.copyWith(
                    color: primaryColor,
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radiusXl),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 78,
                    color: hairline,
                  ),
                _NotificationTile(
                  item: items[i],
                  onTap: () => _markAsRead(items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return const Center(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: navBarClearance),
        child: EmptyStateView(
          icon: Icons.notifications_off_rounded,
          title: 'Belum Ada Notifikasi',
          message:
              'Update pengiriman pesanan dan panen sayur segar harian akan muncul di sini.',
        ),
      ),
    );
  }
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

/// Tombol kapsul "Tandai dibaca" di header.
class _MarkAllReadButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _MarkAllReadButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : surfaceMuted,
          borderRadius: BorderRadius.circular(radiusPill),
          boxShadow: enabled ? AppShadows.soft : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 17,
              color: enabled ? primaryColor : textDarkTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'Tandai dibaca',
              style: AppText.captionStrong.copyWith(
                fontSize: 12.5,
                color: enabled ? textNeutralPrimary : textDarkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                      : primaryColor50,
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
                child: Text(
                  '$count',
                  style: AppText.captionStrong.copyWith(
                    fontSize: 11,
                    height: 1.1,
                    color: isSelected ? Colors.white : primaryColor700,
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

/// Satu baris notifikasi di dalam kartu grup.
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !((item['isRead'] as bool?) ?? true);
    final accent = item['iconColor'] as Color;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        color: isUnread
            ? primaryColor50.withValues(alpha: 0.55)
            : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon bulat berwarna sesuai jenis notifikasi
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item['bgColor'] as Color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(item['icon'] as IconData, color: accent, size: 21),
            ),
            const SizedBox(width: 14),

            // Judul, isi, waktu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: AppText.title.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, left: 10),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['message'] as String,
                    style: AppText.body.copyWith(fontSize: 12.5, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item['category'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.captionStrong.copyWith(
                            fontSize: 11,
                            color: accent,
                          ),
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(
                          color: textDarkTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: AppText.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
