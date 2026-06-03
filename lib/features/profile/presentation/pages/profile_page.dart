import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Image.asset('assets/images/logo_health_fix.png', height: 32),
                  ),
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
                  children: [
                    const SizedBox(height: 20),
                    // Profile Info
                    _buildProfileHeader(user?.name ?? 'User', user?.email ?? 'user@pandara.health', user?.profilePic),
                    const SizedBox(height: 40),
                    // Settings Menu
                    _buildSettingsMenu(context, ref),
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

  Widget _buildProfileHeader(String name, String email, String? profilePic) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: _getProfileImage(profilePic),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: const TextStyle(color: Colors.black38, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, 'Kelola Profil', Colors.teal, false, onTap: () => context.push('/manage_profile')),
          _buildDivider(),
          _buildMenuItem(Icons.account_balance_wallet_outlined, 'Manajemen Akun', Colors.teal, false, onTap: () => context.push('/account_management')),
          _buildDivider(),
          _buildMenuItem(Icons.storage_outlined, 'Database Inspector', Colors.teal, false, onTap: () => context.push('/debug_db')),
          _buildDivider(),
          _buildMenuItem(
            Icons.logout, 
            'Logout', 
            Colors.redAccent, 
            true, 
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(currentUserProvider.notifier).state = null;
              if (context.mounted) {
                context.go('/welcome');
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, bool isDestructive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.redAccent : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: isDestructive ? Colors.redAccent.withValues(alpha: 0.3) : Colors.black12),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.03)),
    );
  }
}
