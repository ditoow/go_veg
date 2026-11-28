import 'package:flutter/foundation.dart';

/// Provider riwayat pesanan sesuai kontrak pembagian proyek (FE-2 / BE-1).
/// Siap disambungkan ke tabel `orders` Supabase setelah BE-1 push skema DB.
class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _orders = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  void setOrders(List<Map<String, dynamic>> orders) {
    _orders = orders;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
