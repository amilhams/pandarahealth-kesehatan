import 'package:pandara_health/core/widgets/app_avatar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class ManageProfilePage extends ConsumerStatefulWidget {
  const ManageProfilePage({super.key});

  @override
  ConsumerState<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends ConsumerState<ManageProfilePage> {
  late TextEditingController _nameController;
  String? _profilePicPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).getCurrentUser();
    _nameController = TextEditingController(text: user?.name ?? '');
    _profilePicPath = user?.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profilePicPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  ImageProvider _getProfileImage(String? path) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http') || path.startsWith('https')) {
        return NetworkImage(path);
      } else {
        return FileImage(File(path));
      }
    }
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400');
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.updateProfile(
      name: name,
      profilePic: _profilePicPath,
    );

    // Update global state immediately
    ref.read(currentUserProvider.notifier).state = authRepo.getCurrentUser();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Kelola Profil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Spacer(),
                  AppAvatar(radius: 20, profilePic: _profilePicPath),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Change Photo Section
                    _buildPhotoSection(),
                    const SizedBox(height: 40),
                    // Info Card
                    _buildInfoCard(user?.email ?? 'user@pandara.health'),
                    const SizedBox(height: 40),
                    // Action Button
                    _buildActionButton(context),
                    const SizedBox(height: 24),
                    const Text(
                      'Perubahan disimpan secara langsung di database lokal',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
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

  Widget _buildPhotoSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: AppAvatar(radius: 70, profilePic: _profilePicPath),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'KETUK UNTUK UBAH FOTO',
          style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Text('Informasi Akun', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildReadOnlyField('Email / Akun', email, icon: Icons.email_outlined),
          const SizedBox(height: 20),
          _buildInputField('Nama Lengkap', null, _nameController, icon: Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.015),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black12),
                const SizedBox(width: 12),
              ],
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black38),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String? prefix, TextEditingController controller, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              icon: prefix != null 
                ? Text(prefix, style: const TextStyle(color: Colors.black26, fontSize: 18, fontWeight: FontWeight.bold))
                : Icon(icon, color: Colors.black26),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text(
        'Simpan Perubahan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
