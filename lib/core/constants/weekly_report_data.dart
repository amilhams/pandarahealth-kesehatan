import '../data/repositories/health_repository.dart';

/// Wrapper tipis untuk menghasilkan teks laporan mingguan secara dinamis.
/// Semua kalkulasi dilakukan oleh [HealthRepository.generateWeeklyReportText].
class WeeklyReportData {
  /// Menghasilkan teks ringkasan mingguan berdasarkan data aktual 7 hari terakhir.
  /// Memerlukan instance [HealthRepository] agar dapat membaca data dari Hive.
  static String getFormattedReportText(HealthRepository repo) {
    return repo.generateWeeklyReportText();
  }
}
