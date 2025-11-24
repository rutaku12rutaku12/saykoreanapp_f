import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../api/chatting_api.dart';  // 🔥 신고 API 사용

class ChatPage extends StatefulWidget {
  final int roomNo;
  final String friendName;
  final int myUserNo;
  final VoidCallback? onMessageSent;

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
  late WebSocketChannel _channel;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  bool _loadingHistory = true; // HISTORY 도착 전 로딩 표시
  final api = ChattingApi();   // 🔥 신고 API 인스턴스 추가

  @override
  void initState() {
    super.initState();
    _connectSocket(); // 첫 연결
  }

  void _connectSocket() {
    // 혹시 기존 소켓이 남아있으면 강제로 닫고 재연결
    try{
      _channel?.sink.close();
    }catch(_){}
    //-----------------------------
    final wsUrl =
        "${ApiClient.detectWsUrl()}?roomNo=${widget.roomNo}&userNo=${widget.myUserNo}";
    print("WebSocket connect: $wsUrl");

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final type = decoded["type"] ?? "";

        // -------------------------------
        // HISTORY mode
        // -------------------------------
        if (type == "HISTORY") {
          final list = decoded["messages"] ?? [];

          setState(() {
            _loadingHistory = false; // 로딩 종료
            _messages.clear();

            for (final m in list) {
              _messages.add({
                "messageNo": m["messageNo"],
                "sendNo": m["sendNo"],
                "message": m["chatMessage"],
                "time": m["chatTime"] ?? "",
              });
            }
          });

          _scrollToBottom();
          return;
        }

        // -------------------------------
        // 실시간 메시지
        // -------------------------------
        if (type == "chat") {
          setState(() {
            _messages.add({
              "messageNo": decoded["messageNo"],
              "sendNo": decoded["sendNo"],
              "message": decoded["message"] ?? "",
              "time": decoded["time"] ?? "",
            });
          });

          widget.onMessageSent?.call();
          _scrollToBottom();
        }
      },
      onDone: () {
        print("⚠ 소켓 종료됨 → 자동 재연결 시도");
        Future.delayed(Duration(seconds: 1), _connectSocket);
      },
      onError: (e) {
        print("⚠ 소켓 오류: $e");
        Future.delayed(Duration(seconds: 1), _connectSocket);
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    try{
      _channel?.sink.close();
    }catch(_){}
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------
  // 메시지 전송
  // -------------------------------
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final payload = {
      "type" : "chat",
      "roomNo" : widget.roomNo, //채팅방 번호
      "userNo" : widget.myUserNo, // 내 userNo
      "message": text //보낼 메시지
    };
    _channel.sink.add(jsonEncode(payload));

    _controller.clear();
  }

  // -------------------------------
  // 메시지 신고 기능
  // -------------------------------
  Future<void> _reportMessage(Map<String, dynamic> message) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("메시지 신고"),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(hintText: "신고 사유를 입력해주세요."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: Text("신고"),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await api.reportMessage(
        messageNo: message['messageNo'],
        reporterNo: widget.myUserNo,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("신고가 접수되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("신고 중 오류가 발생했습니다.")),
      );
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m['sendNo'] == widget.myUserNo;

                return GestureDetector(
                  onLongPress: () => _reportMessage(m),   // 🔥 길게 눌러 신고
                  child: Align(
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
                  ),
                );
              },
            ),
          ),

          // 입력창
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "메시지 입력",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
