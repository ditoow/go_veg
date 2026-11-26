import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vegetables_app/config/service_locator.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_cubit.dart';
import 'package:vegetables_app/feature/detail/cubit/vegetable_detail_cubit.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_cubit.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_state.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_detail_model.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/ui/app_back_button.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class DetailScreen extends StatelessWidget {
  final VegetableModel vegetable;

  const DetailScreen({super.key, required this.vegetable});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VegetableDetailCubit>(
      create: (context) =>
          serviceLocator.get<VegetableDetailCubit>()..getDetail(vegetable.id),
      child: _DetailView(vegetable: vegetable),
    );
  }
}

class _DetailView extends StatefulWidget {
  final VegetableModel vegetable;

  const _DetailView({required this.vegetable});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  int _quantity = 1;
  int _selectedInfoTab = 0; // 0: Manfaat, 1: Tips Simpan, 2: Deskripsi

  static const List<String> _infoTabs = ['Manfaat', 'Tips Simpan', 'Deskripsi'];

  /// Radius bawah foto — sama dengan akhir animasi Hero dari kartu Home.
  static const BorderRadius _heroRadius = BorderRadius.vertical(
    bottom: Radius.circular(36),
  );

  /// Seberapa jauh sheet konten menimpa foto setelah transisi selesai.
  static const double _sheetOverlap = 30;

  /// Tinggi baris tombol atas (padding 8 + tombol 44 + padding 8).
  static const double _topBarHeight = 60;

  /// Tinggi bottom bar (padding 8 + tombol 52 + padding 8).
  static const double _bottomBarHeight = 68;

  final ScrollController _scrollController = ScrollController();

