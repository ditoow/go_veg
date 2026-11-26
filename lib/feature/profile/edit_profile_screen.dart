import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vegetables_app/ui/color.dart';
import 'package:vegetables_app/ui/shared_widget/app_widgets.dart';
import 'package:vegetables_app/ui/style.dart';
import 'package:vegetables_app/ui/theme.dart';
import 'package:vegetables_app/ui/typography.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialAddress;

  const EditProfileScreen({
    super.key,
    this.initialName = 'Doni Aditya Pratama',
    this.initialEmail = 'doniaditya004@gmail.com',
    this.initialPhone = '+62 812-3456-7890',
    this.initialAddress =
        'Jl. Nakula I No. 5-11, Pendrikan Kidul, Semarang Tengah',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      showAppSnackBar(
        context,
        'Profil berhasil diperbarui!',
        icon: Icons.check_rounded,
        aboveNavBar: true,
      );

      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });
    }
  }

  String _initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'VB';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: bgApp,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppPageHeader(
                title: 'Edit Profil',
                subtitle: 'Perbarui informasi akunmu',
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 28),

                        // Informasi pribadi
                        _buildFormCard(
                          overline: 'Informasi Pribadi',
                          children: [
                            AppTextField(
                              label: 'Nama Lengkap',
                              controller: _nameController,
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            AppTextField(
                              label: 'Alamat Email',
                              controller: _emailController,
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!val.contains('@')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            AppTextField(
                              label: 'Nomor WhatsApp / HP',
                              controller: _phoneController,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nomor telepon tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Alamat
                        _buildFormCard(
                          overline: 'Pengiriman',
                          children: [
                            AppTextField(
                              label: 'Alamat Pengiriman Utama',
                              controller: _addressController,
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                              keyboardType: TextInputType.streetAddress,
                              autofillHints: const [
                                AutofillHints.fullStreetAddress,
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Alamat tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tombol simpan
              Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: AppShadows.floating,
                ),
                child: AppButton(
                  label: 'Simpan Perubahan',
                  icon: Icons.check_rounded,
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: AppShadows.soft,
              ),
              child: ClipOval(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, _) {
                    final initials = Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor50, primaryColor100],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initialsOf(value.text),
                        style: AppText.display.copyWith(
                          color: primaryColor700,
                          fontSize: 34,
                        ),
                      ),
                    );

                    if (photoUrl == null || photoUrl.trim().isEmpty) {
                      return initials;
                    }
                    return Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stack) => initials,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: AppShadows.glow(primaryColor, strength: 0.3),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Ketuk ikon kamera untuk ganti foto',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required String overline,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(overline.toUpperCase(), style: AppText.overline),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
