// lib/models/friend.dart

class Friend {
  final int frenNo;
  final int frenStatus;
  final String frenUpdate;
  final int offer;
  final int receiver;
  final String friendName;

  Friend({
    required this.frenNo,
    required this.frenStatus,
    required this.frenUpdate,
    required this.offer,
    required this.receiver,
    required this.friendName,

  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      frenNo: json['frenNo'] as int,
      frenStatus: json['frenStatus'] as int,
      frenUpdate: json['frenUpdate'] as String? ?? '',
      offer: json['offer'] as int,
      receiver: json['receiver'] as int,
      friendName: json['friendName'] as String? ?? '',
    );
  }
}
