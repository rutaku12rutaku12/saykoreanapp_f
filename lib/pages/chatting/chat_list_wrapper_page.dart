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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "채팅",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),

        bottom: TabBar(
          controller: _tab,

          // 여기서 색 통일
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor:
          Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.5),

          indicatorColor: Theme.of(context).appBarTheme.foregroundColor,

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
