// lib/pages/friends/friends.dart

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    _loadFriends();
    _loadRequests();
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
      print("서버에서 받은 요청 개수: ${list.length}");
      print("서버에서 받은 raw 데이터: $list");

      setState(() {
        _requests = list;
        print("_requests 길이: ${_requests.length}");
      });
    } catch (e) {
      _showError("요청 목록 불러오기 실패\n$e");
    } finally {
      setState(() => _loadingRequests = false);
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
      await _api.addFriend(
        offer: widget.myUserNo,
        email: email,
      );
      _showSnack("친구 요청을 보냈습니다.");
      _loadRequests();
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
      // 친구 목록 갱신
      await _loadFriends();
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
          _requests
              .removeWhere((e) => e.offer == r.offer && e.receiver == r.receiver);
        });
      } else {
        _showError("이미 처리된 요청이거나 존재하지 않습니다.");
      }
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 테마 기반 배경 (라이트/다크 둘 다)
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("친구"),
        // AppBar 도 테마 배경 사용
        backgroundColor: bg,
        elevation: 0,
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
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
            Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: "친구 목록"),
              Tab(text: "받은 요청"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 친구 목록 UI
  Widget _buildFriendsTab() {
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return const Center(child: Text("친구가 없습니다."));
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (_, i) {
          final f = _friends[i];

          return ListTile(
            title: Text(f.friendName),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _delete(f),
            ),
          );
        },
      ),
    );
  }

  // 요청 목록 UI
  Widget _buildRequestsTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(child: Text("받은 요청이 없습니다."));
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (_, i) {
          final r = _requests[i];

          return ListTile(
            title: Text(r.friendName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 수락
                IconButton(
                  onPressed: () => _accept(r),
                  icon: const Icon(Icons.check, color: Colors.green),
                ),
                // 거절
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _refusal(r),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
