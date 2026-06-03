import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/models/hive_models.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final currentUserProvider = StateProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUser();
});

class AuthRepository {
  final Box<UserModel> _userBox = Hive.box<UserModel>('user_box');
  final Box _settingsBox = Hive.box('settings_box');

  static const String _currentUserKey = 'current_user_email';

  Future<bool> register(String name, String email, String password) async {
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) return false;

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      final user = UserModel(name: name, email: email, password: password);

      // Save to Hive
      await _userBox.put(email, user);
      await _userBox.put(
        'current_user',
        UserModel(
          name: user.name,
          email: user.email,
          password: user.password,
          profilePic: user.profilePic,
        ),
      );

      // 2. Save profile to Firestore (menggunakan UID sebagai document key)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': name,
            'email': email,
            'profilePic': '',
          }, SetOptions(merge: true));

      // Clear old tracker boxes
      await Hive.box<MoodRecord>('mood_box').clear();
      await Hive.box<SleepRecord>('sleep_box').clear();
      await Hive.box<VitalsRecord>('vitals_box').clear();
      await Hive.box<NutritionRecord>('nutrition_box').clear();
      await Hive.box<SymptomRecord>('symptom_box').clear();

      await Hive.box<MoodRecord>('mood_box').flush();
      await Hive.box<SleepRecord>('sleep_box').flush();
      await Hive.box<VitalsRecord>('vitals_box').flush();
      await Hive.box<NutritionRecord>('nutrition_box').flush();
      await Hive.box<SymptomRecord>('symptom_box').flush();

      await _userBox.flush(); // Memaksa penulisan ke disk

      // Auto-login setelah registrasi
      await _settingsBox.put(_currentUserKey, email);
      await _settingsBox.flush();

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase Auth Exception during registration: ${e.code} - ${e.message}",
      );
      rethrow;
    } catch (e) {
      debugPrint("Error registering in Firebase: $e");
      rethrow;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      // 1. Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) return null;

      // 2. Fetch profile from Firestore (menggunakan UID sebagai document key)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      String name = userCredential.user!.displayName ?? 'User';
      String? profilePic;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        name = data['name'] ?? name;
        profilePic = data['profilePic'];
      }

      final user = UserModel(
        name: name,
        email: email,
        password: password,
        profilePic: profilePic,
      );

      // Save to Hive
      await _userBox.put(email, user);
      await _userBox.put(
        'current_user',
        UserModel(
          name: user.name,
          email: user.email,
          password: user.password,
          profilePic: user.profilePic,
        ),
      );
      await _userBox.flush();

      // Clear old tracker boxes
      await Hive.box<MoodRecord>('mood_box').clear();
      await Hive.box<SleepRecord>('sleep_box').clear();
      await Hive.box<VitalsRecord>('vitals_box').clear();
      await Hive.box<NutritionRecord>('nutrition_box').clear();
      await Hive.box<SymptomRecord>('symptom_box').clear();

      await Hive.box<MoodRecord>('mood_box').flush();
      await Hive.box<SleepRecord>('sleep_box').flush();
      await Hive.box<VitalsRecord>('vitals_box').flush();
      await Hive.box<NutritionRecord>('nutrition_box').flush();
      await Hive.box<SymptomRecord>('symptom_box').flush();

      await _settingsBox.put(_currentUserKey, email);
      await _settingsBox.flush();

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase Auth Exception during login: ${e.code} - ${e.message}",
      );
      rethrow;
    } catch (e) {
      debugPrint("Error logging in Firebase: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }

    await _settingsBox.delete(_currentUserKey);
    await _userBox.delete('current_user');

    // Clear old tracker boxes
    await Hive.box<MoodRecord>('mood_box').clear();
    await Hive.box<SleepRecord>('sleep_box').clear();
    await Hive.box<VitalsRecord>('vitals_box').clear();
    await Hive.box<NutritionRecord>('nutrition_box').clear();
    await Hive.box<SymptomRecord>('symptom_box').clear();

    await Hive.box<MoodRecord>('mood_box').flush();
    await Hive.box<SleepRecord>('sleep_box').flush();
    await Hive.box<VitalsRecord>('vitals_box').flush();
    await Hive.box<NutritionRecord>('nutrition_box').flush();
    await Hive.box<SymptomRecord>('symptom_box').flush();

    await _userBox.flush();
    await _settingsBox.flush();
  }

  UserModel? getCurrentUser() {
    final email = _settingsBox.get(_currentUserKey);
    if (email != null) {
      final user = _userBox.get(email);
      if (user != null) {
        return UserModel(
          name: user.name,
          email: user.email,
          password: user.password,
          profilePic: user.profilePic,
        );
      }
    }
    return null;
  }

  // TC-ACC-01 & TC-ACC-02: Sinkronisasi pembaruan profil ke Cloud Firestore
  Future<void> updateProfile({required String name, String? profilePic}) async {
    final email = _settingsBox.get(_currentUserKey);
    if (email != null) {
      try {
        // 1. Perbarui display name di Firebase Auth terlebih dahulu
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

        // 2. Kirim data pembaruan ke Cloud Firestore (users/{uid})
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final Map<String, dynamic> firestoreData = {'name': name};
        if (profilePic != null) {
          firestoreData['profilePic'] = profilePic;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(firestoreData, SetOptions(merge: true));

        // 3. Jika berhasil, baru perbarui penyimpanan Hive lokal
        final user = _userBox.get(email);
        if (user != null) {
          user.name = name;
          if (profilePic != null) {
            user.profilePic = profilePic;
          }
          await _userBox.put(email, user);
          await _userBox.put(
            'current_user',
            UserModel(
              name: user.name,
              email: user.email,
              password: user.password,
              profilePic: user.profilePic,
            ),
          );
          await _userBox.flush();
        }
      } catch (e) {
        debugPrint("Error updating profile in Firebase/Firestore: $e");
        rethrow;
      }
    }
  }

  // TC-ACC-03: Ganti email menggunakan verifyBeforeUpdateEmail + UID-based Firestore
  Future<bool> updateEmail(String newEmail) async {
    final currentEmail = _settingsBox.get(_currentUserKey);
    if (currentEmail != null && currentEmail != newEmail) {
      final user = _userBox.get(currentEmail);
      if (user != null) {
        try {
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) return false;

          // 1. Re-autentikasi untuk operasi sensitif
          final credential = EmailAuthProvider.credential(
            email: currentEmail,
            password: user.password,
          );
          await firebaseUser.reauthenticateWithCredential(credential);

          // 2. Kirim verifikasi ke email baru (email di Auth berubah setelah diverifikasi)
          await firebaseUser.verifyBeforeUpdateEmail(newEmail);

          // 3. Update field email di Firestore (doc key = UID, tidak perlu migrasi)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set({'email': newEmail}, SetOptions(merge: true));

          // 4. Update penyimpanan Hive lokal
          final newUser = UserModel(
            name: user.name,
            email: newEmail,
            password: user.password,
            profilePic: user.profilePic,
          );
          await _userBox.put(newEmail, newUser);
          await _userBox.put(
            'current_user',
            UserModel(
              name: newUser.name,
              email: newUser.email,
              password: newUser.password,
              profilePic: newUser.profilePic,
            ),
          );
          await _userBox.delete(currentEmail);
          await _settingsBox.put(_currentUserKey, newEmail);

          await _userBox.flush();
          await _settingsBox.flush();
          return true;
        } on FirebaseAuthException catch (e) {
          debugPrint(
            "Firebase Auth Exception during updateEmail: ${e.code} - ${e.message}",
          );
          rethrow;
        } catch (e) {
          debugPrint("Error updating email: $e");
          rethrow;
        }
      }
    }
    return false;
  }

  // TC-ACC-05: Ganti password aman dengan validasi urutan & rethrow error ke UI
  Future<void> updatePassword(String newPassword) async {
    try {
      // 1. Lakukan update di Firebase Auth terlebih dahulu
      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);

      // 2. Jika sukses tanpa exception, perbarui kata sandi di Hive lokal
      final email = _settingsBox.get(_currentUserKey);
      if (email != null) {
        final user = _userBox.get(email);
        if (user != null) {
          user.password = newPassword;
          await _userBox.put(email, user);
          await _userBox.put(
            'current_user',
            UserModel(
              name: user.name,
              email: user.email,
              password: user.password,
              profilePic: user.profilePic,
            ),
          );
          await _userBox.flush();
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase Auth Exception during updatePassword: ${e.code} - ${e.message}",
      );
      rethrow;
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  // TC-ACC-06: Penghapusan akun bersih (Menghapus dokumen pengguna & seluruh subkoleksinya)
  Future<void> deleteAccount() async {
    final email = _settingsBox.get(_currentUserKey);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    try {
      if (firebaseUser != null) {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        // 1. Referensi ke dokumen pengguna utama (menggunakan UID)
        final userDocRef = firestore.collection('users').doc(firebaseUser.uid);
        batch.delete(userDocRef);

        // 2. Hapus data dari seluruh subkoleksi pendukung tracker
        final List<String> subcollections = [
          'moods',
          'sleeps',
          'vitals',
          'nutrition',
          'symptoms',
        ];
        for (final subcollection in subcollections) {
          final snapshots = await userDocRef.collection(subcollection).get();
          for (final doc in snapshots.docs) {
            batch.delete(doc.reference);
          }
        }

        // Eksekusi penghapusan massal di Firestore
        await batch.commit();
      }

      // 3. Hapus akun dari Firebase Authentication
      await FirebaseAuth.instance.currentUser?.delete();

      // 4. Bersihkan data sisa yang ada pada Hive lokal
      if (email != null) {
        await _userBox.delete(email);
        await _userBox.delete('current_user');
        await _settingsBox.delete(_currentUserKey);

        await Hive.box<MoodRecord>('mood_box').clear();
        await Hive.box<SleepRecord>('sleep_box').clear();
        await Hive.box<VitalsRecord>('vitals_box').clear();
        await Hive.box<NutritionRecord>('nutrition_box').clear();
        await Hive.box<SymptomRecord>('symptom_box').clear();

        await Hive.box<MoodRecord>('mood_box').flush();
        await Hive.box<SleepRecord>('sleep_box').flush();
        await Hive.box<VitalsRecord>('vitals_box').flush();
        await Hive.box<NutritionRecord>('nutrition_box').flush();
        await Hive.box<SymptomRecord>('symptom_box').flush();

        await _userBox.flush();
        await _settingsBox.flush();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase Auth Exception during deleteAccount: ${e.code} - ${e.message}",
      );
      rethrow;
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  bool isLoggedIn() {
    return _settingsBox.containsKey(_currentUserKey);
  }
}
