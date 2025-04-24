// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/group_data_service.dart'; // Import the service
import 'models/models.dart'; // Import the model for the state type

// Define the StateNotifierProvider
// This provider creates and holds the single instance of GroupDataService
// and exposes its state (List<PaymentGroup>).
final groupServiceProvider = StateNotifierProvider<GroupDataService, List<PaymentGroup>>((ref) {
  // The callback function creates the instance of our service.
  // This is typically called only once by Riverpod.
  return GroupDataService();
});

// Optional: You could add other providers here later, for example:
// final settingsProvider = StateProvider<AppSettings>((ref) => AppSettings());
// final currentUserProvider = Provider<User?>((ref) => null); // Example for auth state