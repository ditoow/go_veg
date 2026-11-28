import 'package:flutter/foundation.dart';
import 'package:vegetables_app/config/constant.dart';
import 'package:vegetables_app/model/vegetable_model/category_model.dart';
import 'package:vegetables_app/model/vegetable_model/local_vegetables.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/repository/vegetable_repository.dart';
import 'package:vegetables_app/utility/resource/data_state.dart';

class ProductProvider extends ChangeNotifier {
  final VegetableRepository _vegetableRepository;

  ProductProvider(this._vegetableRepository);

  bool _isLoading = false;
  String? _errorMessage;
  List<VegetableModel> _vegetables = const [];
  bool _hasLoadedOnce = false;

  bool _isCategoriesLoading = false;
  String? _categoriesError;
  List<String> _categories = vegetableCategories;
  List<CategoryModel> _categoryModels = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VegetableModel> get vegetables => _vegetables;
  bool get hasLoadedOnce => _hasLoadedOnce;

  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get categoriesError => _categoriesError;
  List<String> get categories => _categories;
  List<CategoryModel> get categoryModels => _categoryModels;

  Future<void> getVegetables({String? kategori, String? cari}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryKategori = (kategori == null || kategori == 'Semua')
        ? null
        : kategori;

    final localItems = LocalVegetables.filter(
      kategori: queryKategori,
      cari: cari,
    );

    final result = await _vegetableRepository.getVegetables(
      kategori: queryKategori,
      cari: cari,
    );

    if (result is DataStateSuccess) {
      final list = result.data?.data ?? [];
      final localNames = localItems
          .map((item) => item.nama.toLowerCase())
          .toSet();
      final apiItems = list
          .where((item) => !localNames.contains(item.nama.toLowerCase()))
          .toList();
      _vegetables = [...localItems, ...apiItems];
      _errorMessage = null;
      _hasLoadedOnce = true;
    } else if (result is DataStateError) {
      if (localItems.isNotEmpty) {
        _vegetables = localItems;
        _errorMessage = null;
      } else {
        _errorMessage =
            result.exception?.message ?? 'Gagal memuat data sayuran.';
      }
      _hasLoadedOnce = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getCategories() async {
    _isCategoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    final result = await _vegetableRepository.getCategories();

    if (result is DataStateSuccess) {
      final list = result.data?.data ?? [];
      _categories = ['Semua', ...list.map((c) => c.nama)];
      _categoryModels = list;
      _categoriesError = null;
    } else if (result is DataStateError) {
      _categories = vegetableCategories;
      _categoriesError =
          result.exception?.message ?? 'Gagal memuat kategori dari server.';
    }

    _isCategoriesLoading = false;
    notifyListeners();
  }
}
