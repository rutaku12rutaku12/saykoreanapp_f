class ChatRoom {
  final int roomNo;
  final String friendName;
  final int friendNo;
  final String? lastMessage;
  final String? lastTime;

  ChatRoom({
    required this.roomNo,
    required this.friendName,
    required this.friendNo,
    this.lastMessage,
    this.lastTime,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomNo: json['roomNo'],
      friendName: json['friendName'],
      friendNo: json['friendNo'],
      lastMessage: json['lastMessage'],
      lastTime: json['lastTime'],
    );
  }
}
