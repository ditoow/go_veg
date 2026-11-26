import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vegetables_app/config/service_locator.dart';
import 'package:vegetables_app/config/user_preference.dart';
import 'package:vegetables_app/feature/login/login_screen.dart';
import 'package:vegetables_app/feature/main_navigation/main_navigation.dart';
import 'package:vegetables_app/firebase/firebase_analytics_helper.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with TickerProviderStateMixin {
  static const int _sessionExpiryDays = 7;

  /// Ikon status bar & navigation bar terang di atas latar hijau hutan.
  static final SystemUiOverlayStyle _overlayStyle = AppTheme.lightStatusBar
      .copyWith(
        systemNavigationBarColor: forestDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  // Animation Controllers
  late final AnimationController _introController;
  late final AnimationController _ambientController;
  late final AnimationController _loaderController;

  // Animations
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    // Intro berurutan: logo → nama & tagline → loader (total ±1,2 detik)
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _loaderFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    // Gerak ambient yang sangat halus (cahaya logo "bernapas", ornamen melayang)
    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);

    // Loader garis tipis yang bergeser
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();

    _introController.forward();

    _handleAuthCheck();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthCheck() async {
    // Delay estetis splash screen agar transisi mulus
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // 1. Jika belum pernah login sama sekali
    if (user == null) {
      _navigateToLogin();
      return;
    }

    // 2. Jika ada user, periksa masa berlaku sesi (Session Expiry)
    final userPref = serviceLocator.get<UserPreference>();
    final lastLogin = userPref.getLastLoginTime();
    final now = DateTime.now();

    bool isExpired = false;
    if (lastLogin != null) {
      final difference = now.difference(lastLogin);
      if (difference.inDays >= _sessionExpiryDays) {
        isExpired = true;
      }
    }

    // 3. Sesi Kadaluarsa (Session Timeout >= 7 Hari)
    if (isExpired) {
      serviceLocator.get<FirebaseAnalyticsHelper>().recordLog(
        "User session expired after $_sessionExpiryDays days.",
      );

      // Auto sign-out demi keamanan
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      await userPref.clearData();

      if (!mounted) return;
      _navigateToLogin(
        expiredMessage:
            "Sesi login Anda telah berakhir ($_sessionExpiryDays hari). Silakan masuk kembali.",
      );
      return;
    }

    // 4. Sesi Masih Valid: Perbarui waktu login terakhir & rekam ke analytics
    await userPref.setLastLoginTime(now);
    await serviceLocator.get<FirebaseAnalyticsHelper>().setUserId(user.uid);

    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToLogin({String? expiredMessage}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoginScreen(sessionExpiredMessage: expiredMessage),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: forestDeep,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.forest),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Ornamen dekoratif ──────────────────────────────────────
              _buildDecorations(),

              // ── Konten utama ───────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    _buildLogo(),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: _buildBrand(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(opacity: _loaderFade, child: _buildLoader()),
                    const Spacer(flex: 6),
                    FadeTransition(opacity: _loaderFade, child: _buildFooter()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────

  Widget _buildDecorations() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ambientController.value);

        return Stack(
          children: [
            Positioned(
              top: -110 + (t * 12),
              right: -80,
              child: _decorCircle(300, 0.06),
            ),
            Positioned(top: 150, left: -60, child: _decorRing(150, 0.07)),
            Positioned(
              bottom: -90 - (t * 10),
              left: -70,
              child: _decorCircle(240, 0.05),
            ),
            Positioned(
              bottom: 70,
              right: -40,
              child: Transform.rotate(
                angle: -0.5 + (t * 0.05),
                child: Icon(
                  Icons.eco_rounded,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 90,
              right: 44,
              child: Transform.rotate(
                angle: 2.4 - (t * 0.08),
                child: Icon(
                  Icons.eco_rounded,
                  size: 46,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _decorRing(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Cahaya lembut yang "bernapas"
              OverflowBox(
                maxWidth: 240,
                maxHeight: 240,
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(
                      _ambientController.value,
                    );
                    return Transform.scale(
                      scale: 0.9 + (t * 0.1),
                      child: Opacity(opacity: 0.75 + (t * 0.25), child: child),
                    );
                  },
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor300.withValues(alpha: 0.34),
                          primaryColor300.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Cincin kaca
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),

              // Inti putih dengan daun
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, primaryColor50],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                    ...AppShadows.glow(primaryColor300, strength: 0.3),
                  ],
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 48,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'VegBox',
            style: AppText.display.copyWith(
              color: Colors.white,
              fontSize: 36,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sayur segar, langsung dari petani',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    const double trackWidth = 88;
    const double segmentWidth = 30;

    return Container(
      width: trackWidth,
      height: 3,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: AnimatedBuilder(
        animation: _loaderController,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_loaderController.value);
          return Transform.translate(
            offset: Offset(-segmentWidth + (trackWidth + segmentWidth) * t, 0),
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: segmentWidth,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusPill),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.spa_rounded,
            size: 14,
            color: primaryColor200.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 8),
          Text(
            'PANEN SEGAR SETIAP HARI',
            style: AppText.overline.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
