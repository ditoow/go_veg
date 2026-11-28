import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetables_app/config/user_preference.dart';
import 'package:vegetables_app/providers/auth_provider.dart';
import 'package:vegetables_app/providers/cart_provider.dart';
import 'package:vegetables_app/providers/favorite_provider.dart';
import 'package:vegetables_app/providers/order_provider.dart';
import 'package:vegetables_app/providers/payment_provider.dart';
import 'package:vegetables_app/providers/product_detail_provider.dart';
import 'package:vegetables_app/providers/product_provider.dart';

import '../data/api/api_service.dart';
import '../firebase/firebase_analytics_helper.dart';
import '../firebase/firebase_email_auth.dart';
import '../firebase/firebase_google.auth.dart';
import '../repository/vegetable_repository.dart';
import 'constant.dart';

/// Global [GetIt.instance].
final GetIt serviceLocator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerSingleton<UserPreference>(UserPreference(prefs));

  serviceLocator.registerFactory<Dio>(() {
    final dio = Dio();
    kDebugMode ? dio.interceptors.add(AwesomeDioInterceptor()) : null;
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: timeOutDuration),
      receiveTimeout: const Duration(seconds: timeOutDuration),
      persistentConnection: false,
      headers: {
        'Content-Type': 'application/json',
        // 'Accept': 'application/json',
        // "x-api-key": Env.apiKey,
        // 'Authorization':
        //     'Bearer ${serviceLocator.get<UserPreference>().getToken()}',
      },
    );

    return dio;
  });

  serviceLocator.registerFactory<ApiService>(
    () => ApiService(serviceLocator.get<Dio>(), baseUrl: baseApi),
  );

  serviceLocator.registerFactory<VegetableRepository>(
    () => VegetableRepository(serviceLocator.get<ApiService>()),
  );

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  serviceLocator.registerSingleton<PackageInfo>(packageInfo);

  // Firebase Services
  serviceLocator.registerLazySingleton<FirebaseAnalyticsHelper>(
    () => FirebaseAnalyticsHelper(),
  );
  serviceLocator.registerLazySingleton<FirebaseEmailAuth>(
    () => FirebaseEmailAuth(),
  );
  serviceLocator.registerLazySingleton<FirebaseGoogleAuth>(
    () => FirebaseGoogleAuth(),
  );
  serviceLocator.registerLazySingleton<AuthProvider>(
    () => AuthProvider(serviceLocator.get<UserPreference>()),
  );
  serviceLocator.registerFactory<ProductProvider>(
    () => ProductProvider(serviceLocator.get<VegetableRepository>()),
  );
  serviceLocator.registerFactory<ProductDetailProvider>(
    () => ProductDetailProvider(serviceLocator.get<VegetableRepository>()),
  );
  serviceLocator.registerLazySingleton<CartProvider>(
    () => CartProvider(serviceLocator.get<SharedPreferences>()),
  );
  serviceLocator.registerLazySingleton<FavoriteProvider>(
    () => FavoriteProvider(serviceLocator.get<SharedPreferences>()),
  );
  serviceLocator.registerLazySingleton<OrderProvider>(() => OrderProvider());
  serviceLocator.registerFactory<PaymentProvider>(
    () => PaymentProvider(
      serviceLocator.get<Dio>(),
      backendBaseUrl: be2BaseUrl,
    ),
  );
}
