import 'package:flutter/material.dart';
import '../friends/friends.dart';
import 'chat_room_list_page.dart';

class ChatListWrapperPage extends StatefulWidget {
  final int myUserNo;
  const ChatListWrapperPage({super.key, required this.myUserNo});

  @override
  State<ChatListWrapperPage> createState() => _ChatListWrapperPageState();
}

class _ChatListWrapperPageState extends State<ChatListWrapperPage>
    with SingleTickerProviderStateMixin {

  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("채팅"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "채팅방"),
            Tab(text: "친구"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ChatRoomListPage(myUserNo: widget.myUserNo),
          FriendsPage(myUserNo: widget.myUserNo),
        ],
      ),
    );
  }
}
