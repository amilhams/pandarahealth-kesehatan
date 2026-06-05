import 'package:pandara_health/core/widgets/app_avatar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/models/hive_models.dart';
import '../../../../core/data/repositories/health_repository.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

// ─── Period option ────────────────────────────────────────────────────────────
class _PeriodOption {
  final String label;
  final DateTime start;
  final DateTime end;
  _PeriodOption({required this.label, required this.start, required this.end});
}

class _VitalRangeItem {
  final String label;
  final String range;
  final Color color;
  _VitalRangeItem(this.label, this.range, this.color);
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class WeeklyReportPage extends ConsumerStatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  ConsumerState<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends ConsumerState<WeeklyReportPage> {
  late _PeriodOption _selected;
  String _selectedVital = 'HR'; // 'HR', 'STEPS', 'BMI', 'SPO2'

  // ── helpers ────────────────────────────────────────────────────────────────
  ImageProvider _getProfileImage(String? pic) {
    if (pic != null && pic.isNotEmpty) {
      if (pic.startsWith('http') || pic.startsWith('https')) {
        return NetworkImage(pic);
      }
      return FileImage(File(pic));
    }
    return const NetworkImage(
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    );
  }

  String _fmtRange(DateTime s, DateTime e) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (s.month == e.month && s.year == e.year) {
      return '${s.day} – ${e.day} ${m[e.month - 1]} ${e.year}';
    }
    return '${s.day} ${m[s.month - 1]} – ${e.day} ${m[e.month - 1]} ${e.year}';
  }

