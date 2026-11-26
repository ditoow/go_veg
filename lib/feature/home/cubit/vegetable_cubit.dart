import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vegetables_app/model/vegetable_model/local_vegetables.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/repository/vegetable_repository.dart';
import 'package:vegetables_app/utility/resource/data_state.dart';

part 'vegetable_state.dart';

class VegetableCubit extends Cubit<VegetableState> {
  final VegetableRepository _vegetableRepository;

  VegetableCubit(this._vegetableRepository) : super(VegetableInitial());

  Future<void> getVegetables({String? kategori, String? cari}) async {
    emit(VegetableLoading());
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
      emit(VegetableLoaded([...localItems, ...apiItems]));
    } else if (result is DataStateError) {
      if (localItems.isNotEmpty) {
        emit(VegetableLoaded(localItems));
        return;
      }
      final errorMessage =
          result.exception?.message ?? 'Gagal memuat data sayuran.';
      emit(VegetableError(errorMessage));
    }
  }
}
