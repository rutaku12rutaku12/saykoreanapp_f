import 'package:flutter/material.dart';
import '../../api/chatting_api.dart';
import '../../models/chat_room.dart';

class ChatRoomListPage extends StatefulWidget {
  final int myUserNo;
  const ChatRoomListPage({super.key, required this.myUserNo});

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  final api = ChattingApi();
  List<Map<String,dynamic>> rooms = [];

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  Future<void> loadRooms() async {
    if (!mounted) return;
    try {
      final list = await api.getMyRooms(widget.myUserNo);
      if (!mounted) return;
      setState(() => rooms = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: loadRooms,
        child: ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (_, i) {
            final r = rooms[i];
            return ListTile(
              title: Text(r['friendName']),
              subtitle: Text(r['lastMessage'] ?? '대화 없음'),
              trailing: Text(r['lastTime'] ?? ''),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/chatRoom",
                  arguments: {
                    "roomNo": r['roomNo'],
                    "friendName": r['friendName'],
                    "friendNo": r['friendNo'],
                    "myUserNo" : widget.myUserNo, //중요
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
