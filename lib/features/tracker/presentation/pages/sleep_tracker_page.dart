import 'package:pandara_health/core/widgets/app_avatar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:pandara_health/core/data/models/hive_models.dart';
import 'package:pandara_health/core/data/repositories/health_repository.dart';
import 'package:pandara_health/core/widgets/app_bottom_nav.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';

class SleepTrackerPage extends ConsumerStatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  ConsumerState<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends ConsumerState<SleepTrackerPage> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _selectedQuality = 'Cukup';
  final bool _isRefreshed = true;

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

  @override
  void initState() {
    super.initState();
    _startTime = const TimeOfDay(hour: 22, minute: 0);
    _endTime = const TimeOfDay(hour: 6, minute: 0);
  }

  double _calculateDuration() {
    double start = _startTime.hour + (_startTime.minute / 60.0);
    double end = _endTime.hour + (_endTime.minute / 60.0);

    if (end < start) {
      return (24.0 - start) + end;
    }
    return end - start;
  }

  final List<Map<String, dynamic>> _qualities = [
    {'label': 'Buruk', 'icon': Icons.sentiment_very_dissatisfied_outlined},
    {'label': 'Kurang', 'icon': Icons.sentiment_dissatisfied_outlined},
    {'label': 'Cukup', 'icon': Icons.sentiment_neutral_outlined},
    {'label': 'Baik', 'icon': Icons.sentiment_satisfied_outlined},
    {'label': 'Nyenyak', 'icon': Icons.sentiment_very_satisfied_outlined},
  ];

  // Perbaikan Modul Validasi Input Durasi Tidur sebelum data disimpan
  Future<void> _saveSleep() async {
    final repository = ref.read(healthRepositoryProvider);
    final duration = _calculateDuration();

    // Validasi: Durasi tidur wajib lebih besar dari 0 jam
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Durasi tidur harus lebih besar dari 0 jam! Silakan periksa kembali jam tidur dan bangun Anda.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final record = SleepRecord(
      date: DateTime.now(),
      hours: duration,
      quality: _selectedQuality,
      isRefreshed: _isRefreshed,
    );

    await repository.addSleep(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data tidur berhasil disimpan!'),
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
                                  text: 'Bagaimana ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'istirahat',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(text: ' kamu hari ini?'),
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
                      'Pantau perkembangan tidur Anda secara rutin untuk hasil yang optimal.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Duration Card
                    _buildDurationCard(),

                    const SizedBox(height: 24),

                    // Quality Card
                    _buildQualityCard(),

                    const SizedBox(height: 24),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveSleep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.black38),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildDurationCard() {
    final duration = _calculateDuration();
    final dHours = duration.floor();
    final dMinutes = ((duration - dHours) * 60).round();

    return Container(
      width: double.infinity,
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
        children: [
          const Text(
            'Kapan Anda tidur & bangun?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimePicker(
                'MULAI TIDUR',
                _startTime,
                (time) => setState(() => _startTime = time),
              ),
              const Icon(Icons.arrow_forward, color: Colors.black12, size: 24),
              _buildTimePicker(
                'BANGUN TIDUR',
                _endTime,
                (time) => setState(() => _endTime = time),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.nightlight_round,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Durasi Tidur: $dHours j $dMinutes m',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onSelected,
  ) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
              // Memaksa dialog input jam langsung memunculkan soft keyboard angka text-field
              initialEntryMode: TimePickerEntryMode.input,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );
            if (picked != null) onSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$hour:$minute',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityCard() {
    return Container(
      width: double.infinity,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kualitas Tidur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.star, color: AppColors.primary, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _qualities.map((q) {
              final isSelected = _selectedQuality == q['label'];
              return GestureDetector(
                onTap: () => setState(() => _selectedQuality = q['label']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        q['icon'] as IconData,
                        color: isSelected ? AppColors.primary : Colors.black26,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black26,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
