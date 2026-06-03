import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class AccountManagementPage extends ConsumerWidget {
  const AccountManagementPage({super.key});

  ImageProvider _getProfileImage(String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      if (profilePic.startsWith('http') || profilePic.startsWith('https')) {
        return NetworkImage(profilePic);
      } else {
        return FileImage(File(profilePic));
      }
    }
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Manajemen Akun',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D1D1D)),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _getProfileImage(user?.profilePic),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Banner
                    _buildSecurityBanner(),
                    const SizedBox(height: 32),
                    
                    // Main Settings
                    const Text('PENGATURAN UTAMA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => context.push('/change_password'),
                      borderRadius: BorderRadius.circular(24),
                      child: _buildSettingsCard(Icons.lock_reset, 'Ganti Password', 'Amankan kredensial masuk Anda'),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => context.push('/change_email'),
                      borderRadius: BorderRadius.circular(24),
                      child: _buildSettingsCard(Icons.email_outlined, 'Ganti Email', user?.email ?? 'user@pandara.health'),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Danger Zone
                    const Text('ZONA BERBAHAYA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    _buildDangerZone(context, ref),
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

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KEAMANAN DATA', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          SizedBox(height: 8),
          Text('Terproteksi & Aman', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(
            'Kelola kredensial dan preferensi login Anda di sini.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub, style: const TextStyle(color: Colors.black26, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            'Menghapus akun akan menghilangkan semua data kesehatan, rekam medis, dan riwayat konsultasi Anda secara permanen.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showDeleteConfirmation(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline),
                SizedBox(width: 12),
                Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext outerContext, WidgetRef ref) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Akun Permanen?'),
          content: const Text('Apakah Anda yakin ingin menghapus akun ini secara permanen? Seluruh riwayat dan data Anda akan hilang dan tidak dapat dipulihkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.deleteAccount();
                ref.read(currentUserProvider.notifier).state = null;
                if (outerContext.mounted) {
                  outerContext.go('/welcome');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );
  }
}
