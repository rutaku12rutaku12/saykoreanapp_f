import 'package:dio/dio.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../api.dart';

class ChattingApi {
  final Dio _dio = ApiClient.dio;

  Future<List<ChatRoom>> getMyRooms(int userNo) async {
    final res = await _dio.get("/chat/rooms?userNo=$userNo");
    final list = res.data as List;
    return list.map((e) => ChatRoom.fromJson(e)).toList();
  }

  Future<List<Message>> getMessages(int roomNo) async {
    final res = await _dio.get("/chat/messages?roomNo=$roomNo");
    final list = res.data as List;
    return list.map((e) => Message.fromJson(e)).toList();
  }
}
