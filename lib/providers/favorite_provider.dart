import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';

class FavoriteProvider extends ChangeNotifier {
  static const String _storageKey = 'favorite_vegetables';
  final SharedPreferences _prefs;

  FavoriteProvider(this._prefs);

  List<VegetableModel> _favorites = const [];

  List<VegetableModel> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int id) => _favorites.any((v) => v.id == id);

  void loadFavorites() {
    try {
      final raw = _prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _favorites = decoded
            .map((e) => VegetableModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  void toggleFavorite(VegetableModel item) {
    final current = List<VegetableModel>.from(_favorites);
    final exists = current.any((v) => v.id == item.id);

    if (exists) {
      current.removeWhere((v) => v.id == item.id);
    } else {
      current.add(item);
    }

    _favorites = current;
    notifyListeners();
    _saveToStorage(current);
  }

  Future<void> _saveToStorage(List<VegetableModel> items) async {
    try {
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await _prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
