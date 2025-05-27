// lib/utils/profile_image_preloader.dart

import 'package:flutter_application_2/services/profile_image_cache_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/firebase_storage_service.dart';

Future<void> preloadProfileImages(WidgetRef ref, List<User> users) async {
  final storageService = FirebaseStorageService();
  final cacheNotifier = ref.read(profileImageCacheProvider.notifier);
  final cached = ref.read(profileImageCacheProvider);

  for (final user in users) {
    if (!cached.containsKey(user.id)) {
      try {
        final url = await storageService.getProfileImageUrl(user.id);
        cacheNotifier.cacheImageUrl(user.id, url);
      } catch (_) {
        // Image not found or error – silently ignore
      }
    }
  }
}
