import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetables_app/model/vegetable_model/vegetable_model.dart';
import 'package:vegetables_app/providers/cart_provider.dart';
import 'package:vegetables_app/providers/favorite_provider.dart';
import 'package:vegetables_app/providers/order_provider.dart';
import 'package:vegetables_app/providers/payment_provider.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/api/dev/orders')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Local test order created',
          'data': {'id': 'ORD-MOCK-1', 'gross_amount': 16000, 'status': 'PENDING'},
        }),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.endsWith('/api/payments/create')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Payment initiated',
          'data': {
            'order_id': 'ORD-MOCK-1',
            'snap_token': 'snap-token-123',
            'redirect_url': 'https://app.sandbox.midtrans.com/snap/v4/redirection/snap-token-123',
            'payment_status': 'PENDING',
            'expires_at': '2026-11-27T02:51:00.000Z',
          },
        }),
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.endsWith('/api/payments/ORD-MOCK-1/status')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'message': 'Payment status retrieved',
          'data': {
            'order_id': 'ORD-MOCK-1',
            'order_status': 'PAID',
            'payment_status': 'PAID',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{"success":false,"message":"Not found"}', 404);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleVeg = VegetableModel(
    id: 1,
    nama: 'Bayam Hijau',
    kategori: 'Sayuran Daun',
    harga: 8000,
    gambar: 'assets/images/kangkung.jpg',
    deskripsi: 'Bayam segar',
  );

  test('CartProvider add, update, persist, and clear flow', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final cart = CartProvider(prefs);
    cart.addItem(sampleVeg, quantity: 2);
    expect(cart.items.length, 1);
    expect(cart.totalItems, 2);
    expect(cart.totalPrice, 16000);

    cart.updateQuantity(1, 3);
    expect(cart.totalItems, 3);
    expect(cart.totalPrice, 24000);

    // Reload into a fresh instance to verify persistence
    final reloaded = CartProvider(prefs)..loadCart();
    expect(reloaded.items.length, 1);
    expect(reloaded.totalItems, 3);

    cart.clearCart();
    expect(cart.items, isEmpty);
    expect(cart.totalPrice, 0);
  });

  test('FavoriteProvider toggles and persists favorites', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fav = FavoriteProvider(prefs);
    expect(fav.isFavorite(1), isFalse);

    fav.toggleFavorite(sampleVeg);
    expect(fav.isFavorite(1), isTrue);
    expect(fav.favorites.length, 1);

    final reloaded = FavoriteProvider(prefs)..loadFavorites();
    expect(reloaded.isFavorite(1), isTrue);

    fav.toggleFavorite(sampleVeg);
    expect(fav.isFavorite(1), isFalse);
  });

  test('OrderProvider tracks loading, orders, and errors', () {
    final orders = OrderProvider();
    expect(orders.orders, isEmpty);
    orders.setLoading(true);
    expect(orders.isLoading, isTrue);
    orders.setOrders([
      {'id': 'ORD-1', 'status': 'PENDING'},
    ]);
    expect(orders.orders.length, 1);
    orders.setError('Network error');
    expect(orders.errorMessage, 'Network error');
  });

  test('PaymentProvider initiates checkout and checks payment status', () async {
    final dio = Dio()..httpClientAdapter = _MockHttpClientAdapter();
    final payment = PaymentProvider(dio, backendBaseUrl: 'http://localhost:8080');

    final initiated = await payment.initiateCheckoutPayment(grossAmount: 16000);
    expect(initiated, isTrue);
    expect(payment.orderId, 'ORD-MOCK-1');
    expect(payment.snapToken, 'snap-token-123');
    expect(payment.redirectUrl, contains('snap-token-123'));
    expect(payment.paymentStatus, 'PENDING');
    expect(payment.expiresAt, isNotNull);

    final status = await payment.checkPaymentStatus('ORD-MOCK-1', sync: true);
    expect(status, 'PAID');
    expect(payment.paymentStatus, 'PAID');
  });
}
