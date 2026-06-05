import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Widget avatar profil yang digunakan di seluruh aplikasi.
///
/// - Jika [profilePic] berisi URL (http/https) → tampilkan foto dari network.
/// - Jika [profilePic] berisi path lokal → tampilkan foto dari file.
/// - Jika [profilePic] null atau kosong → tampilkan icon person dengan
///   background teal sesuai desain UI.
class AppAvatar extends StatelessWidget {
  /// Path / URL foto profil. Boleh null / kosong untuk tampilkan default.
  final String? profilePic;

  /// Radius lingkaran avatar (default: 20).
  final double radius;

  /// Warna background avatar default (default: AppColors.primary teal).
  final Color backgroundColor;

  /// Warna icon person pada avatar default (default: putih).
  final Color iconColor;

  const AppAvatar({
    super.key,
    this.profilePic,
    this.radius = 20,
    this.backgroundColor = AppColors.primary,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final pic = profilePic;

    // Tidak ada foto — tampilkan icon avatar default
    if (pic == null || pic.trim().isEmpty) {
      return _defaultAvatar();
    }

    // Foto dari network (URL)
    if (pic.startsWith('http://') || pic.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(pic),
        // Fallback jika network error
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // Foto dari file lokal
    final file = File(pic);
    if (file.existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(file),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // File tidak ditemukan — fallback ke default
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(
        Icons.person_rounded,
        color: iconColor,
        size: radius * 1.1,
      ),
    );
  }
}
