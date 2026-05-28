import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review.dart';
import '../../data/repositories/review_repository.dart';
import 'auth_provider.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

// Reviews for a given cyber
final cyberReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, cyberId) async {
  return ref.read(reviewRepositoryProvider).getCyberReviews(cyberId);
});

// Review notifier for creating a review
final reviewNotifierProvider =
    AsyncNotifierProvider<ReviewNotifier, void>(() => ReviewNotifier());

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitReview({
    required String cyberId,
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final user = ref.read(authStateProvider);
    if (user == null) throw Exception('Not authenticated');

    await ref.read(reviewRepositoryProvider).createReview(
          userId: user.id,
          cyberId: cyberId,
          bookingId: bookingId,
          rating: rating,
          comment: comment,
        );

    // Invalidate to refresh the reviews list
    ref.invalidate(cyberReviewsProvider(cyberId));
  }
}
