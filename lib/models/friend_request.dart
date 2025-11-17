// lib/models/friend_request.dart

class FriendRequest {
  final int frenNo;
  final int frenStatus;
  final String frenUpdate;
  final int offer;
  final int receiver;
  final String friendName;

  FriendRequest({
    required this.frenNo,
    required this.frenStatus,
    required this.frenUpdate,
    required this.offer,
    required this.receiver,
    required this.friendName,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      frenNo: json['frenNo'] as int,
      frenStatus: json['frenStatus'] as int,
      frenUpdate: json['frenUpdate'] as String? ?? '',
      offer: json['offer'] as int,
      receiver: json['receiver'] as int,
      friendName: json['friendName'] as String? ?? '',
    );
  }
}
