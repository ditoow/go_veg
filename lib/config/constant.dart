import 'package:flutter/foundation.dart';

import 'env/env.dart';

/// App Config
const String appName = "Vegetables App";
const String appVersion = "1.0.0";

/// Network Config
const String baseUrl = Env.baseUrl;
const String baseApi = "$baseUrl/api";
const int timeOutDuration = 60;

/// Base URL untuk service BE-2 (Midtrans & Status Sync).
/// Bisa di-override saat build/run via `--dart-define=BE2_BASE_URL=https://...`
String get be2BaseUrl {
  const configured = String.fromEnvironment('BE2_BASE_URL');
  if (configured.isNotEmpty) return configured;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// Supabase Config (diisi di `.env` dan dibaca via `--dart-define-from-file=.env`)
const String defaultSupabaseUrl = 'https://tatcjwgbswpclkarnzwh.supabase.co';
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: defaultSupabaseUrl,
);
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty &&
    supabaseAnonKey.isNotEmpty &&
    !supabaseAnonKey.contains('ISI_ANON_KEY');

/// Firebase Config
const String firebaseSecondaryApp = "secondary";

/// Image Config
const double imageMaxHeight = 720;
const double imageMaxWidth = 720;

/// UI Enums
enum SnackBarPosition { top, bottom }

enum DatePickerType { day, range }

/// Vegetable Categories
const List<String> vegetableCategories = [
  'Semua',
  'Sayuran Daun',
  'Sayuran Buah',
  'Sayuran Umbi',
  'Sayuran Polong',
];