  /// Sheet baru "naik" menimpa foto setelah Hero mendarat, supaya
  /// pendaratan animasi Hero tetap mulus (tidak tertutup tiba-tiba).
  Animation<double>? _routeAnimation;
  bool _sheetSettled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation == _routeAnimation) return;

    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _routeAnimation = animation;

    if (animation == null || animation.status == AnimationStatus.completed) {
      _sheetSettled = true;
    } else {
      animation.addStatusListener(_handleRouteStatus);
    }
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_sheetSettled && mounted) {
      setState(() => _sheetSettled = true);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _scrollController.dispose();
    super.dispose();
  }

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.vegetable;
    final media = MediaQuery.of(context);
    final double heroHeight = (media.size.height * 0.5).clamp(340.0, 480.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. FOTO PRODUK (parallax saat scroll, melar saat overscroll)
          _buildHeroImage(item.gambar, heroHeight),

          // 2. KONTEN — sheet putih yang menimpa foto
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _sheetSettled ? 1 : 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) =>
                      SizedBox(height: heroHeight - _sheetOverlap * t),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildContentSheet(item, media.padding.bottom),
              ),
            ],
          ),

          // 3. FLOATING TOP BAR (kembali & favorit)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingTopBar(heroHeight, media.padding.top),
          ),

          // 4. FLOATING BOTTOM BAR (jumlah + tambah ke keranjang)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + media.padding.bottom,
            child: _buildBottomActionBar(item),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO IMAGE
  // ---------------------------------------------------------------------------
  Widget _buildHeroImage(String imageUrl, double heroHeight) {
    return ListenableBuilder(
      listenable: _scrollController,
      builder: (context, child) {
        final offset = _scrollOffset;
        return Positioned(
          top: offset > 0 ? -offset * 0.4 : 0,
          left: 0,
          right: 0,
          height: heroHeight + (offset < 0 ? -offset : 0),
          child: child!,
        );
      },
      child: Hero(
        tag: imageUrl,
        flightShuttleBuilder: _buildHeroShuttle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VegImage(url: imageUrl, borderRadius: _heroRadius, iconSize: 64),
            const _TopScrim(),
          ],
        ),
      ),
    );
  }

  /// Sama dengan shuttle di kartu Home: radius kartu -> radius bawah 36.
  Widget _buildHeroShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final imageUrl = widget.vegetable.gambar;
    final radiusTween = BorderRadiusTween(
      begin: BorderRadius.circular(radiusLg - 2),
      end: _heroRadius,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        return ClipRRect(
          borderRadius: radiusTween.transform(t) ?? BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VegImage(url: imageUrl, iconSize: 64),
              _TopScrim(opacity: t),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FLOATING TOP BAR — berubah jadi bar putih saat konten di-scroll
  // ---------------------------------------------------------------------------
  Widget _buildFloatingTopBar(double heroHeight, double topInset) {
    return ListenableBuilder(
      listenable: _scrollController,
      builder: (context, _) {
        final sheetTop = heroHeight - _sheetOverlap - _scrollOffset;
        final barBottom = topInset + _topBarHeight;
        final t = ((barBottom + 48 - sheetTop) / 48).clamp(0.0, 1.0);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: t > 0.5 ? AppTheme.darkStatusBar : AppTheme.lightStatusBar,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: t),
              boxShadow: [
                BoxShadow(
                  color: inkSoft.withValues(alpha: 0.06 * t),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const AppBackButton(isFrosted: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: Text(
                      widget.vegetable.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppText.h3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<FavoriteCubit, FavoriteState>(
                  builder: (context, favState) {
                    final isFav = context.read<FavoriteCubit>().isFavorite(
                      widget.vegetable.id,
                    );
                    return AppCircleButton(
                      icon: isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFav ? errorColor : textNeutralPrimary,
                      onTap: () => context
                          .read<FavoriteCubit>()
                          .toggleFavorite(widget.vegetable),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CONTENT SHEET
  // ---------------------------------------------------------------------------
  Widget _buildContentSheet(VegetableModel item, double bottomInset) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        28,
        20,
        _bottomBarHeight + 12 + bottomInset + 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(radius2xl),
        ),
        boxShadow: [
          BoxShadow(
            color: inkSoft.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: BlocBuilder<VegetableDetailCubit, VegetableDetailState>(
        builder: (context, state) {
          final isLoading =
              state is VegetableDetailLoading ||
              state is VegetableDetailInitial;
          final VegetableDetailModel? detail = state is VegetableDetailLoaded
              ? state.detail
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori & asal petani (dinamis dari API)
              _buildBadges(item, detail, isLoading),
              const SizedBox(height: 14),

              // Nama produk
              Text(item.nama, style: AppText.h1),
              const SizedBox(height: 18),

              // Harga & rating
              _buildPriceRow(item.harga),
              const SizedBox(height: 30),

              // Nutrisi (dinamis dari API)
              const SectionHeader(
                overline: 'Per 100 gram',
                title: 'Kandungan Gizi',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),
              isLoading
                  ? _buildSpecGridSkeleton()
                  : _buildSpecGrid(detail?.nutrisi),
              const SizedBox(height: 30),

              if (state is VegetableDetailError) ...[
                _buildErrorNotice(state.message),
                const SizedBox(height: 16),
              ],

              // Tab informasi (Manfaat / Tips Simpan / Deskripsi)
              _buildInfoTabs(),
              const SizedBox(height: 18),
              _buildInfoTabContent(detail, isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadges(
    VegetableModel item,
    VegetableDetailModel? detail,
    bool isLoading,
  ) {
    final asal = detail?.asal ?? 'Petani Lokal';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusPill(label: item.kategori, icon: Icons.eco_rounded),
        if (isLoading)
          _shimmer(_skeletonBox(width: 150, height: 23, radius: radiusPill))
        else
          StatusPill(
            label: 'Panen segar · $asal',
            icon: Icons.nature_people_rounded,
            color: textDarkSecondary,
            background: surfaceMuted,
          ),
      ],
    );
  }

  Widget _buildPriceRow(int price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HARGA',
                style: AppText.overline.copyWith(color: textDarkTertiary),
              ),
              const SizedBox(height: 6),
              Text(
                formatRupiah(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.price.copyWith(
                  fontSize: 30,
                  height: 1.1,
                  letterSpacing: -0.9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          decoration: BoxDecoration(
            color: pastelYellow,
            borderRadius: BorderRadius.circular(radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: warningColor, size: 18),
              const SizedBox(width: 4),
              Text('4.9', style: AppText.title.copyWith(fontSize: 13)),
              Text(
                ' / 5',
                style: AppText.caption.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NUTRISI
  // ---------------------------------------------------------------------------
  Widget _buildSpecGrid(NutrisiModel? nutrisi) {
    final specs = [
      _NutrientCard(
        label: 'Kalori',
        value: nutrisi?.kalori?.replaceAll('/ 100g', '').trim() ?? '23 kcal',
        icon: Icons.local_fire_department_rounded,
        color: secondaryColor600,
        background: pastelOrange,
      ),
      _NutrientCard(
        label: 'Protein',
        value: nutrisi?.protein ?? '2.9g',
        icon: Icons.fitness_center_rounded,
        color: primaryColor,
        background: pastelMint,
      ),
      _NutrientCard(
        label: 'Serat',
        value: nutrisi?.serat ?? '2.2g',
        icon: Icons.grass_rounded,
        color: blue700,
        background: pastelBlue,
      ),
      _NutrientCard(
        label: 'Karbohidrat',
        value: nutrisi?.karbohidrat ?? '3.6g',
        icon: Icons.grain_rounded,
        color: jacarta500,
        background: pastelPurple,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: specs[i]),
        ],
      ],
    );
  }

  Widget _buildSpecGridSkeleton() {
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radiusLg),
                boxShadow: AppShadows.soft,
              ),
              child: _shimmer(
                Column(
                  children: [
                    _skeletonBox(width: 36, height: 36, radius: radiusPill),
                    const SizedBox(height: 12),
                    _skeletonBox(width: 40, height: 12),
                    const SizedBox(height: 6),
                    _skeletonBox(width: 52, height: 9),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: red50,
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: errorColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detail lengkap belum termuat',
                  style: AppText.captionStrong.copyWith(
                    color: textNeutralPrimary,
                  ),
                ),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () => context.read<VegetableDetailCubit>().getDetail(
              widget.vegetable.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'Coba lagi',
                style: AppText.captionStrong.copyWith(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TAB INFORMASI — segmented control dengan indikator geser
  // ---------------------------------------------------------------------------
  Widget _buildInfoTabs() {
    final count = _infoTabs.length;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + 2 * _selectedInfoTab / (count - 1), 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radiusPill),
                  boxShadow: AppShadows.soft,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 0; i < count; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedInfoTab = i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: _selectedInfoTab == i
                            ? AppText.title.copyWith(fontSize: 13)
                            : AppText.captionStrong.copyWith(
                                fontSize: 13,
                                color: textDarkTertiary,
                              ),
                        child: Text(
                          _infoTabs[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Isi konten tab dinamis dari API
  Widget _buildInfoTabContent(VegetableDetailModel? detail, bool isLoading) {
    final Widget content;

    if (isLoading) {
      content = _shimmer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 10),
            _skeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 10),
            _skeletonBox(width: 200, height: 12),
          ],
        ),
      );
    } else if (_selectedInfoTab == 0) {
      final manfaatList = detail?.manfaat;
      if (manfaatList != null && manfaatList.isNotEmpty) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in manfaatList)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(
                        color: primaryColor50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: primaryColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(m, style: AppText.body)),
                  ],
                ),
              ),
          ],
        );
      } else {
        content = Text(
          detail?.deskripsi ?? widget.vegetable.deskripsi,
          style: AppText.body,
        );
      }
    } else if (_selectedInfoTab == 1) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgApp,
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.kitchen_rounded,
                color: primaryColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                detail?.tipsPenyimpanan ??
                    'Simpan dalam wadah kedap udara beralas tisu di lemari es untuk menjaga kerenyahannya.',
                style: AppText.body,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Text(
        detail?.deskripsi ?? widget.vegetable.deskripsi,
        style: AppText.body,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topLeft,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey('$_selectedInfoTab-$isLoading'),
        child: content,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. FLOATING BOTTOM BAR (jumlah + tombol keranjang)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(VegetableModel item) {
    final int subtotal = item.harga * _quantity;

    return Container(
      height: _bottomBarHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          QuantityStepper(
            value: _quantity,
            onDecrement: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
            onIncrement: () => setState(() => _quantity++),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: formatRupiah(subtotal),
              icon: Icons.add_shopping_cart_rounded,
              height: 52,
              onPressed: () {
                context.read<CartCubit>().addItem(item, quantity: _quantity);
                showAppSnackBar(
                  context,
                  '$_quantity × ${item.nama} (${formatRupiah(subtotal)}) masuk keranjang',
                  icon: Icons.shopping_basket_rounded,
                  aboveNavBar: true,
                );

                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton helpers
  // ---------------------------------------------------------------------------
  Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor: surfaceMuted,
      highlightColor: Colors.white,
      child: child,
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Gradasi gelap tipis di atas foto agar status bar & tombol tetap kontras.
class _TopScrim extends StatelessWidget {
  final double opacity;

  const _TopScrim({this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.34 * opacity),
                Colors.black.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu mini nutrisi.
class _NutrientCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _NutrientCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.title.copyWith(fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppText.caption.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
