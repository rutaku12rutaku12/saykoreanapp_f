import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatPage extends StatefulWidget {
  final int roomNo;
  final String friendName;
  final int myUserNo;

  final VoidCallback? onMessageSent; //

  const ChatPage({
    super.key,
    required this.roomNo,
    required this.friendName,
    required this.myUserNo,
    this.onMessageSent,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scroll = ScrollController();
  late WebSocketChannel _channel;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();

    // WebSocket URL 생성
    final wsUrl =
        "${ApiClient.detectWsUrl()}?roomNo=${widget.roomNo}&userNo=${widget
        .myUserNo}";
    print("WebSocket Connect URL : $wsUrl");

    // WebSocket 연결
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    //메시지 수신 리스너
    _channel.stream.listen((data) {
      final decoded = jsonDecode(data as String);

      final type = decoded["type"] ?? "";

      //히스토리 처리
      if (type == "HISTORY") {
        final List<dynamic> list = decoded["messages"] ?? [];

        setState(() {
          _messages.clear();
          _messages.addAll(
            list.map((e) =>
            {
              'messageNo': e['messageNo'],
              'sendNo': e['sendNo'],
              'message': e['chatMessage'],
              'time': e['chatTime'],
            }),
          );
        });
        _scrollToBottom();
        return;
      }

      // 실시간 메세지
      if (type == "CHAT") {
        setState(() {
          _messages.add({
            'messageNo': decoded['messageNo'],
            'sendNo': decoded['sendNo'],
            'message': decoded['message'],
            'time': decoded['time']
          });
        });
        // ChatRoomListPage 갱신 요청
        widget.onMessageSent?.call();

        _scrollToBottom();
      }
    });
  }

      // 자동 스크롤 맨 알래로
      void _scrollToBottom() {
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }

      // // 새로운 메시지 알림
      // if(decoded["type"] == "message" &&
      // decoded["sendNo"] != widget.myUserNo){
      //   _showNewMessageToast();
      // }
    });
  }
//----------------------------------------------
  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 서버는 "message"로 받음 (content x)
    final payload = {
      "message" : text,
    };

    _channel.sink.add(jsonEncode(payload));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m['sendNo'] == widget.myUserNo;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pink[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m['message'] ?? ''),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '메시지 입력',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
