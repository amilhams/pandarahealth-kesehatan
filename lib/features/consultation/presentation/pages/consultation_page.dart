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

class DoctorModel {
  final String name;
  final String spec;
  final String category; // 'Umum', 'Anak', 'Paru', 'Jantung', 'Gizi', 'Mental'
  final String exp;
  final String img;
  final String phone;

  DoctorModel({
    required this.name,
    required this.spec,
    required this.category,
    required this.exp,
    required this.img,
    required this.phone,
  });
}

class ConsultationPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const ConsultationPage({super.key, this.initialCategory});

  @override
  ConsumerState<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends ConsumerState<ConsultationPage> {
  late String _selectedCategory;
  final List<DoctorModel> _allDoctors = [
    DoctorModel(
      name: 'Dr. Ilham Nur',
      spec: 'Spesialis Gizi Klinik',
      category: 'Gizi',
      exp: '8 Thn',
      img: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=400',
      phone: '6285176914026',
    ),
    DoctorModel(
      name: 'Dr. Adrian Pratama',
      spec: 'Spesialis Jantung',
      category: 'Jantung',
      exp: '12 Thn',
      img: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=400',
      phone: '6285176914026',
    ),
    DoctorModel(
      name: 'Dr. Rakha Buming',
      spec: 'Dokter Umum',
      category: 'Umum',
      exp: '15 Thn',
      img: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=400',
      phone: '6285176914026',
    ),
    DoctorModel(
      name: 'Dr. Herman Yusuf',
      spec: 'Spesialis Paru',
      category: 'Paru',
      exp: '10 Thn',
      img: 'https://plus.unsplash.com/premium_photo-1661764878654-3d0fc2eefcca?q=80&w=400',
      phone: '6285176914026',
    ),
    DoctorModel(
      name: 'Dr. Muhana Putra',
      spec: 'Psikolog Klinis',
      category: 'Mental',
      exp: '7 Thn',
      img: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=400',
      phone: '6285176914026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Semua';
    // Normalisasi category jika ada query parameter yang dikirimkan (kategori Anak dihapus)
    final validCategories = ['Semua', 'Umum', 'Paru', 'Jantung', 'Gizi', 'Mental'];
    if (!validCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }
  }

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
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Saring dokter berdasarkan kategori yang dipilih
    final filteredDoctors = _selectedCategory == 'Semua'
        ? _allDoctors
        : _allDoctors.where((doc) => doc.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Layanan Telemedisin',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Categories
                    _buildCategories(),
                    
                    const SizedBox(height: 24),
                    Text(
                      _selectedCategory == 'Semua' 
                          ? 'Daftar Dokter Spesialis Kami' 
                          : 'Dokter Spesialis $_selectedCategory',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    if (filteredDoctors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            'Tidak ada dokter spesialis yang terdaftar di kategori ini.',
                            style: TextStyle(color: Colors.black38),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDoctors.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final doc = filteredDoctors[index];
                          return _buildDoctorCard(
                            context, 
                            doc.name, 
                            doc.spec, 
                            doc.exp, 
                            doc.img, 
                            doc.phone
                          );
                        },
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

  Widget _buildCategories() {
    final categories = ['Semua', 'Umum', 'Paru', 'Jantung', 'Gizi', 'Mental'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.toLowerCase() == _selectedCategory.toLowerCase();
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildDoctorCard(BuildContext context, String name, String spec, String exp, String img, String phone) {
    Color chipColor;
    Color textColor;
    IconData specIcon;

    if (spec.contains('Gizi') || spec.contains('Nutrisi')) {
      chipColor = const Color(0xFFE8F5E9); // soft green
      textColor = const Color(0xFF2E7D32);
      specIcon = Icons.restaurant_outlined;
    } else if (spec.contains('Jantung')) {
      chipColor = const Color(0xFFFFEBEE); // soft red
      textColor = const Color(0xFFC62828);
      specIcon = Icons.favorite_rounded;
    } else if (spec.contains('Anak')) {
      chipColor = const Color(0xFFE8F5E9); // soft green
      textColor = const Color(0xFF2E7D32);
      specIcon = Icons.child_care_rounded;
    } else if (spec.contains('Paru')) {
      chipColor = const Color(0xFFFFF3E0); // soft orange
      textColor = const Color(0xFFE65100);
      specIcon = Icons.air_outlined;
    } else if (spec.contains('Psikolog') || spec.contains('Mental')) {
      chipColor = const Color(0xFFECEFF1); // soft grey-blue
      textColor = const Color(0xFF37474F);
      specIcon = Icons.psychology_outlined;
    } else {
      // Dokter Umum / default
      chipColor = const Color(0xFFE3F2FD); // soft blue
      textColor = const Color(0xFF1565C0);
      specIcon = Icons.person_outline_rounded;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.push(
          Uri(
            path: '/doctor_profile',
            queryParameters: {
              'name': name,
              'spec': spec,
              'exp': exp,
              'img': img,
              'phone': phone,
            },
          ).toString(),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _getProfileImage(img),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, color: Colors.blue, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(specIcon, size: 13, color: textColor),
                              const SizedBox(width: 4),
                              Text(
                                spec,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStatItem(Icons.business_center_outlined, exp),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(healthRepositoryProvider);
                  final String reportText = WeeklyReportData.getFormattedReportText(repo);
                  final String message = "Halo $name, saya ingin berkonsultasi mengenai kesehatan saya melalui aplikasi Pandara Health.\n\n$reportText\n\nMohon arahannya dokter, terima kasih.";
                  final Uri url = Uri.parse("https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}");
                  try {
                    final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                    if (!launched) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal membuka WhatsApp. Pastikan aplikasi WhatsApp terinstal.'),
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
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Mulai Konsultasi (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black26),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
