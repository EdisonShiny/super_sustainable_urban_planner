import '../../auth/models/access_level.dart';
import 'leader_reply.dart';

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.accessLevel,
    required this.city,
    required this.text,
    required this.rating,
    required this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String userId;
  final String username;
  final AccessLevel accessLevel;
  final String city;
  final String text;
  final int rating;
  final DateTime createdAt;
  final List<LeaderReply> replies;

  FeedbackEntry copyWith({List<LeaderReply>? replies}) {
    return FeedbackEntry(
      id: id,
      userId: userId,
      username: username,
      accessLevel: accessLevel,
      city: city,
      text: text,
      rating: rating,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    final rawReplies = map['replies'];
    final parsedReplies = <LeaderReply>[];
    if (rawReplies is List) {
      for (final item in rawReplies) {
        if (item is LeaderReply) {
          parsedReplies.add(item);
        } else if (item is Map<String, dynamic>) {
          parsedReplies.add(LeaderReply.fromMap(item));
        }
      }
    }

    return FeedbackEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String,
      accessLevel: AccessLevelX.fromString(map['access_level'] as String),
      city: map['city'] as String,
      text: map['text'] as String,
      rating: (map['rating'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      replies: parsedReplies,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'username': username,
      'access_level': accessLevel.value,
      'city': city,
      'text': text,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