  int _getDataDaysCount(HealthRepository repo) {
    final all = <String>{};
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
    for (final v in Hive.box<VitalsRecord>('vitals_box').values) {
      all.add(key(v.date));
    }
    for (final m in repo.getAllMoods()) {
      all.add(key(m.date));
    }
    for (final s in repo.getAllSleep()) {
      all.add(key(s.date));
    }
    for (final n in Hive.box<NutritionRecord>('nutrition_box').values) {
      all.add(key(n.date));
    }
    for (final sym in Hive.box<SymptomRecord>('symptom_box').values) {
      all.add(key(sym.date));
    }
    return all.isEmpty ? 0 : all.length;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    _selected = _PeriodOption(
      label: _fmtRange(start, today),
      start: start,
      end: today,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(healthRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final days = _getDataDaysCount(repo);

    final start = _selected.start;
    final end = _selected.end;

    final sleeps = repo.getSleepByRange(start, end);
    final moods = repo.getMoodsByRange(start, end);
    final vitals = repo.getVitalsByRange(start, end);
    final nutrition = repo.getNutritionByRange(start, end);
    final symptoms = repo.getSymptomsByRange(start, end);

    // PERBAIKAN 1: Mengubah logika agar dinamis murni mengikuti filter kalender berjalan
    final latestVital = vitals.isNotEmpty ? vitals.last : null;

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
                    child: Image.asset(
                      'assets/images/logo_health_fix.png',
                      height: 32,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan Mingguan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Calendar Selection Dropdown ─────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: DateTimeRange(
                            start: _selected.start,
                            end: _selected.end,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selected = _PeriodOption(
                              label: _fmtRange(picked.start, picked.end),
                              start: picked.start,
                              end: picked.end,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selected.label,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── New User Banner ─────────────────────────────────────
                    if (days > 0 && days < 7) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFE0B2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.orange,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Periode laporan hanya tersedia dalam format mingguan. Berikut adalah ringkasan data Anda selama $days hari terakhir. Ringkasan penuh akan tersedia setelah pengisian mencapai satu minggu.',
                                style: const TextStyle(
                                  color: Color(0xFFD84315),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Cards ───────────────────────────────────────────────
                    _buildSleepCard(sleeps),
                    const SizedBox(height: 16),
                    _buildVitalsCard(latestVital, vitals),
                    const SizedBox(height: 16),
                    _buildNutritionCard(nutrition),
                    const SizedBox(height: 16),
                    _buildMoodCard(moods),
                    const SizedBox(height: 16),
                    _buildSymptomsCard(symptoms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── 1. Sleep ──────────────────────────────────────────────────────────────
  Widget _buildSleepCard(List<SleepRecord> sleeps) {
    return _sectionCard(
      icon: Icons.bedtime_outlined,
      color: Colors.indigo,
      title: 'Data Tidur',
      child: _sleepContent(sleeps),
    );
  }

  Widget _sleepContent(List<SleepRecord> sleeps) {
    final avgHours = sleeps.isEmpty
        ? 0.0
        : sleeps.fold(0.0, (s, r) => s + r.hours) / sleeps.length;
    final h = avgHours.floor();
    final m = ((avgHours - h) * 60).round();

    final qualityCount = <String, int>{};
    for (final s in sleeps) {
      qualityCount[s.quality] = (qualityCount[s.quality] ?? 0) + 1;
    }
    final dominantQ = sleeps.isEmpty
        ? '0'
        : qualityCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    String summary;
    if (sleeps.isEmpty) {
      summary =
          'Belum ada catatan jadwal tidur Anda di periode ini. Silakan catat tidur harian Anda.';
    } else if (avgHours >= 7 &&
        (dominantQ == 'Baik' || dominantQ == 'Nyenyak')) {
      summary =
          'Berdasarkan catatan jadwal tidur Anda di periode ini, kualitas dan durasi tidur terpantau sangat baik.';
    } else if (avgHours < 5) {
      summary =
          'Durasi tidur rata-rata Anda di periode ini cukup singkat. Usahakan tidur minimal 7 jam per malam untuk pemulihan optimal.';
    } else if (dominantQ == 'Buruk' || dominantQ == 'Kurang') {
      summary =
          'Kualitas tidur Anda dominan "$dominantQ" pada periode ini. Pertimbangkan untuk menjaga konsistensi jam tidur dan bangun.';
    } else {
      summary =
          'Rata-rata tidur Anda ${h}j ${m}m per malam dengan kualitas $dominantQ. Pertahankan kebiasaan ini.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${h}j ${m}m',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'rata-rata / malam',
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sleeps.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: sleeps.take(7).map((s) {
              final barH = (s.hours / 10).clamp(0.1, 1.0);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 40 * barH,
                      width: 22,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.hours.toStringAsFixed(0)}j',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (sleeps.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: qualityCount.entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${e.key} (${e.value}x)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF3949AB),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Vitals ─────────────────────────────────────────────────────────────
  Widget _buildVitalsCard(
    VitalsRecord? latest,
    List<VitalsRecord> periodVitals,
  ) {
    return _sectionCard(
      icon: Icons.monitor_heart_outlined,
      color: Colors.redAccent,
      title: 'Data Vital Terkini',
      child: _vitalsContent(latest, periodVitals),
    );
  }

  Widget _vitalsContent(VitalsRecord? v, List<VitalsRecord> period) {
    final avgHR = period.isEmpty
        ? (v?.heartRate ?? 0)
        : (period.fold(0, (s, r) => s + r.heartRate) / period.length).round();
    final avgSteps = period.isEmpty
        ? (v?.steps ?? 0)
        : (period.fold(0, (s, r) => s + r.steps) / period.length).round();

    final latestWeight = v?.weight ?? 0.0;
    final latestHeight = v?.height ?? 0;
    final bmi = (latestWeight > 0 && latestHeight > 0)
        ? HealthRepository.calculateBMI(latestWeight, latestHeight)
        : null;

    final spo2 = v?.oxygen;

    final hrVal = avgHR > 0 ? '$avgHR BPM' : '0 BPM';
    final stepsVal = avgSteps > 0 ? '$avgSteps' : '0';
    final bmiVal = bmi != null ? bmi.toStringAsFixed(1) : '0';
    final spo2Val = spo2 != null ? '$spo2%' : '0%';

    Widget infoBox;
    switch (_selectedVital) {
      case 'HR':
        infoBox = _buildVitalInfoBox(
          title: 'Detak Jantung (Heart Rate)',
          subtitle:
              'Frekuensi detak jantung per menit (BPM) diukur saat istirahat.',
          color: Colors.redAccent,
          icon: Icons.favorite,
          currentValue: hrVal,
          ranges: [
            _VitalRangeItem(
              'Lambat (Bradycardia / Buruk)',
              '< 60 BPM',
              Colors.orange,
            ),
            _VitalRangeItem('Normal (Ideal)', '60 - 100 BPM', Colors.green),
            _VitalRangeItem(
              'Cepat (Tachycardia / Intens)',
              '> 100 BPM',
              Colors.red,
            ),
          ],
        );
        break;
      case 'STEPS':
        infoBox = _buildVitalInfoBox(
          title: 'Jumlah Langkah (Steps)',
          subtitle: 'Aktivitas fisik harian berdasarkan jumlah langkah kaki.',
          color: Colors.teal,
          icon: Icons.directions_walk,
          currentValue: '$stepsVal langkah',
          ranges: [
            _VitalRangeItem('Kurang Aktif (Sedentary)', '< 5.000', Colors.red),
            _VitalRangeItem('Cukup Aktif', '5.000 - 9.999', Colors.orange),
            _VitalRangeItem('Aktif (Sangat Baik)', '>= 10.000', Colors.green),
          ],
        );
        break;
      case 'BMI':
        infoBox = _buildVitalInfoBox(
          title: 'Indeks Massa Tubuh (BMI)',
          subtitle: 'Perbandingan berat badan dengan tinggi badan (kg/m²).',
          color: Colors.purple,
          icon: Icons.monitor_weight_outlined,
          currentValue: bmiVal,
          ranges: [
            _VitalRangeItem('Kurang Berat Badan', '< 18.5', Colors.orange),
            _VitalRangeItem('Normal / Ideal', '18.5 - 24.9', Colors.green),
            _VitalRangeItem('Kelebihan Berat', '25.0 - 29.9', Colors.orange),
            _VitalRangeItem('Obesitas', '>= 30.0', Colors.red),
          ],
        );
        break;
      case 'SPO2':
      default:
        infoBox = _buildVitalInfoBox(
          title: 'Saturasi Oksigen (SpO2)',
          subtitle:
              'Persentase hemoglobin yang membawa oksigen di dalam darah.',
          color: Colors.blue,
          icon: Icons.air,
          currentValue: spo2Val,
          ranges: [
            _VitalRangeItem('Normal / Sehat', '95% - 100%', Colors.green),
            _VitalRangeItem(
              'Rendah (Hypoxia Ringan)',
              '90% - 94%',
              Colors.orange,
            ),
            _VitalRangeItem(
              'Sangat Rendah (Hypoxia Berat)',
              '< 90%',
              Colors.red,
            ),
          ],
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _vitalChip(
              Icons.favorite,
              hrVal,
              'Detak Jantung',
              Colors.redAccent,
              _selectedVital == 'HR',
              () {
                setState(() => _selectedVital = 'HR');
              },
            ),
            const SizedBox(width: 8),
            _vitalChip(
              Icons.directions_walk,
              stepsVal,
              'Langkah',
              Colors.teal,
              _selectedVital == 'STEPS',
              () {
                setState(() => _selectedVital = 'STEPS');
              },
            ),
            const SizedBox(width: 8),
            _vitalChip(
              Icons.monitor_weight_outlined,
              bmiVal,
              'BMI',
              Colors.purple,
              _selectedVital == 'BMI',
              () {
                setState(() => _selectedVital = 'BMI');
              },
            ),
            const SizedBox(width: 8),
            _vitalChip(
              Icons.air,
              spo2Val,
              'SpO2',
              Colors.blue,
              _selectedVital == 'SPO2',
              () {
                setState(() => _selectedVital = 'SPO2');
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        infoBox,
      ],
    );
  }

  Widget _vitalChip(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black38, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalInfoBox({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String currentValue,
    required List<_VitalRangeItem> ranges,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8),
          const Text(
            'Panduan Parameter (Standar Internasional):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...ranges.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: r.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    r.range,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: r.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Nutrition ──────────────────────────────────────────────────────────
  Widget _buildNutritionCard(List<NutritionRecord> records) {
    return _sectionCard(
      icon: Icons.restaurant_menu,
      color: Colors.green,
      title: 'Data Nutrisi Periode Ini',
      child: _nutritionContent(records),
    );
  }

  Widget _nutritionContent(List<NutritionRecord> records) {
    final totalCal = records.isEmpty
        ? 0
        : records.fold(0, (s, n) => s + n.calories);
    final totalProt = records.isEmpty
        ? 0
        : records.fold(0, (s, n) => s + n.protein);
    final totalCarb = records.isEmpty
        ? 0
        : records.fold(0, (s, n) => s + n.carbs);
    final totalFat = records.isEmpty ? 0 : records.fold(0, (s, n) => s + n.fat);
    final totalWater = records.isEmpty
        ? 0
        : records.fold(0, (s, n) => s + (n.water ?? 0));

    String summary;
    if (records.isEmpty) {
      summary = 'Belum ada catatan data nutrisi Anda pada periode ini.';
    } else if (totalProt > 50 && totalFat < 80) {
      summary =
          'Selama periode ini, Anda telah mengonsumsi total $totalCal kalori. Asupan protein harian tercukupi dengan baik, dan konsumsi lemak masih dalam batas wajar.';
    } else if (totalFat >= 80) {
      summary =
          'Selama periode ini, Anda telah mengonsumsi total $totalCal kalori. Asupan protein harian tercukupi, namun perhatikan kembali batas konsumsi lemak Anda yang mencapai ${totalFat}g.';
    } else if (totalProt < 30) {
      summary =
          'Total $totalCal kalori tercatat di periode ini. Asupan protein perlu ditingkatkan — pastikan cukup sumber protein seperti daging, telur, atau kacang-kacangan.';
    } else {
      summary =
          'Total $totalCal kalori tercatat pada periode ini. Pantau terus keseimbangan makronutrisi untuk menjaga energi optimal.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$totalCal',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'kalori total',
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _macroChip('Protein', totalProt, Colors.redAccent, 'g'),
            const SizedBox(width: 8),
            _macroChip('Karbo', totalCarb, Colors.orange, 'g'),
            const SizedBox(width: 8),
            _macroChip('Lemak', totalFat, Colors.blueAccent, 'g'),
            const SizedBox(width: 8),
            _macroChip('Air', totalWater, const Color(0xFF29B6F6), 'ml'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${records.length} entri makanan tercatat',
          style: const TextStyle(color: Colors.black38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _macroChip(String label, int value, Color color, [String unit = 'g']) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Mood ───────────────────────────────────────────────────────────────
  Widget _buildMoodCard(List<MoodRecord> moods) {
    return _sectionCard(
      icon: Icons.sentiment_satisfied_alt,
      color: Colors.orange,
      title: 'Suasana Hati',
      child: _moodContent(moods),
    );
  }

  Widget _moodContent(List<MoodRecord> moods) {
    const emojis = {
      'Angry': '😠',
      'Sad': '😔',
      'Neutral': '😐',
      'Happy': '😊',
      'Great': '🤩',
    };
    final count = <String, int>{};
    for (final m in moods) {
      count[m.mood] = (count[m.mood] ?? 0) + 1;
    }
    final dominant = moods.isEmpty
        ? 'Neutral'
        : count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emojis[dominant] ?? '😐',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moods.isEmpty ? 'Belum ada data' : 'Dominan: $dominant',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${moods.length} catatan pada periode ini',
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        if (moods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: count.entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${emojis[e.key] ?? ''} ${e.key} (${e.value}x)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  // ── 5. Symptoms ───────────────────────────────────────────────────────────
  Widget _buildSymptomsCard(List<SymptomRecord> symptoms) {
    return _sectionCard(
      icon: Icons.medical_information_outlined,
      color: Colors.deepOrange,
      title: 'Gejala Periode Ini',
      child: _symptomsContent(symptoms),
    );
  }

  Widget _symptomsContent(List<SymptomRecord> symptoms) {
    final standardSymptoms = [
      'Sakit Kepala',
      'Demam',
      'Batuk',
      'Mual',
      'Alergi',
      'Kelelahan',
    ];

    final agg = <String, List<double>>{};
    for (final rec in symptoms) {
      rec.symptoms.forEach((name, sev) {
        agg.putIfAbsent(name, () => []).add(sev);
      });
    }
    final avgSev = agg.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );

    final sortedSymptoms = List<String>.from(standardSymptoms)
      ..sort((a, b) {
        final sevA = avgSev[a] ?? 0.0;
        final sevB = avgSev[b] ?? 0.0;
        return sevB.compareTo(sevA);
      });

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedSymptoms.map((name) {
        final severity = avgSev[name] ?? 0.0;
        final color = severity >= 7
            ? Colors.red
            : (severity >= 4
                  ? Colors.orange
                  : (severity > 0 ? Colors.teal : Colors.black26));
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$name   ${severity > 0 ? severity.toStringAsFixed(1) : '0'}/10',
            style: TextStyle(
              fontSize: 12,
              color: severity > 0 ? color : Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
