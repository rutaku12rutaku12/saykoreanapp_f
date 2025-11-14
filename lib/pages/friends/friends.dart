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

  // 친구 목록 (frenStatus == 1)
  Future<void> _loadFriends() async{
    setState(() => _loadingFriends = true);
    try{
      final list = await _api.getFriendList(userNo: widget.myUserNo);
      setState(() {
        _friends = list.where((e) => e.frenStatus == 1).toList();
      });
    }catch(e){
      _showError("친구 목록 불러오기 실패\n$e");
    }finally{
      setState(() => _loadingFriends = false);
      }
    }


  // 요청 목록 (내가 receiver 이고 frenStatus==0)
  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final list = await _api.getFriendList(userNo: widget.myUserNo);

      setState(() {
        _requests = list
            .where((e) =>
        e.frenStatus == 0 &&
            e.receiver == widget.myUserNo) // 내가 받은 요청만
            .map((e) => FriendRequest(
          frenNo: e.frenNo,
          frenStatus: e.frenStatus,
          frenUpdate: e.frenUpdate,
          offer: e.offer,
          receiver: e.receiver,
        )).toList();
      });
    } catch (e) {
      _showError("요청 목록 불러오기 실패\n$e");
    } finally {
      setState(() => _loadingRequests = false);
    }
  }


  // 친구 요청 보내기
  Future<void> _sendRequest() async{
    TextEditingController receiverCtl = TextEditingController();

    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("친구 요청"),
          content: TextField(
            controller: receiverCtl,
            decoration: const InputDecoration(
              labelText: "상대방 userNo",
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("보내기")),
          ],
        ),
    );

    if(ok != true) return;

    final receiver = int.tryParse(receiverCtl.text.trim());
    if(receiver == null){
      _showError("정확한 유저 번호를 입력하세요");
      return;
    }
    try{
      await _api.addFriend(offer: widget.myUserNo, receiver: receiver);
      _showSnack("친구 요청을 보냈습니다.");
      _loadRequests();
    }catch(e){_showError("친구 요청 실패\n$e");
    }
  }

  // 요청 수락
  Future<void> _accept(FriendRequest req) async {
    try {
      await _api.acceptFriend(offer: req.offer, receiver: widget.myUserNo);
      _showSnack('친구 요청을 수락했습니다.');
      await _loadFriends();
      await _loadRequests();
    } catch (e) {
      _showError('요청 수락에 실패했습니다.\n$e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("친구"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _sendRequest,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "친구 목록"),
            Tab(text: "받은 요청"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
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

          final int friendUserNo =
          f.offer == widget.myUserNo ? f.receiver : f.offer;

          return ListTile(
            title: Text("유저번호 : $friendUserNo"),
            subtitle: Text("업데이트 : ${f.frenUpdate}"),
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
            title: Text("보낸 사람 userNo : ${r.offer}"),
            subtitle: Text("상태 : 요청중"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, //
              children: [
                //수락
                IconButton(onPressed: () => _accept(r), icon: const Icon(Icons.check, color: Colors.green)
                ),
                //거절
                IconButton(icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    try {
                      await _api.deleteFriend(
                      offer: r.offer,
                      receiver: widget.myUserNo,
                      );
                      _showSnack("요청을 거절했습니다.");
                      _loadRequests();
                      } catch (e) {
                      _showError("거절 실패\n$e");
                    }
                  },
                )
              ],
            )
          );
        },
      ),
    );
  }
}
