import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ditambahkan untuk menangkap FirebaseAuthException
import '../../../../core/widgets/app_bottom_nav.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom kata sandi harus diisi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.getCurrentUser();

    if (user != null && user.password != currentPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi saat ini salah!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi baru minimal harus 8 karakter!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi baru tidak cocok!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TC-ACC-05: Penanganan Error & Keamanan Perubahan Password
    try {
      // Eksekusi pembaruan password
      await authRepo.updatePassword(newPassword);

      // Jika berhasil tanpa lemparan error, perbarui state provider UI
      ref.read(currentUserProvider.notifier).state = authRepo.getCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik dari Firebase Auth dan menerjemahkannya ke Bahasa Indonesia
      String errorMessage = 'Gagal memperbarui kata sandi. Silakan coba lagi.';

      if (e.code == 'requires-recent-login') {
        errorMessage =
            'Sesi Anda telah berakhir demi keamanan. Silakan keluar (logout) dan masuk kembali sebelum mengubah kata sandi.';
      } else if (e.code == 'weak-password') {
        errorMessage =
            'Kata sandi yang Anda masukkan terlalu lemah atau mudah ditebak.';
      } else if (e.code == 'user-token-expired') {
        errorMessage = 'Autentikasi Anda kedaluwarsa. Silakan masuk kembali.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Menangkap error umum/koneksi lainnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Terjadi kesalahan koneksi atau sistem. Silakan coba beberapa saat lagi.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Security Header
                    _buildSecurityHeader(),
                    const SizedBox(height: 32),
                    // Password Card
                    _buildPasswordCard(),
                    const SizedBox(height: 40),
                    // Action Button
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildSecurityHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Keamanan Akun',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Pastikan kata sandi Anda kuat dan sulit ditebak untuk keamanan akun yang lebih baik.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, height: 1.5, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPasswordField(
            'Kata Sandi Saat Ini',
            Icons.lock_outline,
            _showCurrent,
            (v) => setState(() => _showCurrent = v),
            _currentPasswordController,
          ),
          const SizedBox(height: 24),
          _buildPasswordField(
            'Kata Sandi Baru',
            Icons.vpn_key_outlined,
            _showNew,
            (v) => setState(() => _showNew = v),
            _newPasswordController,
          ),
          const SizedBox(height: 16),
          _buildStrengthIndicator(),
          const SizedBox(height: 24),
          _buildPasswordField(
            'Konfirmasi Kata Sandi Baru',
            Icons.lock_reset,
            _showConfirm,
            (v) => setState(() => _showConfirm = v),
            _confirmPasswordController,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    IconData icon,
    bool isVisible,
    Function(bool) onToggle,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            onChanged: (val) {
              if (label == 'Kata Sandi Baru') {
                setState(() {});
              }
            },
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.black26),
              suffixIcon: IconButton(
                onPressed: () => onToggle(!isVisible),
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black26,
                  size: 20,
                ),
              ),
              hintText: '........',
              hintStyle: const TextStyle(color: Colors.black12, fontSize: 18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++; // length check
    if (RegExp(r'[a-zA-Z]').hasMatch(password)) strength++; // letters
    if (RegExp(r'[0-9]').hasMatch(password)) strength++; // numbers
    if (RegExp(r'[!@#\$&*~%]').hasMatch(password)) strength++; // symbols
    return strength;
  }

  Widget _buildStrengthIndicator() {
    final password = _newPasswordController.text;
    final score = _calculateStrength(password);

    String label = 'Sangat Lemah';
    Color color = Colors.redAccent;
    if (score == 0) {
      label = 'Belum Diisi';
      color = Colors.black26;
    } else if (score == 1) {
      label = 'Lemah';
      color = Colors.redAccent;
    } else if (score == 2) {
      label = 'Sedang';
      color = Colors.orange;
    } else if (score == 3) {
      label = 'Kuat';
      color = AppColors.primary;
    } else if (score == 4) {
      label = 'Sangat Kuat';
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kekuatan Kata Sandi',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  color: index < score ? color : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gunakan minimal 8 karakter dengan kombinasi huruf, angka, dan simbol.',
          style: TextStyle(color: Colors.black26, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updatePassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Perbarui Kata Sandi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
    );
  }
}
