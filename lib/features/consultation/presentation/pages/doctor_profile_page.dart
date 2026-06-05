import 'package:pandara_health/core/widgets/app_avatar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pandara_health/core/constants/weekly_report_data.dart';
import 'package:pandara_health/core/data/repositories/health_repository.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class DoctorProfilePage extends ConsumerWidget {
  final String name;
  final String spec;
  final String exp;
  final String img;
  final String phone;

  const DoctorProfilePage({
    super.key,
    required this.name,
    required this.spec,
    required this.exp,
    required this.img,
    required this.phone,
  });

  ImageProvider _getProfileImage(String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      if (profilePic.startsWith('http') || profilePic.startsWith('https')) {
        return NetworkImage(profilePic);
      } else if (profilePic.startsWith('assets/')) {
        return AssetImage(profilePic);
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
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: AppAvatar(radius: 20, profilePic: user?.profilePic),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Photo with Gradient Overlay
                    _buildDoctorHeader(context),

                    // Floating Info Card
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildInfoCard(),
                            const SizedBox(height: 24),
                            _buildAboutSection(),
                            const SizedBox(height: 32),
                            _buildConsultationAction(context, ref),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildDoctorHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: _getProfileImage(img),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                const Color(0xFFF7FBFB),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black26),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final expYears = exp.replaceAll(RegExp(r'[^0-9]'), '');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            spec,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Terverifikasi Badge Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 18,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tahun Pengalaman Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF80E1D1).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expYears.isNotEmpty ? expYears : '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1D5A56),
                          ),
                        ),
                        const Text(
                          'TAHUN',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D5A56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Dokter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '$name adalah seorang $spec berdedikasi tinggi dengan pengalaman praktik selama $exp. Beliau memiliki keahlian mendalam dalam menangani keluhan pasien dan memberikan rekomendasi klinis yang tepat untuk mendukung kualitas hidup Anda.',
            style: const TextStyle(color: Colors.black54, height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationAction(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final repo = ref.read(healthRepositoryProvider);
            final String reportText = WeeklyReportData.getFormattedReportText(repo);
            final String message =
                "Halo $name, saya ingin berkonsultasi mengenai kesehatan saya melalui aplikasi Pandara Health.\n\n$reportText\n\nMohon arahannya dokter, terima kasih.";
            final Uri url = Uri.parse(
              "https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}",
            );
            try {
              final bool launched = await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Gagal membuka WhatsApp. Pastikan aplikasi WhatsApp terinstal.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Terjadi kesalahan: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 20),
              SizedBox(width: 8),
              Text(
                'Mulai Konsultasi (WhatsApp)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tersedia Hari Ini: 09:00 - 17:00 WIB',
          style: TextStyle(
            color: Colors.black38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
