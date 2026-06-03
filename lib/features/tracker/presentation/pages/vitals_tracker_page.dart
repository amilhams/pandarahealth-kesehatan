import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:pandara_health/core/data/models/hive_models.dart';
import 'package:pandara_health/core/data/repositories/health_repository.dart';
import 'package:pandara_health/core/widgets/app_bottom_nav.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';

class VitalsTrackerPage extends ConsumerStatefulWidget {
  const VitalsTrackerPage({super.key});

  @override
  ConsumerState<VitalsTrackerPage> createState() => _VitalsTrackerPageState();
}

class _VitalsTrackerPageState extends ConsumerState<VitalsTrackerPage> {
  final TextEditingController _heightController = TextEditingController(
    text: '170',
  );
  final TextEditingController _weightController = TextEditingController(
    text: '65.5',
  );
  final TextEditingController _heartRateController = TextEditingController(
    text: '72',
  );
  final TextEditingController _oxygenController = TextEditingController(
    text: '98',
  );
  final TextEditingController _stepsController = TextEditingController(
    text: '8000',
  );

  // Live BMI calculation
  double? _bmi;
  String _bmiCategory = '';

  void _recalculateBMI() {
    final w = double.tryParse(_weightController.text.trim());
    final h = int.tryParse(_heightController.text.trim());
    if (w != null && h != null && h > 0 && w > 0) {
      setState(() {
        _bmi = HealthRepository.calculateBMI(w, h);
        _bmiCategory = _bmi != null ? HealthRepository.bmiCategory(_bmi!) : '';
      });
    } else {
      setState(() {
        _bmi = null;
        _bmiCategory = '';
      });
    }
  }

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
    // Prefill dengan data vitalitas terbaru jika tersedia di lokal lokal
    final latest = ref.read(healthRepositoryProvider).getLatestVitals();
    if (latest != null) {
      _weightController.text = latest.weight.toString();
      _heartRateController.text = latest.heartRate.toString();
      _stepsController.text = latest.steps.toString();
      if (latest.height != null) {
        _heightController.text = latest.height.toString();
      }
      if (latest.oxygen != null) {
        _oxygenController.text = latest.oxygen.toString();
      }
    }
    // Kalkulasi awal BMI setelah proses prefill selesai
    _recalculateBMI();

    // Pasang listener untuk kalkulasi BMI secara realtime saat mengetik
    _heightController.addListener(_recalculateBMI);
    _weightController.addListener(_recalculateBMI);
  }

  @override
  void dispose() {
    _heightController.removeListener(_recalculateBMI);
    _weightController.removeListener(_recalculateBMI);
    _heightController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _oxygenController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Validasi Input Vitalitas Kesehatan Sebelum Data Disimpan secara Permanen
  Future<void> _saveVitals() async {
    // 1. Parsing input teks ke bentuk numerik secara aman
    final int? height = int.tryParse(_heightController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());
    final int? heartRate = int.tryParse(_heartRateController.text.trim());
    final int? oxygen = int.tryParse(_oxygenController.text.trim());
    final int? steps = int.tryParse(_stepsController.text.trim());

    // 2. Validasi format angka / kolom kosong
    if (height == null ||
        weight == null ||
        heartRate == null ||
        oxygen == null ||
        steps == null) {
      _showWarningSnackBar(
        'Semua kolom data kesehatan harus diisi dengan angka yang valid!',
      );
      return;
    }

    // 3. Validasi Nilai Positif dan Rentang Batas Logis (> 0)
    if (height <= 0) {
      _showWarningSnackBar('Tinggi badan harus lebih besar dari 0 cm!');
      return;
    }
    if (weight <= 0) {
      _showWarningSnackBar('Berat badan harus lebih besar dari 0 kg!');
      return;
    }
    if (heartRate <= 0) {
      _showWarningSnackBar('Detak jantung harus lebih besar dari 0 BPM!');
      return;
    }
    if (oxygen <= 0) {
      _showWarningSnackBar('Kadar oksigen harus lebih besar dari 0%!');
      return;
    }
    if (oxygen > 100) {
      _showWarningSnackBar('Kadar oksigen (SpO2) tidak boleh melebihi 100%!');
      return;
    }
    if (steps < 0) {
      _showWarningSnackBar(
        'Jumlah langkah harian tidak boleh bernilai negatif!',
      );
      return;
    }

    // 4. Jika seluruh validasi lolos, lakukan penyimpanan data ke repositori
    final repository = ref.read(healthRepositoryProvider);
    final record = VitalsRecord(
      date: DateTime.now(),
      heartRate: heartRate,
      steps: steps,
      weight: weight,
      height: height,
      oxygen: oxygen,
    );

    await repository.updateVitals(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data vitalitas berhasil disimpan!'),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catat Data Kesehatan',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Colors.black38,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hari ini, ${_getFormattedDate()}',
                                    style: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pantau perkembangan vitalitas tubuh Anda secara rutin untuk hasil yang optimal.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Body Stats Row
                    Row(
                      children: [
                        _buildHeightCard(),
                        const SizedBox(width: 16),
                        _buildWeightCard(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // BMI Preview Card
                    _buildBMIPreviewCard(),

                    const SizedBox(height: 24),

                    // Heart Rate Card
                    _buildHeartRateCard(),

                    const SizedBox(height: 24),

                    // Oxygen Card
                    _buildOxygenCard(),

                    const SizedBox(height: 24),

                    // Steps Card
                    _buildStepsCard(),

                    const SizedBox(height: 40),

                    // Tombol Aksi Simpan
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF00BFA5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveVitals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Simpan Data Kesehatan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
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
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Data Anda tersimpan dengan aman dan terenkripsi.',
                        style: TextStyle(color: Colors.black26, fontSize: 12),
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

  Widget _buildBMIPreviewCard() {
    final Color bmiColor;
    final Color bgColor;
    final IconData bmiIcon;

    if (_bmi == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              color: Colors.black26,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Isi tinggi & berat badan untuk melihat BMI',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_bmi! < 18.5) {
      bmiColor = Colors.blue;
      bgColor = const Color(0xFFE3F2FD);
      bmiIcon = Icons.arrow_downward_rounded;
    } else if (_bmi! < 25.0) {
      bmiColor = const Color(0xFF2E7D32);
      bgColor = const Color(0xFFE8F5E9);
      bmiIcon = Icons.check_circle_outline;
    } else if (_bmi! < 30.0) {
      bmiColor = Colors.orange;
      bgColor = const Color(0xFFFFF3E0);
      bmiIcon = Icons.warning_amber_rounded;
    } else {
      bmiColor = Colors.red;
      bgColor = const Color(0xFFFFEBEE);
      bmiIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bmiColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(bmiIcon, color: bmiColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INDEKS MASSA TUBUH (BMI)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _bmi!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '— $_bmiCategory',
                      style: TextStyle(
                        fontSize: 13,
                        color: bmiColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.height_rounded,
                  color: Colors.indigo,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'TINGGI BADAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF9F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'BERAT BADAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DETAK JANTUNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ukur saat tubuh rileks untuk tingkat akurasi data yang lebih baik.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heartRateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BPM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8095), Color(0xFFFF2D55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOxygenCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.air, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'KADAR OKSIGEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kadar oksigen normal berkisar antara 95% - 100%.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _oxygenController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '% SpO2',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF80B3FF), Color(0xFF3385FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.bubble_chart_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LANGKAH HARIAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aktivitas bergerak menjaga kesehatan jantung dan metabolisme tubuh.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'langkah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC080), Color(0xFFFF9500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}
