import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a profile image and return its download URL
  Future<String> uploadProfileImage({required String userId, required File imageFile}) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');

      await ref.putFile(imageFile);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get download URL for a user's profile image
  Future<String> getProfileImageUrl(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get profile image URL: $e');
    }
  }

  /// Delete a profile image (optional)
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}
