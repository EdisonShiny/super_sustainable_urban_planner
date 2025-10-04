import '../../../core/services/supabase_client.dart';
import '../../auth/models/access_level.dart';
import '../../auth/models/user_profile.dart';
import '../models/feedback.dart';
import '../models/leader_reply.dart';
import 'demo_data_store.dart';

class FeedbackRepository {
  FeedbackRepository._();

  static final FeedbackRepository instance = FeedbackRepository._();

  Future<void> createFeedback({
    required UserProfile author,
    required String city,
    required String description,
    required int rating,
  }) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        await client.from('feedback').insert({
          'user_id': author.id,
          'username': author.username,
          'access_level': author.accessLevel.value,
          'city': city,
          'text': description,
          'rating': rating,
        });
        return;
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    DemoDataStore.instance.addFeedback(
      author: author,
      cityDisplayName: city,
      description: description,
      rating: rating,
    );
  }

  Future<List<FeedbackEntry>> listFeedback(String city) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('feedback')
            .select(
              'id, user_id, username, access_level, city, text, rating, created_at, leader_replies(id, feedback_id, username, text, created_at)',
            )
            .eq('city', city)
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return response.cast<Map<String, dynamic>>().map((entry) {
            final repliesData = (entry['leader_replies'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .map(LeaderReply.fromMap)
                .toList();
            return FeedbackEntry.fromMap({...entry, 'replies': repliesData});
          }).toList();
        }
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    return DemoDataStore.instance.feedbackForCity(city);
  }

  Future<LeaderReply> createReply({
    required String feedbackId,
    required UserProfile leader,
    required String replyText,
  }) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final insert = await client
            .from('leader_replies')
            .insert({
              'feedback_id': feedbackId,
              'username': leader.username,
              'text': replyText,
            })
            .select()
            .single();
        return LeaderReply.fromMap(insert);
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    return DemoDataStore.instance.addReply(
      feedbackId: feedbackId,
      leader: leader,
      replyText: replyText,
    );
  }
}
