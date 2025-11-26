// lib/pages/friends/friends.dart

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';
import '../../api/friends_api.dart';
import '../../models/friend.dart';
import '../../models/friend_request.dart';

class FriendsPage extends StatefulWidget {
  final int myUserNo;
  const FriendsPage({super.key, required this.myUserNo});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsApi _api = FriendsApi();

  // 친구 목록 탭 상태
  List<Friend> _friends = [];
  bool _loadingFriends = false;

  // 요청 관리 탭 상태
  List<FriendRequest> _requests = [];
  bool _loadingRequests = false;

  // 요청 보낸 목록 탭 상태
  List<FriendRequest> _sentRequests = [];
  bool _loadingSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    _loadFriends();
    _loadRequests(); // 받은요청
    _loadSentRequests(); // 보낸요청
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 친구 목록 (frenStatus == 1)
  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final list = await _api.getFriendList(userNo: widget.myUserNo);
      // ignore: avoid_print
      print("최종 파싱된 Friend 리스트:");
      setState(() {
        _friends = list;
      });
    } catch (e) {
      _showError("친구 목록 불러오기 실패\n$e");
    } finally {
      setState(() => _loadingFriends = false);
    }
  }

  // 요청 목록 (내가 receiver 이고 frenStatus==0)
  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final list = await _api.fetchRequests(widget.myUserNo);
      // ignore: avoid_print
      print("서버에서 받은 요청 개수: ${list.length}");
      // ignore: avoid_print
      print("서버에서 받은 raw 데이터: $list");

      setState(() {
        _requests = list;
        // ignore: avoid_print
        print("_requests 길이: ${_requests.length}");
      });
    } catch (e) {
      _showError("요청 목록 불러오기 실패\n$e");
    } finally {
      setState(() => _loadingRequests = false);
    }
  }

  // 보낸 요청 목록
  Future<void> _loadSentRequests() async {
    setState(() => _loadingSent = true);
    try {
      _sentRequests = await _api.getSentRequests(widget.myUserNo);
    } finally {
      setState(() => _loadingSent = false);
    }
  }

  // 친구 요청 보내기
  Future<void> _sendRequest() async {
    final receiverCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("친구 요청"),
        content: TextField(
          controller: receiverCtl,
          decoration: const InputDecoration(
            labelText: "상대방 이메일",
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("보내기"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final email = receiverCtl.text.trim();
    if (email.isEmpty) {
      _showError("이메일을 입력하세요.");
      return;
    }

    try {
      // 서버에서 message + success 받음
      final res = await _api.addFriend(
        offer: widget.myUserNo,
        email: email,
      );

      final success = res["success"] as bool?;
      final message = res["message"] as String?;

      // message가 있으면 Alert 또는 SnackBar로 표시
      if (message != null && message.isNotEmpty) {
        if (success == true) {
          _showSnack(message);
        } else {
          _showError(message);
        }
      }

      // 요청 갱신
      if (success == true) {
        _loadFriends();
        _loadRequests();
        _loadSentRequests();
      }
    } catch (e) {
      _showError("친구 요청 실패\n$e");
    }
  }

  // 요청 수락
  Future<void> _accept(FriendRequest r) async {
    try {
      await _api.acceptFriend(offer: r.offer, receiver: widget.myUserNo);
      _showSnack('친구 요청을 수락했습니다.');

      // 화면 상태에서 즉시 제거
      setState(() {
        _requests.removeWhere((e) => e.frenNo == r.frenNo);
      });
      // 친구 목록 및 요청들 갱신
      await _loadFriends();
      await _loadRequests();
      await _loadSentRequests();
    } catch (e) {
      _showError('요청 수락에 실패했습니다.\n$e');
    }
  }

  // 거절
  Future<void> _refusal(FriendRequest r) async {
    try {
      final ok = await _api.refusalFriend(
        offer: r.offer,
        receiver: widget.myUserNo,
      );

      if (ok) {
        _showSnack("요청을 거절했습니다.");

        // 화면 상태에서 즉시 제거
        setState(() {
          _requests.removeWhere(
                  (e) => e.offer == r.offer && e.receiver == r.receiver);
        });
      } else {
        _showError("이미 처리된 요청이거나 존재하지 않습니다.");
      }
      await _loadRequests();
      await _loadSentRequests();
    } catch (e) {
      _showError("거절 실패\n$e");
    }
  }

  // 삭제
  Future<void> _delete(Friend friend) async {
    try {
      await _api.deleteFriend(offer: friend.offer, receiver: friend.receiver);
      _showSnack('친구 삭제 완료.');
      _loadFriends();
    } catch (e) {
      _showError('삭제 실패.\n$e');
    }
  }

  void _showSnack(String msg, {Color? bg, Color? fg}) {
    showFooterSnackBar(
      context,
      msg,
      backgroundColor: bg,
      foregroundColor: fg, // ✅ 이름 맞추기
    );
  }




  void _showError(String msg) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: scheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: null,
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
        actions: [
          IconButton(
            onPressed: _sendRequest,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: "친구 요청 보내기",
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          ),
          const SizedBox(height: 4),

          // 탭바
          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              indicatorColor: scheme.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: "친구 목록"),
                Tab(text: "받은 요청"),
                Tab(text: "보낸 요청"),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(context),
                _buildRequestsTab(context), // 받은 요청
                _buildSentRequestsTab(context), // 보낸 요청
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 친구 목록 UI
  Widget _buildFriendsTab(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return const Center(child: Text("친구가 없습니다."));
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final f = _friends[i];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              child: ListTile(
                title: Text(
                  f.friendName,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(f),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 받은 요청 목록 UI
  Widget _buildRequestsTab(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(child: Text("받은 요청이 없습니다."));
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _requests.length,
        itemBuilder: (_, i) {
          final r = _requests[i];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              child: ListTile(
                title: Text(
                  r.friendName,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _accept(r),
                      icon: Icon(Icons.check_circle,
                          color: scheme.primary.withOpacity(0.9)),
                      tooltip: "수락",
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel,
                          color: scheme.error.withOpacity(0.9)),
                      onPressed: () => _refusal(r),
                      tooltip: "거절",
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 보낸 요청 목록 UI
  Widget _buildSentRequestsTab(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loadingSent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentRequests.isEmpty) {
      return const Center(child: Text("보낸 친구 요청이 없습니다."));
    }

    return RefreshIndicator(
      onRefresh: _loadSentRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final item = _sentRequests[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              child: ListTile(
                title: Text(
                  item.friendName,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "요청 중",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                trailing: Icon(
                  Icons.hourglass_top,
                  color: scheme.primary.withOpacity(0.8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
