import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/group_data_service.dart';
import 'models/models.dart';

final groupServiceProvider = StateNotifierProvider<GroupDataService, List<PaymentGroup>>((ref) {
  return GroupDataService();
});
