import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'q': 'Bagaimana cara memastikan sayuran tetap segar saat tiba?',
      'a':
          'Semua sayuran kami dipanen subuh hari langsung dari petani mitra di Bandungan dan Ambarawa. Selama pengantaran, sayur dikemas higienis dalam box berpendingin dengan ice pack khusus.',
    },
    {
      'q': 'Berapa lama estimasi pengiriman pesanan?',
      'a':
          'Untuk pengiriman reguler hari yang sama (Same Day), pesanan diantar dalam waktu 15 - 45 menit tergantung jarak dari Hub GoVeg terdekat ke lokasimu.',
    },
    {
      'q': 'Bagaimana jika sayuran yang diterima layu atau rusak?',
      'a':
          'GoVeg memberikan Garansi Kesegaran 100%. Cukup kirimkan foto sayuran yang kurang segar lewat menu Pesanan Saya, dan kami akan langsung mengganti produk baru atau mengembalikan dana secara instan.',
    },
    {
      'q': 'Apakah sayuran berlabel organik benar-benar bebas kimia?',
      'a':
          'Betul. Sayuran bertanda 100% Organik dibudidayakan secara alami dengan pupuk kompos nabati tanpa pestisida sintetis dan telah melalui uji residu ketat.',
    },
    {
      'q': 'Metode pembayaran apa saja yang tersedia?',
      'a':
          'Kami menerima QRIS (GoPay, OVO, DANA, ShopeePay), Transfer Virtual Account (BCA, Mandiri, BRI, BNI), dan pembayaran tunai saat barang sampai (COD).',
    },
    {
      'q': 'Kapan waktu terbaik untuk melakukan pemesanan sayur?',
      'a':
          'Kami menyarankan memesan antara pukul 06.00 - 10.00 WIB untuk mendapatkan varian sayur daun dan rempah yang baru saja selesai dipanen dari kebun.',
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFaqs {
    if (_searchQuery.trim().isEmpty) return _faqs;
    final query = _searchQuery.toLowerCase();
    return _faqs.where((f) {
      return (f['q']?.toLowerCase().contains(query) ?? false) ||
          (f['a']?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _searchQuery = '');
  }

  void _contactCustomerCare() {
    showAppSnackBar(
      context,
      'Menghubungkan ke WhatsApp Customer Care GoVeg...',
      icon: Icons.headset_mic_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          child: Column(
            children: [
              const AppPageHeader(
                title: 'Pusat Bantuan & FAQ',
                subtitle: 'Jawaban cepat untuk pertanyaanmu',
              ),

              // Pencarian
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Cari pertanyaan...',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  suffix: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                ),
              ),

              // Daftar FAQ
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    if (faqs.isEmpty)
                      const EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'Pertanyaan tidak ditemukan',
                        message:
                            'Coba kata kunci lain atau hubungi tim customer care kami.',
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _searchQuery.trim().isEmpty
                                    ? 'PERTANYAAN UMUM'
                                    : 'HASIL PENCARIAN',
                                style: AppText.overline,
                              ),
                            ),
                            Text(
                              '${faqs.length} topik',
                              style: AppText.captionStrong.copyWith(
                                color: textDarkTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (int i = 0; i < faqs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _FaqCard(
                          key: ValueKey(faqs[i]['q']),
                          index: i + 1,
                          question: faqs[i]['q'] ?? '',
                          answer: faqs[i]['a'] ?? '',
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    _buildCsBanner(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCsBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: AppShadows.glow(forestDeep, strength: 0.22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -26,
            right: 18,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.headset_mic_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Masih butuh bantuan?',
                            style: AppText.h3.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tim customer care GoVeg siap membantu 24/7.',
                            style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Pressable(
                  onTap: _contactCustomerCare,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radiusPill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: forestDeep,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chat CS',
                          style: AppText.button.copyWith(
                            color: forestDeep,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Kartu FAQ yang bisa dibuka-tutup
// -----------------------------------------------------------------------------
class _FaqCard extends StatefulWidget {
  final int index;
  final String question;
  final String answer;

  const _FaqCard({
    super.key,
    required this.index,
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  static const _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: _expanded ? primaryColor100 : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: () => setState(() => _expanded = !_expanded),
            pressedScale: 0.985,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: _duration,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _expanded ? primaryColor : primaryColor50,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.index.toString().padLeft(2, '0'),
                      style: AppText.captionStrong.copyWith(
                        color: _expanded ? Colors.white : primaryColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.question,
                        style: AppText.title.copyWith(height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: _duration,
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _expanded ? primaryColor : textDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: _duration,
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, thickness: 1, color: hairline),
                  const SizedBox(height: 12),
                  Text(
                    widget.answer,
                    style: AppText.body.copyWith(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
