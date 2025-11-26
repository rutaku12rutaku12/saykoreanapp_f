import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../api/chatting_api.dart';

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
  WebSocketChannel? _channel;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  bool _loadingHistory = true;
  final api = ChattingApi();

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    try {
      _channel?.sink.close();
    } catch (_) {}

    final wsUrl =
        "${ApiClient.detectWsUrl()}?roomNo=${widget.roomNo}&userNo=${widget.myUserNo}";
    // ignore: avoid_print
    print("WebSocket connect: $wsUrl");

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);
        final type = decoded["type"] ?? "";

        // 🔥 HISTORY 수신
        if (type == "HISTORY") {
          final list = decoded["messages"] ?? [];

          setState(() {
            _loadingHistory = false;
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

        // 🔥 실시간 메시지 수신
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
        // ignore: avoid_print
        print("⚠ 소켓 종료됨 → 자동 재연결");
        Future.delayed(const Duration(seconds: 1), _connectSocket);
      },
      onError: (e) {
        // ignore: avoid_print
        print("⚠ 소켓 오류: $e");
        Future.delayed(const Duration(seconds: 1), _connectSocket);
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  // 메시지 전송
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_channel == null) {
      print("❌ 소켓 연결 안 됨");
      return;
    }

    final payload = {
      "type": "chat",
      "roomNo": widget.roomNo,
      "userNo": widget.myUserNo,
      "message": text
    };

    try {
      _channel!.sink.add(jsonEncode(payload));
      _controller.clear();

      // 스크롤 아래로
      _scrollToBottom();

      // 부모에게 알려줄 필요 있을 때
      widget.onMessageSent?.call();

    } catch (e) {
      print("❌ 메시지 전송 오류: $e");
      _connectSocket(); // 자동 재연결
    }
  }

  // 메시지 신고 기능
  Future<void> _reportMessage(Map<String, dynamic> message) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("메시지 신고"),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "신고 사유를 입력해주세요.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text("신고"),
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
        const SnackBar(content: Text("신고가 접수되었습니다.")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("신고 중 오류가 발생했습니다.")),
      );
    }
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    // 테마/민트/다크에 따라 자동으로 맞춰지는 컬러들
    final myBubbleBg =
    isDark ? scheme.primaryContainer : scheme.secondaryContainer;
    final myBubbleFg =
    isDark ? scheme.onPrimaryContainer : scheme.onSecondaryContainer;

    final otherBubbleBg =
    isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final otherBubbleFg = scheme.onSurface;
    final timeColor = scheme.onSurface.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.friendName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: _loadingHistory && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m['sendNo'] == widget.myUserNo;

                final bubbleBg = isMe ? myBubbleBg : otherBubbleBg;
                final bubbleFg = isMe ? myBubbleFg : otherBubbleFg;

                return GestureDetector(
                  onLongPress: () => _reportMessage(m),
                  child: Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: bubbleBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                Radius.circular(isMe ? 16 : 4),
                                bottomRight:
                                Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              m['message'] ?? '',
                              style:
                              theme.textTheme.bodyMedium?.copyWith(
                                color: bubbleFg,
                              ),
                            ),
                          ),
                          if ((m['time'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 2, left: 4, right: 4),
                              child: Text(
                                m['time'].toString(),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: timeColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 입력창
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  /// === ✨ 엔터 전송 + Shift+Enter 줄바꿈 기능 포함 ===
                  Expanded(
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) {
                        if (event is RawKeyDownEvent) {
                          // 엔터 → 메시지 전송
                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                              !event.isShiftPressed) {
                            _sendMessage();
                            return; // 줄바꿈 방지
                          }
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "메시지를 입력하세요",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: scheme.primary,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  /// === 전송 버튼 ===
                  IconButton(
                    icon: Icon(Icons.send, color: scheme.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
