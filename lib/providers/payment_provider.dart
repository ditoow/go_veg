import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Provider status & sinkronisasi pembayaran Midtrans (kontrak BE-2).
class PaymentProvider extends ChangeNotifier {
  final Dio _dio;
  final String _backendBaseUrl;

  PaymentProvider(this._dio, {String backendBaseUrl = 'http://localhost:8080'})
      : _backendBaseUrl = backendBaseUrl;

  bool _isLoading = false;
  String? _errorMessage;
  String? _orderId;
  String? _snapToken;
  String? _redirectUrl;
  String _paymentStatus = 'PENDING';
  DateTime? _expiresAt;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get orderId => _orderId;
  String? get snapToken => _snapToken;
  String? get redirectUrl => _redirectUrl;
  String get paymentStatus => _paymentStatus;
  DateTime? get expiresAt => _expiresAt;

  /// Helper sementara untuk membuat order lokal di mode `STORAGE_MODE=local`
  /// sebelum endpoint/tabel order dari BE-1 tersedia.
  Future<String?> createDevOrder({
    required int grossAmount,
    String? userId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_backendBaseUrl/api/dev/orders',
        data: {
          'gross_amount': grossAmount,
          'user_id': ?userId,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final createdId = data?['id'] as String?;
      if (createdId != null) {
        _orderId = createdId;
      }
      return createdId;
    } on DioException catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal membuat order lokal di backend BE-2.',
      );
      return null;
    }
  }

  /// Membuat order lokal (jika [orderId] belum ada) lalu menginisiasi Snap Midtrans.
  Future<bool> initiateCheckoutPayment({
    String? orderId,
    required int grossAmount,
    String? userId,
    Map<String, dynamic>? customerDetails,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var targetOrderId = orderId;
      if (targetOrderId == null || targetOrderId.isEmpty) {
        targetOrderId = await createDevOrder(
          grossAmount: grossAmount,
          userId: userId,
        );
        if (targetOrderId == null) {
          return false;
        }
      }

      return await _requestSnapToken(
        orderId: targetOrderId,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> initiatePayment({
    required String orderId,
    Map<String, dynamic>? customerDetails,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _requestSnapToken(
        orderId: orderId,
        customerDetails: customerDetails,
        itemDetails: itemDetails,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _requestSnapToken({
    required String orderId,
    Map<String, dynamic>? customerDetails,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_backendBaseUrl/api/payments/create',
        data: {
          'order_id': orderId,
          'customer_details': ?customerDetails,
          'item_details': ?itemDetails,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      _orderId = data?['order_id'] as String? ?? orderId;
      _snapToken = data?['snap_token'] as String?;
      _redirectUrl = data?['redirect_url'] as String?;
      _paymentStatus = data?['payment_status'] as String? ?? 'PENDING';
      final rawExpires = data?['expires_at'] as String?;
      _expiresAt = rawExpires != null ? DateTime.tryParse(rawExpires) : null;
      return _redirectUrl != null && _redirectUrl!.isNotEmpty;
    } on DioException catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal menginisiasi pembayaran Midtrans.',
      );
      return false;
    }
  }

  Future<String?> checkPaymentStatus(String orderId, {bool sync = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_backendBaseUrl/api/payments/$orderId/status',
        queryParameters: sync ? {'sync': 'true'} : null,
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      _orderId = data?['order_id'] as String? ?? orderId;
      _paymentStatus = data?['payment_status'] as String? ?? _paymentStatus;
      _snapToken = data?['snap_token'] as String? ?? _snapToken;
      _redirectUrl = data?['redirect_url'] as String? ?? _redirectUrl;
      final rawExpires = data?['expires_at'] as String?;
      if (rawExpires != null) {
        _expiresAt = DateTime.tryParse(rawExpires) ?? _expiresAt;
      }
      return _paymentStatus;
    } on DioException catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal mengecek status pembayaran.',
      );
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? fallback;
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _orderId = null;
    _snapToken = null;
    _redirectUrl = null;
    _paymentStatus = 'PENDING';
    _expiresAt = null;
    notifyListeners();
  }
}
