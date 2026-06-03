import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isAgreed = false;
  bool _isLoading = false;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final success = await repository.register(name, email, password);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan masuk.'),
              backgroundColor: AppColors.primary,
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi gagal. Silakan coba kembali.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal';
      
      // Penerjemahan Kode Error Registrasi Firebase Auth ke Bahasa Indonesia
      if (e.code == 'weak-password') {
        message = 'Kata sandi terlalu lemah (minimal 6 karakter)';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar dan digunakan oleh akun lain';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi jaringan gagal. Periksa kembali sambungan internet Anda.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Autentikasi Email/Password belum diaktifkan di Firebase Console';
      } else if (e.message != null) {
        message = e.message!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
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
            // Header Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              alignment: Alignment.centerLeft,
              color: Colors.white,
              child: Image.asset(
                'assets/images/logo_health_fix.png',
                height: 40,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Buat Akun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bergabunglah dengan Pandara dan kendalikan kesehatan Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        label: 'Nama Lengkap',
                        hint: 'John Doe',
                        icon: Icons.person_outline,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Email',
                        hint: 'john@example.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Kata Sandi',
                        hint: '........',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Konfirmasi Kata Sandi',
                        hint: '........',
                        icon: Icons.lock_clock_outlined,
                        controller: _confirmController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: (val) => setState(() => _isAgreed = val!),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi Pandara Health',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Daftar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Sudah punya akun? ',
                              style: TextStyle(color: Colors.black54),
                              children: [
                                TextSpan(
                                  text: 'Masuk',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            prefixIcon: Icon(icon, color: Colors.black26),
            filled: true,
            fillColor: const Color(0xFFF1F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}