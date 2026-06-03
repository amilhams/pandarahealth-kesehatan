import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pandara_health/core/data/models/hive_models.dart';
import 'package:pandara_health/core/data/repositories/health_repository.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';

class SymptomTrackerPage extends ConsumerStatefulWidget {
  const SymptomTrackerPage({super.key});

  @override
  ConsumerState<SymptomTrackerPage> createState() => _SymptomTrackerPageState();
}

class _SymptomTrackerPageState extends ConsumerState<SymptomTrackerPage> {
  final Map<String, double> _userSymptomSelection = {};

  ImageProvider _getProfileImage(String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      if (profilePic.startsWith('http') || profilePic.startsWith('https')) {
        return NetworkImage(profilePic);
      } else {
        return FileImage(File(profilePic));
      }
    }
    return const NetworkImage(
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    );
  }

  Future<void> _saveSymptoms() async {
    if (_userSymptomSelection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu gejala!')),
      );
      return;
    }

    final repository = ref.read(healthRepositoryProvider);
    final record = SymptomRecord(
      date: DateTime.now(),
      symptoms: Map.from(_userSymptomSelection),
    );

    await repository.addSymptom(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gejala berhasil disimpan!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Sakit Kepala', 'icon': Icons.face_outlined},
    {'name': 'Demam', 'icon': Icons.thermostat_outlined},
    {'name': 'Batuk', 'icon': Icons.air_outlined},
    {'name': 'Sesak Napas', 'icon': Icons.bubble_chart_outlined},
    {'name': 'Sakit Tenggorokan', 'icon': Icons.healing_outlined},
    {'name': 'Mual', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Alergi', 'icon': Icons.spa_outlined},
    {'name': 'Kelelahan', 'icon': Icons.bed_outlined},
  ];

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _getProfileImage(user?.profilePic),
                      backgroundColor: AppColors.primary,
                    ),
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
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Apa ',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: 'gejala',
                                      style: TextStyle(color: AppColors.primary),
                                    ),
                                    TextSpan(text: ' yang kamu rasakan?'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih satu atau lebih gejala yang sedang Anda alami saat ini untuk analisis lebih lanjut.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gejala Umum',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${(_userSymptomSelection).length} Terpilih', // Dart handles null check if I make it nullable, but here I keep it non-nullable but force a refresh.
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSymptomGrid(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveSymptoms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Simpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Batal', style: TextStyle(color: Colors.black38)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSymptomGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        final symptomName = symptom['name'] as String;
        final isSelected = _userSymptomSelection.containsKey(symptomName);
        final severity = _userSymptomSelection[symptomName] ?? 5.0;

        return GestureDetector(
          onTap: () => _showSeverityDialog(symptomName, severity),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        symptom['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.black38,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      symptomName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${severity.toInt()}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSeverityDialog(String symptomName, double currentSeverity) {
    double tempSeverity = currentSeverity;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Column(
                children: [
                  const Text('Tingkat Keparahan', style: TextStyle(fontSize: 14, color: Colors.black45)),
                  const SizedBox(height: 8),
                  Text(symptomName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '${tempSeverity.toInt()}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: tempSeverity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withValues(alpha: 0.1),
                    onChanged: (val) => setDialogState(() => tempSeverity = val),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ringan', style: TextStyle(fontSize: 12, color: Colors.black26)),
                        Text('Parah', style: TextStyle(fontSize: 12, color: Colors.black26)),
                      ],
                    ),
                  ),
                  if (tempSeverity > 7) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8A8A), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sangat mengganggu aktivitas!',
                              style: TextStyle(color: Color(0xFF7A4E4E), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _userSymptomSelection.remove(symptomName));
                    Navigator.pop(context);
                  },
                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _userSymptomSelection[symptomName] = tempSeverity);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
