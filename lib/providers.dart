import 'package:flutter_riverpod/flutter_riverpod.dart';
// Assuming correct paths
import 'services/group_data_service.dart';
import 'models/models.dart';

// This provider definition looks correct.
final groupServiceProvider = StateNotifierProvider<GroupDataService, List<PaymentGroup>>((ref) {
  // It creates and returns your state management service.
  return GroupDataService();
});

final userIdProvider = StateProvider<String?>((ref) => null);