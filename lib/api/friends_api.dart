// lib/api/friends_api.dart

import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../api.dart';

class FriendsApi {
  final Dio _dio = ApiClient.dio;

  /// 친구 요청
  ///
  /// POST /friends/add?offer=1&receiver=2
  Future<void> addFriend({
    required int offer,
    required int receiver,
  }) async {
    await _dio.post(
      "/friends/add",
      queryParameters: {
        "offer": offer,
        "receiver": receiver,
      },
    );
  }

  /// 친구 수락
  ///
  /// PUT /friends/accept?offer=1&receiver=2
  Future<void> acceptFriend({
    required int offer,
    required int receiver,
  }) async {
    await _dio.put(
      "/friends/accept",
      queryParameters: {
        "offer": offer,
        "receiver": receiver,
      },
    );
  }

  /// 친구 거절
  Future<bool> refusalFriend({
    required int offer, required int receiver,
  }) async {
    final res = await _dio.delete("/refusal",
        queryParameters: {"offer" : offer, "receiver" :receiver});
    return res.data == true;
  }

  /// 친구 삭제
  Future<void> deleteFriend({
    required int offer,
    required int receiver,
  }) async {
    await _dio.delete(
      "/friends/delete",
      queryParameters: {
        "offer": offer,
        "receiver": receiver,
      },
    );
  }

  /// 친구 차단
  Future<void> blockFriend({
    required int offer,
    required int receiver,
  }) async {
    await _dio.delete(
      "/friends/block",
      queryParameters: {
        "offer": offer,
        "receiver": receiver,
      },
    );
  }

  //요청 목록
  Future<List<FriendRequest>> fetchRequests(int myUserNo) async {
    final res = await _dio.get(
      "/friends/requests/recv",
      queryParameters: {"userNo": myUserNo},
    );

    print("서버 응답 : ${res.data}");

    return (res.data as List)
        .map((e) => FriendRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 친구 목록 조회
  ///
  /// PUT /friends/list?userNo=1
  /// -> List<FriendsDto>
  Future<List<Friend>> getFriendList({
    required int userNo,
  }) async {
    final res = await _dio.put(
      "/friends/list",
      queryParameters: {
        "userNo": userNo,
      },//
    );
    print("서버 응답: ${res.data}");

    final list = res.data as List;

    return list.map((item){
      final friendJson = item["friend"]; // 이걸 꺼내야한다고 함
      return Friend.fromJson(friendJson); // 여기에 넣어야 제대로 읽힌다고 함
    }).toList();
  }
}
