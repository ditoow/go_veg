import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vegetables_app/config/constant.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_cubit.dart';
import 'package:vegetables_app/feature/detail/detail_screen.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_cubit.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_state.dart';
import 'package:vegetables_app/feature/favorite/favorite_screen.dart';
import 'package:vegetables_app/feature/home/cubit/category_cubit.dart';
import 'package:vegetables_app/feature/home/cubit/vegetable_cubit.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _selectedCategoryName = 'Semua';

  /// true setelah header hijau ter-scroll lewat — status bar jadi terang.
  bool _pastHeader = false;

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 14,
    mainAxisSpacing: 16,
    childAspectRatio: 0.64,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchVegetables({String? search, String? category}) {
    final cat = category ?? _selectedCategoryName;
    final query = (search ?? _searchController.text).trim();

    context.read<VegetableCubit>().getVegetables(
      kategori: (cat == 'Semua') ? null : cat,
      cari: query.isNotEmpty ? query : null,
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _pastHeader ? AppTheme.darkStatusBar : AppTheme.lightStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
                  final past = n.metrics.pixels > 300;
                  if (past != _pastHeader) setState(() => _pastHeader = past);
                }
                return false;
              },
              child: RefreshIndicator(
                color: primaryColor,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  context.read<CategoryCubit>().getCategories();
                  _fetchVegetables();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeroHeader()),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverToBoxAdapter(child: _buildCategorySection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    SliverToBoxAdapter(child: _buildProductSectionHeader()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildProductGrid(),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: navBarClearance),
                    ),
                  ],
                ),
              ),
            ),

            // Latar status bar yang muncul setelah header terlewati
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _pastHeader ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: topInset,
                    color: bgApp.withValues(alpha: 0.97),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO HEADER — hijau hutan dengan lokasi, sapaan, dan pencarian
  // ---------------------------------------------------------------------------
  Widget _buildHeroHeader() {
    final name = _firstName;

    return Container(
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
            top: 70,
            right: -18,
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationRow(),
                  const SizedBox(height: 26),
                  Text(
                    name.isEmpty ? '$_greeting 👋' : '$_greeting, $name 👋',
                    style: AppText.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Sayur segar,\nlangsung dari '),
                        TextSpan(
                          text: 'kebun.',
                          style: AppText.display.copyWith(
                            color: primaryColor200,
                          ),
                        ),
                      ],
                    ),
                    style: AppText.display.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 22),
                  _buildSearchBar(),
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

  Widget _buildLocationRow() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DIKIRIM KE',
                style: AppText.overline.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Jl. Pemuda No. 45, Semarang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, favState) {
            return AppCircleButton(
              icon: Icons.favorite_border_rounded,
              style: CircleButtonStyle.glass,
              badgeCount: favState.favorites.length,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoriteScreen(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchController.text.isNotEmpty;

    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 18, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: primaryColor, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              cursorColor: primaryColor,
              style: AppText.bodyStrong,
              decoration: InputDecoration(
                hintText: 'Cari bayam, tomat, wortel...',
                hintStyle: AppText.body.copyWith(color: textDarkTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (val) => _fetchVegetables(search: val),
              onChanged: (val) {
                if (val.isEmpty) _fetchVegetables(search: '');
                setState(() {});
              },
            ),
          ),
          if (hasText)
            Pressable(
              onTap: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
                setState(() {});
                _fetchVegetables(search: '');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.close_rounded,
                  color: textDarkTertiary,
                  size: 20,
                ),
              ),
            ),
          Pressable(
            onTap: () {
              FocusScope.of(context).unfocus();
              _fetchVegetables();
            },
            pressedScale: 0.9,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KATEGORI
  // ---------------------------------------------------------------------------
  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n == 'semua') return Icons.grid_view_rounded;
    if (n.contains('daun')) return Icons.eco_rounded;
    if (n.contains('buah')) return Icons.local_florist_rounded;
    if (n.contains('umbi')) return Icons.grass_rounded;
    if (n.contains('polong')) return Icons.bubble_chart_rounded;
    if (n.contains('bumbu') || n.contains('rempah')) return Icons.spa_rounded;
    return Icons.local_grocery_store_rounded;
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(overline: 'Jelajahi', title: 'Kategori'),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              List<String> categories = vegetableCategories;
              if (state is CategoryLoaded) {
                categories = state.categories;
              } else if (state is CategoryError) {
                categories = state.fallbackCategories;
              }

              if (_selectedCategoryIndex >= categories.length) {
                _selectedCategoryIndex = 0;
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final catName = categories[index];
                  return _buildCategoryChip(
                    catName,
                    isSelected: _selectedCategoryIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                        _selectedCategoryName = catName;
                      });
                      _fetchVegetables(category: catName);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    String name, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.14)
                    : primaryColor50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(name),
                size: 19,
                color: isSelected ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: AppText.title.copyWith(
                fontSize: 13,
                color: isSelected ? Colors.white : textNeutralPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PRODUK
  // ---------------------------------------------------------------------------
  Widget _buildProductSectionHeader() {
    return BlocBuilder<VegetableCubit, VegetableState>(
      builder: (context, state) {
        final count = state is VegetableLoaded ? state.vegetables.length : null;
        return SectionHeader(
          overline: 'Pilihan hari ini',
          title: _selectedCategoryName == 'Semua'
              ? 'Paling Segar'
              : _selectedCategoryName,
          trailing: count == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '$count produk',
                    style: AppText.captionStrong.copyWith(
                      color: textDarkTertiary,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<VegetableCubit, VegetableState>(
      builder: (context, state) {
        if (state is VegetableLoading) {
          return _buildShimmerLoading();
        } else if (state is VegetableError) {
          return SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.wifi_off_rounded,
              title: 'Gagal memuat sayuran',
              message: state.message,
              tone: errorColor,
              toneBackground: red50,
              actionLabel: 'Coba Lagi',
              actionIcon: Icons.refresh_rounded,
              onAction: () => _fetchVegetables(),
            ),
          );
        } else if (state is VegetableLoaded) {
          final items = state.vegetables;
          if (items.isEmpty) {
            return const SliverToBoxAdapter(
              child: EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'Sayuran tidak ditemukan',
                message:
                    'Coba kata kunci lain atau pilih kategori yang berbeda.',
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.builder(
              gridDelegate: _gridDelegate,
              itemCount: items.length,
              itemBuilder: (context, index) => _buildProductCard(items[index]),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radiusXl),
              boxShadow: AppShadows.soft,
            ),
            child: Shimmer.fromColors(
              baseColor: surfaceMuted,
              highlightColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(radiusLg - 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _skeletonLine(width: 110, height: 13),
                  const SizedBox(height: 8),
                  _skeletonLine(width: 80, height: 10),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _skeletonLine(width: 64, height: 16),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(radiusSm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildProductCard(VegetableModel item) {
    final imageUrl = item.gambar;

    return Pressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(vegetable: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radiusXl),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar + favorit
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: imageUrl,
                    flightShuttleBuilder:
                        (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          final radiusTween = BorderRadiusTween(
                            begin: BorderRadius.circular(radiusLg - 2),
                            end: const BorderRadius.vertical(
                              bottom: Radius.circular(36),
                            ),
                          );
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          );
                          return AnimatedBuilder(
                            animation: curved,
                            builder: (context, child) => ClipRRect(
                              borderRadius:
                                  radiusTween.evaluate(curved) ??
                                  BorderRadius.zero,
                              child: VegImage(url: imageUrl),
                            ),
                          );
                        },
                    child: VegImage(
                      url: imageUrl,
                      borderRadius: BorderRadius.circular(radiusLg - 2),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: BlocBuilder<FavoriteCubit, FavoriteState>(
                      builder: (context, favState) {
                        final isFav = context.read<FavoriteCubit>().isFavorite(
                          item.id,
                        );
                        return Pressable(
                          pressedScale: 0.85,
                          onTap: () => context
                              .read<FavoriteCubit>()
                              .toggleFavorite(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.soft,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 17,
                              color: isFav ? errorColor : textDarkSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Nama, deskripsi, harga
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 2, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.deskripsi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatRupiah(item.harga),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.price.copyWith(
                            fontSize: 15,
                            color: textNeutralPrimary,
                          ),
                        ),
                      ),
                      Pressable(
                        pressedScale: 0.88,
                        onTap: () {
                          context.read<CartCubit>().addItem(item, quantity: 1);
                          showAppSnackBar(
                            context,
                            '${item.nama} masuk keranjang',
                            icon: Icons.shopping_basket_rounded,
                            aboveNavBar: true,
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: forestDeep,
                            borderRadius: BorderRadius.circular(radiusSm),
                            boxShadow: AppShadows.glow(
                              forestDeep,
                              strength: 0.25,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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
