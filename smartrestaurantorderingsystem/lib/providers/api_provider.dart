import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: ApiConstants.baseUrl);
});
