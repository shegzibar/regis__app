import '../models/review.dart';
import '../supabase/supabase_client.dart';

class ReviewRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get reviews for a cyber
  Future<List<Review>> getCyberReviews(String cyberId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('cyber_id', cyberId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((review) => Review.fromMap(review))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cyber reviews: $e');
    }
  }

  // Get user reviews
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((review) => Review.fromMap(review))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  // Get review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('id', reviewId)
          .maybeSingle();

      if (response != null) {
        return Review.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch review: $e');
    }
  }

  // Create review
  Future<Review> createReview({
    required String userId,
    required String cyberId,
    String? bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final reviewData = {
        'user_id': userId,
        'cyber_id': cyberId,
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('reviews').insert(reviewData).select().single();

      return Review.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Update review
  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;

      final response = await _supabase
          .from('reviews')
          .update(updateData)
          .eq('id', reviewId)
          .select()
          .single();

      return Review.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get average rating for a cyber
  Future<double> getCyberAverageRating(String cyberId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('cyber_id', cyberId);

      if ((response as List).isEmpty) {
        return 0.0;
      }

      final ratings = (response as List)
          .map((item) => (item['rating'] as int).toDouble())
          .toList();

      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(2));
    } catch (e) {
      throw Exception('Failed to calculate average rating: $e');
    }
  }

  // Get review count for a cyber
  Future<int> getCyberReviewCount(String cyberId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('cyber_id', cyberId)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to get review count: $e');
    }
  }

  // Check if user has reviewed a cyber
  Future<bool> hasUserReviewedCyber(String userId, String cyberId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .eq('cyber_id', cyberId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check user review: $e');
    }
  }
}
