import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pandara_health/core/widgets/app_avatar.dart';
import 'package:pandara_health/core/constants/app_colors.dart';
import 'package:pandara_health/features/auth/data/repositories/auth_repository.dart';
import 'package:pandara_health/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pandara_health/features/dashboard/presentation/providers/triage_provider.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _warningDialogShown = false;



  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(currentUserProvider);
    final triageResult = ref.watch(triageResultProvider);
    final triageWarningDismissed = ref.watch(triageWarningDismissedProvider);
    final triageWarningDismissedNotifier = ref.read(
      triageWarningDismissedProvider.notifier,
    );
    final triageCriticalAcknowledged = ref.watch(
      triageCriticalAcknowledgedProvider,
    );
    final triageCriticalAcknowledgedNotifier = ref.read(
      triageCriticalAcknowledgedProvider.notifier,
    );

    _maybeShowWarningDialog(
      triageResult,
      triageWarningDismissed,
      context,
      triageWarningDismissedNotifier,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.name ?? 'User'}! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bagaimana kabar kesehatanmu hari ini?',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        if (triageResult.type == TriageType.critical &&
                            triageCriticalAcknowledged) ...[
                          _buildCriticalCard(triageResult),
                          const SizedBox(height: 24),
                        ],
                        if (triageResult.type == TriageType.warning) ...[
                          _buildWarningCard(
                            triageResult,
                            triageWarningDismissed,
                            triageWarningDismissedNotifier,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (triageResult.type == TriageType.habits) ...[
                          _buildHabitBannerSection(triageResult),
                          const SizedBox(height: 24),
                        ],
                        if (triageResult.type == TriageType.safe) ...[
                          _buildSafeStatusCard(),
                          const SizedBox(height: 24),
                        ],
                        _buildEnhancedVitalCard(stats),
                        const SizedBox(height: 32),
                        const Text(
                          'Akses Cepat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAccessGrid(),
                        const SizedBox(height: 32),
                        const Text(
                          'Daftar Dokter Spesialis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDoctorList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (triageResult.type == TriageType.critical &&
                !triageCriticalAcknowledged)
              _buildCriticalOverlay(
                triageResult,
                triageCriticalAcknowledgedNotifier,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  void _maybeShowWarningDialog(
    TriageResult triageResult,
    bool isDismissed,
    BuildContext context,
    TriageWarningDismissedNotifier dismissNotifier,
  ) {
    if (triageResult.type != TriageType.warning ||
        isDismissed ||
        _warningDialogShown) {
      return;
    }

    _warningDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFF8E1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF57C00),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    triageResult.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              triageResult.description,
              style: const TextStyle(color: Color(0xFF5D4037)),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Color(0xFF616161)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  dismissNotifier.dismiss();
                  Navigator.of(context).pop();
                  context.go(
                    '/consult?category=${triageResult.recommendedSpecialty ?? 'Semua'}',
                  );
                },
                child: const Text('Konsultasi Sekarang'),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildWarningCard(
    TriageResult triageResult,
    bool isDismissed,
    TriageWarningDismissedNotifier dismissNotifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF57C00),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Peringatan Kesehatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            triageResult.description,
            style: const TextStyle(color: Color(0xFF5D4037), height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: () => context.go(
                  '/consult?category=${triageResult.recommendedSpecialty ?? 'Semua'}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Konsultasi Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitBannerSection(TriageResult triageResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF1565C0),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Rekomendasi Kebiasaan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...triageResult.banners.map(
          (banner) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context.go('/consult?category=${banner.category}'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tips_and_updates_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.description,
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${banner.actionText} →',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kondisi Hari Ini Aman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Hebat! Kondisimu hari ini sangat baik.',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalCard(TriageResult triageResult) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.dangerous_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kondisi Darurat!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            triageResult.description,
            style: const TextStyle(color: Color(0xFF8E0000)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => _launchPhoneDialer('112'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Hubungi IGD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () => context.go(
                  '/consult?category=${triageResult.recommendedSpecialty ?? 'Semua'}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Konsultasi Spesialis',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalOverlay(
    TriageResult triageResult,
    TriageCriticalAcknowledgedNotifier criticalNotifier,
  ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.dangerous_rounded,
                      color: Color(0xFFE53935),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        triageResult.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  triageResult.description,
                  style: const TextStyle(color: Color(0xFF8E0000), height: 1.4),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        criticalNotifier.acknowledge();
                        _launchPhoneDialer('112');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Hubungi IGD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        criticalNotifier.acknowledge();
                        context.go(
                          '/consult?category=${triageResult.recommendedSpecialty ?? 'Semua'}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Konsultasi Spesialis',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildEnhancedVitalCard(DashboardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Ringkasan vital harian',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.shield_outlined, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                children: [
                  _buildVitalSubCard(
                    Icons.favorite_outline,
                    'Detak Jantung',
                    stats.heartRate > 0 ? '${stats.heartRate}' : '—',
                    'BPM',
                  ),
                  const SizedBox(width: 16),
                  _buildVitalSubCard(
                    Icons.directions_walk,
                    'Langkah',
                    stats.steps > 0 ? '${stats.steps}' : '—',
                    '',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildVitalSubCard(
                    Icons.air,
                    'Kadar Oksigen',
                    stats.oxygen != null ? '${stats.oxygen}' : '—',
                    '% SpO2',
                  ),
                  const SizedBox(width: 16),
                  _buildVitalSubCard(
                    Icons.bedtime_outlined,
                    'Tidur',
                    stats.sleepHours > 0
                        ? stats.sleepHours.toStringAsFixed(1)
                        : '—',
                    'jam',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lihat Detail',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSubCard(
    IconData icon,
    String label,
    String value,
    String unit,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildAccessCard(
          Icons.show_chart,
          'Tracker',
          'Pantau harian',
          const Color(0xFFE0F7F9),
          AppColors.primary,
          () => context.go('/tracker'),
        ),
        _buildAccessCard(
          Icons.assessment_outlined,
          'Laporan',
          'Ringkasan mingguan',
          const Color(0xFFF3E5F5),
          Colors.purple,
          () => context.go('/reports'),
        ),
        _buildAccessCard(
          Icons.shopping_bag_outlined,
          'Konsultasi',
          'Tanya dokter',
          const Color(0xFFFFF3E0),
          Colors.orange,
          () => context.go('/consult'),
        ),
        _buildAccessCard(
          Icons.person_outline,
          'Profil',
          'Atur akun',
          const Color(0xFFE8F5E9),
          Colors.green,
          () => context.go('/profile'),
        ),
      ],
    );
  }

  Widget _buildAccessCard(
    IconData icon,
    String title,
    String sub,
    Color bgColor,
    Color iconColor,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.black38, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    final List<Map<String, String>> doctors = [
      {
        'name': 'Dr. Adrian Pratama',
        'spec': 'Spesialis Jantung',
        'rate': '4.9',
        'exp': '12 Thn',
        'img':
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=400',
      },
      {
        'name': 'Dr. Ilham Nur',
        'spec': 'Spesialis Gizi',
        'rate': '4.8',
        'exp': '8 Thn',
        'img':
            'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=400',
      },
      {
        'name': 'Dr. Rakha Buming',
        'spec': 'Umum',
        'rate': '4.7',
        'exp': '15 Thn',
        'img':
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=400',
      },
    ];

    return Column(
      children: doctors
          .map(
            (doc) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(
                  Uri(
                    path: '/doctor_profile',
                    queryParameters: {
                      'name': doc['name']!,
                      'spec': doc['spec']!,
                      'exp': doc['exp']!,
                      'img': doc['img']!,
                      'phone': '6285176914026',
                    },
                  ).toString(),
                ),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          doc['img']!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 64,
                                height: 64,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.medical_services,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      doc['spec']!,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business_center_outlined,
                                  size: 14,
                                  color: Colors.black26,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${doc['exp']} Pengalaman',
                                    style: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
