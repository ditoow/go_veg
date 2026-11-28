import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vegetables_app/feature/cart/cart_screen.dart';
import 'package:vegetables_app/feature/home/home_screen.dart';
import 'package:vegetables_app/feature/notification/notification_screen.dart';
import 'package:vegetables_app/feature/orders/order_history_screen.dart';
import 'package:vegetables_app/feature/profile/profile_screen.dart';
import 'package:vegetables_app/providers/cart_provider.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  /// Helper untuk berpindah tab dari screen anak (misalnya dari Home Screen)
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    if (state != null) {
      state.setTab(index);
    } else {
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        );
      } else if (index == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      }
    }
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavEntry {
  final String label;
  final String? svg;
  final IconData? icon;
  final IconData? activeIcon;

  const _NavEntry({required this.label, this.svg, this.icon, this.activeIcon});
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  static const _entries = [
    _NavEntry(label: 'Beranda', svg: 'assets/svg/home.svg'),
    _NavEntry(
      label: 'Notifikasi',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    _NavEntry(label: 'Keranjang', svg: 'assets/svg/basket.svg'),
    _NavEntry(label: 'Pesanan', svg: 'assets/svg/document.svg'),
    _NavEntry(label: 'Profil', svg: 'assets/svg/profile.svg'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    NotificationScreen(),
    CartScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgApp,
      body: Stack(
        children: [
          // Konten tab (state tidak reload saat ganti tab)
          IndexedStack(
            index: _currentIndex,
            children: [
              // Hero hanya aktif di tab yang sedang tampil, supaya tag gambar
              // di tab tersembunyi tidak ikut "terbang" saat buka detail.
              for (int i = 0; i < _pages.length; i++)
                HeroMode(enabled: i == _currentIndex, child: _pages[i]),
            ],
          ),

          // Floating nav bar hijau hutan
          Positioned(
            left: 20,
            right: 20,
            bottom: 16 + bottomInset,
            child: _buildNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: forestDeep,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < _entries.length; i++)
            if (i == 2)
              Selector<CartProvider, int>(
                selector: (_, cart) => cart.totalItems,
                builder: (context, totalItems, _) =>
                    _buildNavItem(i, badge: totalItems),
              )
            else
              _buildNavItem(i),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, {int badge = 0}) {
    final entry = _entries[index];
    final isSelected = _currentIndex == index;
    final color = isSelected ? forestDeep : Colors.white.withValues(alpha: 0.6);

    final Widget icon = entry.svg != null
        ? SvgPicture.asset(
            entry.svg!,
            width: 21,
            height: 21,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(
            isSelected ? (entry.activeIcon ?? entry.icon) : entry.icon,
            size: 23,
            color: color,
          );

    return Pressable(
      onTap: () => setState(() => _currentIndex = index),
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                if (badge > 0)
                  Positioned(
                    top: -9,
                    right: -11,
                    child: CountBadge(count: badge),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: forestDeep,
                          letterSpacing: -0.1,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
