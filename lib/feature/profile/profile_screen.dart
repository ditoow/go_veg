import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:vegetables_app/config/constant.dart';
import 'package:vegetables_app/config/service_locator.dart';
import 'package:vegetables_app/config/user_preference.dart';
import 'package:vegetables_app/feature/favorite/favorite_screen.dart';
import 'package:vegetables_app/providers/favorite_provider.dart';
import 'package:vegetables_app/feature/login/login_screen.dart';
import 'package:vegetables_app/feature/main_navigation/main_navigation.dart';
import 'package:vegetables_app/feature/profile/edit_profile_screen.dart';
import 'package:vegetables_app/feature/profile/faq_screen.dart';
import 'package:vegetables_app/feature/profile/settings_screen.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Pengguna GoVeg';
  String _userEmail = '';
  String _userPhone = '+62 812-3456-7890';
  String _userAddress =
      'Jl. Nakula I No. 5-11, Pendrikan Kidul, Semarang Tengah';
  String? _userPhotoUrl;

  /// Jarak kartu aksi cepat yang "keluar" dari bawah header.
  static const double _quickActionsOverlap = 52;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user =
        Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    final userPref = serviceLocator.get<UserPreference>();

    if (user != null) {
      setState(() {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _userName = user.displayName!;
        } else if (userPref.getUserName() != null &&
            userPref.getUserName()!.isNotEmpty) {
          _userName = userPref.getUserName()!;
        }

        if (user.email != null && user.email!.isNotEmpty) {
          _userEmail = user.email!;
        } else if (userPref.getUserEmail() != null &&
            userPref.getUserEmail()!.isNotEmpty) {
          _userEmail = userPref.getUserEmail()!;
        }

        _userPhotoUrl = user.photoURL;
      });
    }
  }

  String get _initials {
    if (_userName.trim().isEmpty) return 'VB';
    final parts = _userName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String get _appVersionLabel {
    if (serviceLocator.isRegistered<PackageInfo>()) {
      final info = serviceLocator.get<PackageInfo>();
      if (info.version.isNotEmpty) {
        return info.buildNumber.isEmpty
            ? info.version
            : '${info.version} (${info.buildNumber})';
      }
    }
    return appVersion;
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
          initialAddress: _userAddress,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _userName = result['name'] ?? _userName;
        _userEmail = result['email'] ?? _userEmail;
        _userPhone = result['phone'] ?? _userPhone;
        _userAddress = result['address'] ?? _userAddress;
      });
    }
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteScreen()),
    );
  }

  void _openFaq() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaqScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: inkSoft.withValues(alpha: 0.45),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
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
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: red50,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: red100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: errorColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Keluar dari akun?', style: AppText.h2),
                const SizedBox(height: 8),
                Text(
                  'Apakah kamu yakin ingin keluar dari akun GoVeg? '
                  'Kamu perlu login kembali untuk berbelanja.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Ya, Keluar',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.danger,
                  height: 52,
                  onPressed: () async {
                    Navigator.pop(dialogCtx);

                    try {
                      await GoogleSignIn().signOut();
                    } catch (_) {}
                    try {
                      if (Firebase.apps.isNotEmpty) {
                        await FirebaseAuth.instance.signOut();
                      }
                    } catch (_) {}
                    try {
                      await serviceLocator.get<UserPreference>().clearData();
                    } catch (_) {}

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.ghost,
                  height: 48,
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeaderWithQuickActions(),
            const SizedBox(height: 28),
            _buildMenuGroup(
              overline: 'Akun',
              items: [
                _ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: primaryColor,
                  iconBackground: primaryColor50,
                  title: 'Edit Profil',
                  subtitle: _userPhone,
                  onTap: _navigateToEditProfile,
                ),
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  iconColor: yellow600,
                  iconBackground: pastelYellow,
                  title: 'Alamat Pengiriman',
                  subtitle: _userAddress,
                  onTap: _navigateToEditProfile,
                ),
                _ProfileMenuItem(
                  icon: Icons.favorite_border_rounded,
                  iconColor: errorColor,
                  iconBackground: pastelRed,
                  title: 'Sayuran Favorit',
                  subtitle: 'Daftar produk sayur yang kamu sukai',
                  onTap: _openFavorites,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMenuGroup(
              overline: 'Bantuan & Preferensi',
              items: [
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  iconColor: secondaryColor600,
                  iconBackground: pastelOrange,
                  title: 'Pusat Bantuan & FAQ',
                  subtitle: 'Pertanyaan umum seputar pesanan sayur',
                  onTap: _openFaq,
                ),
                _ProfileMenuItem(
                  icon: Icons.tune_rounded,
                  iconColor: iconInfoPressed,
                  iconBackground: pastelBlue,
                  title: 'Pengaturan',
                  subtitle: 'Notifikasi, bahasa, dan tampilan aplikasi',
                  onTap: _openSettings,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton(
                label: 'Keluar Akun',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.danger,
                height: 54,
                onPressed: _showLogoutDialog,
              ),
            ),
            const SizedBox(height: 24),
            _buildVersionCaption(),
            const SizedBox(height: navBarClearance),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO HEADER + AKSI CEPAT
  // ---------------------------------------------------------------------------
  Widget _buildHeaderWithQuickActions() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _quickActionsOverlap),
          child: _buildHeroHeader(),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _buildQuickActions(),
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    final canPop = Navigator.canPop(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ornamen lingkaran & daun (dekoratif)
          Positioned(
            top: -70,
            right: -50,
            child: _decorCircle(220, 0.06),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _decorCircle(160, 0.05),
          ),
          Positioned(
            top: 64,
            right: -22,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.eco_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                28 + _quickActionsOverlap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canPop) ...[
                        AppCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          iconSize: 18,
                          style: CircleButtonStyle.glass,
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AKUN SAYA',
                              style: AppText.overline.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Profil',
                              style: AppText.h2.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.h2.copyWith(color: Colors.white),
                            ),
                            if (_userEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildEditPill(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Widget _buildAvatar() {
    final initials = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppText.h2.copyWith(color: primaryColor700, fontSize: 24),
      ),
    );

    final photoUrl = _userPhotoUrl;

    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photoUrl == null || photoUrl.trim().isEmpty
            ? initials
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stack) => initials,
              ),
      ),
    );
  }

  Widget _buildEditPill() {
    return Pressable(
      onTap: _navigateToEditProfile,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(radiusPill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Edit profil',
              style: AppText.captionStrong.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.receipt_long_rounded,
              label: 'Pesanan',
              color: primaryColor,
              background: primaryColor50,
              onTap: () => MainNavigation.switchToTab(context, 3),
            ),
          ),
          _verticalHairline(),
          Expanded(
            child: Consumer<FavoriteProvider>(
              builder: (context, favProvider, _) {
                return _QuickAction(
                  icon: Icons.favorite_rounded,
                  label: 'Favorit',
                  color: errorColor,
                  background: pastelRed,
                  badgeCount: favProvider.favorites.length,
                  onTap: _openFavorites,
                );
              },
            ),
          ),
          _verticalHairline(),
          Expanded(
            child: _QuickAction(
              icon: Icons.tune_rounded,
              label: 'Pengaturan',
              color: iconInfoPressed,
              background: pastelBlue,
              onTap: _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalHairline() {
    return Container(width: 1, height: 40, color: hairline);
  }

  // ---------------------------------------------------------------------------
  // 2. MENU
  // ---------------------------------------------------------------------------
  Widget _buildMenuGroup({
    required String overline,
    required List<_ProfileMenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(overline.toUpperCase(), style: AppText.overline),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _ProfileMenuTile(item: items[i]),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: hairline,
                      indent: 74,
                      endIndent: 18,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. VERSI APLIKASI
  // ---------------------------------------------------------------------------
  Widget _buildVersionCaption() {
    return Column(
      children: [
        const Icon(Icons.eco_rounded, size: 18, color: primaryColor300),
        const SizedBox(height: 6),
        Text(
          'GoVeg · Versi $_appVersionLabel',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Komponen privat
// -----------------------------------------------------------------------------
class _ProfileMenuItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ProfileMenuTile extends StatelessWidget {
  final _ProfileMenuItem item;

  const _ProfileMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: item.onTap,
      pressedScale: 0.985,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.title, style: AppText.title),
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: textDarkTertiary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: CountBadge(count: badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.captionStrong.copyWith(
              color: textNeutralPrimary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
