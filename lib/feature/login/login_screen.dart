import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vegetables_app/config/service_locator.dart';
import 'package:vegetables_app/config/user_preference.dart';
import 'package:vegetables_app/feature/main_navigation/main_navigation.dart';
import 'package:vegetables_app/firebase/firebase_analytics_helper.dart';
import 'package:vegetables_app/firebase/firebase_email_auth.dart';
import 'package:vegetables_app/firebase/firebase_google.auth.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/dimension.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class LoginScreen extends StatefulWidget {
  final String? sessionExpiredMessage;
  const LoginScreen({super.key, this.sessionExpiredMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Masuk, 1 = Daftar
  int activeTabIndex = 0;

  // Form State
  bool isPasswordVisible = false;
  bool rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  /// Banner "sesi berakhir" ditampilkan sampai ditutup pengguna.
  late bool _showSessionNotice;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showSessionNotice = widget.sessionExpiredMessage != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (activeTabIndex == index) return;
    FocusScope.of(context).unfocus();
    setState(() => activeTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoginTab = activeTabIndex == 0;
    final double bottomSafe = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatusBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER HIJAU HUTAN + PILL SWITCHER [ Masuk | Daftar ]
              _buildHeroArea(isLoginTab),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomSafe),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. INFO SESI BERAKHIR (opsional)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showSessionNotice
                          ? _buildSessionNotice()
                          : const SizedBox(width: double.infinity),
                    ),

                    const SizedBox(height: 28),

                    // 3. FORM (LOGIN / REGISTER DENGAN ANIMASI HALUS)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: _topAlignedLayout,
                        transitionBuilder: _fadeSlideTransition,
                        child: KeyedSubtree(
                          key: ValueKey<bool>(isLoginTab),
                          child: isLoginTab
                              ? _buildLoginForm()
                              : _buildRegisterForm(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 4. PEMBATAS "ATAU"
                    _buildOrDivider(),

                    const SizedBox(height: 20),

                    // 5. TOMBOL SOCIAL LOGIN (GOOGLE & APPLE)
                    _buildSocialButtons(),

                    const SizedBox(height: 24),

                    // 6. AJAKAN PINDAH TAB
                    _buildSwitchPrompt(isLoginTab),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animasi bersama
  // ---------------------------------------------------------------------------
  static Widget _topAlignedLayout(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [...previousChildren, ?currentChild],
    );
  }

  static Widget _fadeSlideTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeroArea(bool isLoginTab) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: _buildHeader(isLoginTab),
        ),
        // Pill switcher "melayang" di batas header & konten
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _buildPillSwitcher(isLoginTab),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isLoginTab) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.forest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ornamen lingkaran & daun (dekoratif)
          Positioned(top: -70, right: -50, child: _decorCircle(220, 0.06)),
          Positioned(bottom: -60, left: -40, child: _decorCircle(160, 0.05)),
          Positioned(
            top: 64,
            right: -22,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(
                Icons.eco_rounded,
                size: 160,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandRow(),
                  const SizedBox(height: 34),
                  _buildHeadline(isLoginTab),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildBrandRow() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GoVeg',
              style: AppText.h3.copyWith(
                color: Colors.white,
                fontSize: 18,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'SAYUR SEGAR HARIAN',
              style: AppText.overline.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9.5,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Judul & subtitle dinamis dengan fade + slide halus
  Widget _buildHeadline(bool isLoginTab) {
    final accent = AppText.display.copyWith(color: primaryColor200);

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: _topAlignedLayout,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey<bool>(isLoginTab),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoginTab ? 'MASUK KE AKUN' : 'DAFTAR AKUN BARU',
              style: AppText.overline.copyWith(color: primaryColor200),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: isLoginTab
                    ? [
                        const TextSpan(text: 'Selamat datang\n'),
                        TextSpan(text: 'kembali.', style: accent),
                      ]
                    : [
                        const TextSpan(text: 'Mulai belanja\n'),
                        TextSpan(text: 'lebih segar.', style: accent),
                      ],
              ),
              style: AppText.display.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              isLoginTab
                  ? 'Masuk untuk mengelola dan memesan sayur segar harianmu.'
                  : 'Buat akun untuk mulai menikmati kemudahan belanja sayuran segar.',
              style: AppText.body.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill Switcher [ Masuk | Daftar ] dengan kapsul aktif yang bergeser
  Widget _buildPillSwitcher(bool isLoginTab) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusPill),
        boxShadow: AppShadows.floating,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                left: isLoginTab ? 0 : segmentWidth,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: forestDeep,
                    borderRadius: BorderRadius.circular(radiusPill),
                    boxShadow: AppShadows.glow(forestDeep, strength: 0.22),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildSwitcherTab(
                    label: 'Masuk',
                    icon: Icons.login_rounded,
                    selected: isLoginTab,
                    onTap: () => _switchTab(0),
                  ),
                  _buildSwitcherTab(
                    label: 'Daftar',
                    icon: Icons.person_add_alt_1_rounded,
                    selected: !isLoginTab,
                    onTap: () => _switchTab(1),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitcherTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color color = selected ? Colors.white : textDarkSecondary;

    return Expanded(
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: const Duration(milliseconds: 220),
                builder: (context, value, _) =>
                    Icon(icon, size: 18, color: value),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppText.title.copyWith(color: color),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. INFO SESI BERAKHIR
  // ---------------------------------------------------------------------------
  Widget _buildSessionNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: secondaryColor50,
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: secondaryColor100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: secondaryColor600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesi berakhir',
                  style: AppText.title.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.sessionExpiredMessage ?? '',
                  style: AppText.caption.copyWith(
                    color: textDarkSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () => setState(() => _showSessionNotice = false),
            pressedScale: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: textDarkTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HANDLERS
  // ---------------------------------------------------------------------------

  /// Flow Masuk dengan Email & Password
  Future<void> _handleEmailLogin() async {
    FocusScope.of(context).unfocus();
    final email = _identifierController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAppSnackBar(
        context,
        'Email dan kata sandi wajib diisi.',
        type: AppSnackType.error,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      showAppSnackBar(
        context,
        'Format email tidak valid (contoh: nama@email.com).',
        type: AppSnackType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final emailAuth = serviceLocator.get<FirebaseEmailAuth>();
    final userPref = serviceLocator.get<UserPreference>();
    final analytics = serviceLocator.get<FirebaseAnalyticsHelper>();

    await emailAuth.signInWithEmail(
      email: email,
      password: password,
      onSuccess: (user) async {
        await analytics.setUserId(user.uid);
        await analytics.logLogin(loginMethod: 'email_password');

        await userPref.setUserId(user.uid);
        await userPref.setUserEmail(user.email ?? email);
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          await userPref.setUserName(user.displayName!);
        }
        await userPref.setLastLoginTime(DateTime.now());

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showAppSnackBar(context, message, type: AppSnackType.error);
      },
    );
  }

  /// Flow Daftar Akun Baru dengan Email & Password
  Future<void> _handleEmailRegister() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _identifierController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      showAppSnackBar(
        context,
        'Nama lengkap wajib diisi.',
        type: AppSnackType.error,
      );
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      showAppSnackBar(
        context,
        'Masukkan alamat email yang valid.',
        type: AppSnackType.error,
      );
      return;
    }

    if (password.length < 6) {
      showAppSnackBar(
        context,
        'Kata sandi minimal 6 karakter.',
        type: AppSnackType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    final emailAuth = serviceLocator.get<FirebaseEmailAuth>();
    final userPref = serviceLocator.get<UserPreference>();
    final analytics = serviceLocator.get<FirebaseAnalyticsHelper>();

    await emailAuth.signUpWithEmail(
      name: name,
      email: email,
      password: password,
      onSuccess: (user) async {
        await analytics.setUserId(user.uid);
        await analytics.logSignUp(signUpMethod: 'email_password');

        await userPref.setUserId(user.uid);
        await userPref.setUserEmail(user.email ?? email);
        await userPref.setUserName(name);
        await userPref.setLastLoginTime(DateTime.now());

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Snackbar tampil di MainNavigation, jadi posisikan di atas nav bar
        showAppSnackBar(
          context,
          'Pendaftaran berhasil! Selamat datang di GoVeg.',
          aboveNavBar: true,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showAppSnackBar(context, message, type: AppSnackType.error);
      },
    );
  }

  /// Flow Masuk dengan Akun Google
  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    final googleAuth = serviceLocator.get<FirebaseGoogleAuth>();
    final userPref = serviceLocator.get<UserPreference>();
    final analytics = serviceLocator.get<FirebaseAnalyticsHelper>();

    await googleAuth.signInWithGoogle(
      onSuccess: (uid, email, firstName, lastName) async {
        final fullName = '$firstName $lastName'.trim();

        await analytics.setUserId(uid);
        await analytics.logLogin(loginMethod: 'google');

        await userPref.setUserId(uid);
        await userPref.setUserEmail(email);
        await userPref.setUserName(
          fullName.isNotEmpty ? fullName : 'Pengguna GoVeg',
        );
        await userPref.setLastLoginTime(DateTime.now());

        if (!mounted) return;
        setState(() => _isGoogleLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isGoogleLoading = false);
        if (message.isNotEmpty) {
          showAppSnackBar(context, message, type: AppSnackType.error);
        }
      },
    );
  }

  /// Bottom sheet Lupa Kata Sandi
  Future<void> _showForgotPasswordDialog() async {
    FocusScope.of(context).unfocus();

    final String? sentTo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: inkSoft.withValues(alpha: 0.45),
      builder: (sheetCtx) =>
          _ForgotPasswordSheet(initialEmail: _identifierController.text.trim()),
    );

    if (!mounted || sentTo == null) return;
    showAppSnackBar(
      context,
      'Tautan reset sandi telah dikirim ke $sentTo. Silakan periksa kotak masuk/spam.',
      icon: Icons.mark_email_read_rounded,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FORM
  // ---------------------------------------------------------------------------

  /// 3A. Form Masuk
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _identifierController,
          label: 'Email',
          hint: 'nama@email.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          label: 'Kata Sandi',
          hint: 'Masukkan kata sandi',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          suffix: _buildPasswordToggle(),
          onSubmitted: (_) {
            if (!_isLoading) _handleEmailLogin();
          },
        ),
        const SizedBox(height: 16),
        _buildRememberRow(),
        const SizedBox(height: 28),
        AppButton(
          label: 'Masuk',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: _isLoading,
          onPressed: _handleEmailLogin,
        ),
      ],
    );
  }

  /// 3B. Form Daftar
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _nameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _identifierController,
          label: 'Email',
          hint: 'nama@email.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          label: 'Kata Sandi',
          hint: 'Minimal 6 karakter',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          suffix: _buildPasswordToggle(),
          onSubmitted: (_) {
            if (!_isLoading) _handleEmailRegister();
          },
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Daftar Sekarang',
          trailingIcon: Icons.arrow_forward_rounded,
          isLoading: _isLoading,
          onPressed: _handleEmailRegister,
        ),
      ],
    );
  }

  /// Tombol lihat / sembunyikan kata sandi
  Widget _buildPasswordToggle() {
    return Pressable(
      onTap: () => setState(() => isPasswordVisible = !isPasswordVisible),
      pressedScale: 0.88,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Icon(
            isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            key: ValueKey<bool>(isPasswordVisible),
            size: 20,
            color: isPasswordVisible ? primaryColor : textDarkTertiary,
          ),
        ),
      ),
    );
  }

  /// Ingat saya + Lupa sandi
  Widget _buildRememberRow() {
    return Row(
      children: [
        Pressable(
          onTap: () => setState(() => rememberMe = !rememberMe),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: rememberMe ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: rememberMe ? primaryColor : borderNeutral,
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: rememberMe ? 1 : 0,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Ingat saya', style: AppText.body.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ),
        const Spacer(),
        Pressable(
          onTap: _showForgotPasswordDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Lupa sandi?',
              style: AppText.captionStrong.copyWith(
                color: primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PEMBATAS ATAU
  // ---------------------------------------------------------------------------
  Widget _buildOrDivider() {
    Widget line({required bool reverse}) {
      final colors = [borderNeutral.withValues(alpha: 0), borderNeutral];
      return Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: reverse ? colors.reversed.toList() : colors,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        line(reverse: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('atau lanjutkan dengan', style: AppText.caption),
        ),
        line(reverse: true),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TOMBOL SOCIAL LOGIN
  // ---------------------------------------------------------------------------
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            svgPath: 'assets/svg/google_logo.svg',
            isLoading: _isGoogleLoading,
            onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            svgPath: 'assets/svg/apple_logo.svg',
            onTap: () {
              showAppSnackBar(
                context,
                'Masuk dengan Apple ID segera hadir di pembaruan berikutnya.',
                type: AppSnackType.info,
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. AJAKAN PINDAH TAB
  // ---------------------------------------------------------------------------
  Widget _buildSwitchPrompt(bool isLoginTab) {
    return Center(
      child: Pressable(
        onTap: () => _switchTab(isLoginTab ? 1 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isLoginTab
                      ? 'Belum punya akun? '
                      : 'Sudah punya akun? ',
                ),
                TextSpan(
                  text: isLoginTab ? 'Daftar sekarang' : 'Masuk',
                  style: AppText.title.copyWith(
                    color: primaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            style: AppText.body.copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol social login (outline kapsul dengan logo SVG)
// ─────────────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final String svgPath;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SocialButton({
    required this.label,
    required this.svgPath,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radiusPill),
          border: Border.all(color: borderNeutral, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 2,
                ),
              )
            else
              SvgPicture.asset(svgPath, width: 20, height: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isLoading ? 'Memuat...' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet Lupa Kata Sandi
// Mengembalikan email tujuan (String) saat tautan reset berhasil dikirim.
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _resetEmailController =
      TextEditingController(text: widget.initialEmail);
  bool _isSending = false;

  /// Pesan error ditampilkan di dalam sheet (snackbar akan tertutup sheet).
  String? _errorMessage;

  @override
  void dispose() {
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return;

    final email = _resetEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Masukkan email yang valid.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final emailAuth = serviceLocator.get<FirebaseEmailAuth>();
    await emailAuth.sendPasswordReset(
      email: email,
      onSuccess: () {
        if (!mounted) return;
        Navigator.pop(context, email);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _errorMessage = err;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_isSending,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.forest,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.glow(forestDeep, strength: 0.25),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('LUPA KATA SANDI', style: AppText.overline),
                const SizedBox(height: 6),
                const Text('Atur ulang kata sandi', style: AppText.h2),
                const SizedBox(height: 8),
                Text(
                  'Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                  style: AppText.body.copyWith(fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _resetEmailController,
                  label: 'Email',
                  hint: 'nama@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: _errorMessage == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 10, left: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 16,
                                  color: errorColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppText.caption.copyWith(
                                    color: errorColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Kirim Tautan Reset',
                  icon: Icons.send_rounded,
                  isLoading: _isSending,
                  onPressed: _submit,
                ),
                const SizedBox(height: 6),
                AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.ghost,
                  height: 48,
                  onPressed: _isSending ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
