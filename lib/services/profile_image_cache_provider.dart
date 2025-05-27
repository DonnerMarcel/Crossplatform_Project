import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateNotifier that holds a map of user IDs to profile image URLs.
class ProfileImageCacheNotifier extends StateNotifier<Map<String, String>> {
  ProfileImageCacheNotifier() : super({});

  /// Update (or add) a cached image URL for a given user ID
  void cacheImageUrl(String userId, String imageUrl) {
    state = {
      ...state,
      userId: imageUrl,
    };
  }

  /// Clear the entire cache (optional utility method)
  void clearCache() {
    state = {};
  }
}

/// Global provider for the image cache
final profileImageCacheProvider =
StateNotifierProvider<ProfileImageCacheNotifier, Map<String, String>>(
      (ref) => ProfileImageCacheNotifier(),
);
