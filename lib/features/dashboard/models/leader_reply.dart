class LeaderReply {
  const LeaderReply({
    required this.id,
    required this.feedbackId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String feedbackId;
  final String username;
  final String text;
  final DateTime createdAt;

  factory LeaderReply.fromMap(Map<String, dynamic> map) {
    return LeaderReply(
      id: map['id'] as String,
      feedbackId: map['feedback_id'] as String,
      username: map['username'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'feedback_id': feedbackId,
      'username': username,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}


