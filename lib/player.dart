import 'package:cloud_firestore/cloud_firestore.dart';

class Player {
  final String uid;
  final String displayName;
  final DateTime createdAt;
  final DateTime? marriedAt;
  final String? marriedTo;
  final Map<String, dynamic> stats;
  final int coins;

  Player({
    required this.uid,
    required this.displayName,
    required this.createdAt,
    required this.marriedAt,
    required this.marriedTo,
    required this.stats,
    required this.coins,
  });

  factory Player.fromJson(Map<String, dynamic> map) {
    return Player(
      uid: map['uid'] ?? '',
      displayName: map['display_name'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
      marriedAt: (map['married_at'] as Timestamp?)?.toDate(),
      stats: map['stats'] ?? {},
      coins: map['coins'] ?? 0,
      marriedTo: map['married_to'],
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'display_name': displayName,
        'created_at': Timestamp.fromDate(createdAt),
        'stats': stats,
        'coins': coins,
      };
}
