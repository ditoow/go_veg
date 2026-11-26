import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;
  bool _promoPanenNotif = true;
  bool _orderStatusNotif = true;
  bool _isDarkMode = false;
  String _selectedLanguage = 'ID'; // 'ID' or 'EN'

  void _setLanguage(String code) {
    if (_selectedLanguage == code) return;
    setState(() => _selectedLanguage = code);
    showAppSnackBar(
      context,
      _selectedLanguage == 'ID'
          ? 'Bahasa diubah ke Bahasa Indonesia'
          : 'Language switched to English',
      icon: Icons.translate_rounded,
    );
  }

  void _setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    setState(() => _isDarkMode = value);
    showAppSnackBar(
      context,
      _isDarkMode ? 'Mode Gelap diaktifkan' : 'Mode Terang diaktifkan',
      icon: _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          child: Column(
            children: [
              const AppPageHeader(
                title: 'Pengaturan',
                subtitle: 'Notifikasi, bahasa & tampilan',
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Section 1: Notifikasi
                    _buildSectionLabel('Notifikasi'),
                    _buildGroupCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_active_outlined,
                        iconColor: primaryColor,
                        iconBackground: primaryColor50,
                        title: 'Push Notifikasi',
                        subtitle: 'Terima pembaruan aplikasi langsung',
                        value: _pushNotif,
                        onChanged: (val) => setState(() => _pushNotif = val),
                      ),
                      _buildSwitchTile(
                        icon: Icons.local_offer_outlined,
                        iconColor: secondaryColor600,
                        iconBackground: pastelOrange,
                        title: 'Info Panen Subuh & Promo',
                        subtitle: 'Kabar sayur segar dipetik pagi hari',
                        value: _promoPanenNotif,
                        onChanged: (val) =>
                            setState(() => _promoPanenNotif = val),
                      ),
                      _buildSwitchTile(
                        icon: Icons.local_shipping_outlined,
                        iconColor: iconInfoPressed,
                        iconBackground: pastelBlue,
                        title: 'Status Pengiriman Pesanan',
                        subtitle: 'Lacak proses kemas dan kurir berjalan',
                        value: _orderStatusNotif,
                        onChanged: (val) =>
                            setState(() => _orderStatusNotif = val),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // Section 2: Preferensi Sistem (Bahasa & Dark Mode)
                    _buildSectionLabel('Preferensi & Tampilan'),
                    _buildGroupCard([
                      _buildPickerTile(
                        leading: const Icon(
                          Icons.translate_rounded,
                          color: jacarta600,
                          size: 20,
                        ),
                        iconBackground: pastelPurple,
                        title: 'Bahasa Aplikasi',
                        subtitle: _selectedLanguage == 'ID'
                            ? 'Bahasa Indonesia aktif'
                            : 'English language active',
                        valueLabel: _selectedLanguage == 'ID' ? 'ID' : 'ENG',
                        onTap: _showLanguagePicker,
                      ),
                      _buildPickerTile(
                        leading: SvgPicture.asset(
                          _isDarkMode
                              ? 'assets/svg/moon.svg'
                              : 'assets/svg/sun.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            textNeutralPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        iconBackground: surfaceMuted,
                        title: 'Mode Gelap (Dark Mode)',
                        subtitle: _isDarkMode
                            ? 'Tema malam aktif'
                            : 'Tema terang aktif',
                        valueLabel: _isDarkMode ? 'Gelap' : 'Terang',
                        onTap: _showThemePicker,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Komponen list
  // ---------------------------------------------------------------------------
  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: AppText.overline),
    );
  }

  Widget _buildGroupCard(List<Widget> tiles) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
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
    );
  }

  Widget _buildIconCircle(Widget child, Color background) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildTileText(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppText.title),
        const SizedBox(height: 1),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Pressable(
      onTap: () => onChanged(!value),
      pressedScale: 0.985,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _buildIconCircle(
              Icon(icon, color: iconColor, size: 20),
              iconBackground,
            ),
            const SizedBox(width: 14),
            Expanded(child: _buildTileText(title, subtitle)),
            const SizedBox(width: 8),
            Switch(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required Widget leading,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required String valueLabel,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.985,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            _buildIconCircle(leading, iconBackground),
            const SizedBox(width: 14),
            Expanded(child: _buildTileText(title, subtitle)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: surfaceMuted,
                borderRadius: BorderRadius.circular(radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueLabel,
                    style: AppText.captionStrong.copyWith(
                      color: textNeutralPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: textDarkTertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom sheet pemilih
  // ---------------------------------------------------------------------------
  void _showLanguagePicker() {
    _showOptionSheet(
      overline: 'Bahasa',
      title: 'Pilih bahasa aplikasi',
      message: 'Teks di aplikasi akan menyesuaikan bahasa pilihanmu.',
      options: [
        _SheetOption(
          leading: Text(
            'ID',
            style: AppText.title.copyWith(color: primaryColor700),
          ),
          title: 'Bahasa Indonesia',
          subtitle: 'Bahasa utama aplikasi',
          selected: _selectedLanguage == 'ID',
          onSelected: () => _setLanguage('ID'),
        ),
        _SheetOption(
          leading: Text(
            'EN',
            style: AppText.title.copyWith(color: primaryColor700),
          ),
          title: 'English',
          subtitle: 'Bahasa Inggris',
          selected: _selectedLanguage == 'EN',
          onSelected: () => _setLanguage('EN'),
        ),
      ],
    );
  }

  void _showThemePicker() {
    _showOptionSheet(
      overline: 'Tampilan',
      title: 'Pilih tema aplikasi',
      message: 'Sesuaikan tampilan agar nyaman dilihat kapan saja.',
      options: [
        _SheetOption(
          leading: _sheetSvg('assets/svg/sun.svg'),
          title: 'Mode Terang',
          subtitle: 'Tampilan cerah untuk siang hari',
          selected: !_isDarkMode,
          onSelected: () => _setDarkMode(false),
        ),
        _SheetOption(
          leading: _sheetSvg('assets/svg/moon.svg'),
          title: 'Mode Gelap',
          subtitle: 'Nyaman di mata saat malam hari',
          selected: _isDarkMode,
          onSelected: () => _setDarkMode(true),
        ),
      ],
    );
  }

  Widget _sheetSvg(String asset) {
    return SvgPicture.asset(
      asset,
      width: 19,
      height: 19,
      colorFilter: const ColorFilter.mode(primaryColor700, BlendMode.srcIn),
    );
  }

  void _showOptionSheet({
    required String overline,
    required String title,
    required String message,
    required List<_SheetOption> options,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: inkSoft.withValues(alpha: 0.45),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: 12),
                Text(overline.toUpperCase(), style: AppText.overline),
                const SizedBox(height: 6),
                Text(title, style: AppText.h2),
                const SizedBox(height: 4),
                Text(message, style: AppText.body.copyWith(fontSize: 13)),
                const SizedBox(height: 20),
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _SheetOptionTile(
                    option: options[i],
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      options[i].onSelected();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Komponen privat bottom sheet
// -----------------------------------------------------------------------------
class _SheetOption {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onSelected;

  const _SheetOption({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelected,
  });
}

class _SheetOptionTile extends StatelessWidget {
  final _SheetOption option;
  final VoidCallback onTap;

  const _SheetOptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = option.selected;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primaryColor50 : surfaceMuted,
          borderRadius: BorderRadius.circular(radiusLg),
          border: Border.all(
            color: selected ? primaryColor : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: option.leading,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(option.title, style: AppText.title),
                  const SizedBox(height: 1),
                  Text(option.subtitle, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primaryColor : borderNeutral,
                  width: 2,
                ),
              ),
              child: selected
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
    );
  }
}
