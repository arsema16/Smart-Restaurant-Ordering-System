import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../repositories/session_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/recommendation_repository.dart';
import '../core/constants/api_constants.dart';

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: ApiConstants.baseUrl);
});

/// Provider for Session Repository
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SessionRepository(api);
});

/// Provider for Menu Repository
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return MenuRepository(api);
});

/// Provider for Cart Repository
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return CartRepository(api);
});

/// Provider for Order Repository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return OrderRepository(api);
});

/// Provider for Recommendation Repository
final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return RecommendationRepository(api);
});

