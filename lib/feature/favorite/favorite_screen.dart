import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vegetables_app/feature/cart/cubit/cart_cubit.dart';
import 'package:vegetables_app/feature/detail/detail_screen.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_cubit.dart';
import 'package:vegetables_app/feature/favorite/cubit/favorite_state.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  /// Sama dengan grid produk di Home agar kartu terasa konsisten.
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 14,
    mainAxisSpacing: 16,
    childAspectRatio: 0.64,
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<FavoriteCubit, FavoriteState>(
            builder: (context, state) {
              final items = state.favorites;

              return Column(
                children: [
                  // 1. HEADER (tombol kembali + judul)
                  AppPageHeader(
                    title: 'Favorit',
                    subtitle: items.isEmpty
                        ? 'Belum ada sayur tersimpan'
                        : '${items.length} sayur tersimpan',
                  ),

                  // 2. GRID FAVORIT / EMPTY STATE
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(bottom: 48 + bottomInset),
                              child: const EmptyStateView(
                                icon: Icons.favorite_border_rounded,
                                title: 'Belum ada favorit',
                                message:
                                    'Simpan sayur segar pilihanmu dengan menekan ikon hati agar mudah dicari lagi.',
                                tone: errorColor,
                                toneBackground: pastelRed,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              32 + bottomInset,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: items.length,
                            gridDelegate: _gridDelegate,
                            itemBuilder: (context, index) =>
                                _buildCard(context, items[index]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, VegetableModel item) {
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
            // Gambar + kategori + tombol hapus favorit
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VegImage(
                    url: item.gambar,
                    borderRadius: BorderRadius.circular(radiusLg - 2),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(
                                  radiusPill,
                                ),
                              ),
                              child: Text(
                                item.kategori,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.captionStrong.copyWith(
                                  color: primaryColor,
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Pressable(
                          pressedScale: 0.85,
                          onTap: () {
                            context.read<FavoriteCubit>().toggleFavorite(item);
                            showAppSnackBar(
                              context,
                              '${item.nama} dihapus dari favorit',
                              type: AppSnackType.info,
                              icon: Icons.heart_broken_rounded,
                            );
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.soft,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 17,
                              color: errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nama, deskripsi, harga + tambah ke keranjang
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
