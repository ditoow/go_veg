import 'package:flutter/foundation.dart';
import 'package:vegetables_app/model/vegetable_model/local_vegetables.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_detail_model.dart';
import 'package:vegetables_app/repository/vegetable_repository.dart';
import 'package:vegetables_app/utility/resource/data_state.dart';

class ProductDetailProvider extends ChangeNotifier {
  final VegetableRepository _vegetableRepository;

  ProductDetailProvider(this._vegetableRepository);

  bool _isLoading = false;
  String? _errorMessage;
  VegetableDetailModel? _detail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VegetableDetailModel? get detail => _detail;

  Future<void> getDetail(int id) async {
    final localDetail = LocalVegetables.detailFor(id);
    if (localDetail != null) {
      _detail = localDetail;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _vegetableRepository.getVegetableDetail(id: id);

    if (result is DataStateSuccess && result.data?.data != null) {
      _detail = result.data!.data!;
      _errorMessage = null;
    } else if (result is DataStateError) {
      _errorMessage =
          result.exception?.message ?? 'Gagal memuat detail sayuran.';
    }

    _isLoading = false;
    notifyListeners();
  }
}
