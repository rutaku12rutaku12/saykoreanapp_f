class Message {
  final int sendNo;
  final String message;
  final String time;

  Message({
    required this.sendNo,
    required this.message,
    required this.time,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sendNo: json['sendNo'],
      message: json['chatMessage'],
      time: json['chatTime'],
    );
  }
}
