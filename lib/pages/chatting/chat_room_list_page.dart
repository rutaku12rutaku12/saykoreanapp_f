// lib/pages/chatting/chat_room_list_page.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../api/chatting_api.dart';
import 'chat_page.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatRoomListPage extends StatefulWidget {
  final int myUserNo;

  const ChatRoomListPage({
    super.key,
    required this.myUserNo,
  });

  @override
  State<ChatRoomListPage> createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  final api = ChattingApi();
  List<Map<String, dynamic>> rooms = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadRooms();
  }

  // 탭 다시 들어올 때 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadRooms();
  }

  Future<void> loadRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await api.getMyRooms(widget.myUserNo);
      if (!mounted) return;
      setState(() => rooms = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "chat.list.error".tr());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: loadRooms,
              child: Text("common.retry".tr()),
            ),
          ],
        ),
      );
    } else if (rooms.isEmpty) {
      body = Center(
        child: Text("chat.list.empty".tr()),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = rooms[i];
          final friendName =
              r['friendName']?.toString() ?? "chat.user.unknown".tr();
          final lastMessage =
          (r['lastMessage']?.toString().isNotEmpty ?? false)
              ? r['lastMessage'].toString()
              : "chat.none".tr();
          final lastTime = r['lastTime']?.toString() ?? '';

          return _ChatRoomTile(
            friendName: friendName,
            lastMessage: lastMessage,
            lastTime: lastTime,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    roomNo: r['roomNo'],
                    friendName: friendName,
                    myUserNo: widget.myUserNo,
                    // 메시지 전송 후 리스트 갱신
                    onMessageSent: loadRooms,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: loadRooms,
      child: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 개별 채팅방 타일 UI
// ─────────────────────────────────────────────────────────────

class _ChatRoomTile extends StatelessWidget {
  final String friendName;
  final String lastMessage;
  final String lastTime;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.friendName,
    required this.lastMessage,
    required this.lastTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;

    final cardColor = scheme.surface;
    final titleColor = scheme.onSurface;
    final subtitleColor = scheme.onSurfaceVariant;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            children: [
              // 프로필 동그라미
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.secondaryContainer,
                child: Text(
                  friendName.isNotEmpty ? friendName[0] : '?',
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 이름 + 마지막 메시지
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
// 시간
              Text(
                lastTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  fontSize: 11,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
