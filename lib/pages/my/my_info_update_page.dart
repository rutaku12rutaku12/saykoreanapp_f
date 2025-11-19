import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:saykoreanapp_f/api.dart';

class MyInfoUpdatePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InfoUpdateState();
    }
}

class _InfoUpdateState extends State<MyInfoUpdatePage>{

  // 입력창 텍스트 컨트롤러
  TextEditingController nameCon = TextEditingController();
  TextEditingController nickCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();
  TextEditingController currentPassCon = TextEditingController();
  TextEditingController newPassCon = TextEditingController();
  TextEditingController checkPassCon = TextEditingController();

  // 중복검사 상태관리
  bool phoneCheck = false;

  // 서버 전송용 국제번호 저장 변수
  PhoneNumber? emailPhoneNumber;

  // 전화번호 중복 확인 메소드
  void checkPhone () async{
    try{
      final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
      final response = await ApiClient.dio.get(
          "/saykorean/checkphone",
          options: Options(
            validateStatus: (status) => true,
          ),
          queryParameters: { 'phone' : plusPhone }
      );
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");
      if(response.statusCode == 200 && response.data != null && response.data == 0){
        setState(() {
          phoneCheck=true;
        });
        Fluttertoast.showToast(msg: "전화번호 사용이 가능합니다.", backgroundColor: Colors.greenAccent);
      }else{Fluttertoast.showToast(msg: "전화번호 형식이 올바르지 않거나, 사용 중인 전화번호입니다.", backgroundColor: Colors.red);}
    }catch(e){
      print(e);}
  }

  // 사용자 정보 수정 메소드
  void updateUserInfo () async {
      if(nameCon.text.trim().isEmpty ||
          nickCon.text.trim().isEmpty ||
          phoneCon.text.trim().isEmpty)
        { Fluttertoast.showToast(msg: "입력값을 채워주세요.",backgroundColor: Colors.red);
          print("입력값을 채워주세요.");
        return;}
    try{
      final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
      final sendData = {"name": nameCon.text,"nickName":nickCon.text,"phone":plusPhone };
      print(sendData);
      final response = await ApiClient.dio.put(
        "/saykorean/updateuserinfo",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print(response);
      print(response.data);
      if(response.statusCode == 200 && response.data != null && response.data){
      Fluttertoast.showToast(msg: "수정이 완료되었습니다.",backgroundColor: Colors.greenAccent);}
      else{Fluttertoast.showToast(msg: "수정이 실패했습니다. 올바른 값을 넣어주세요.",backgroundColor: Colors.greenAccent);}
    }catch(e){print(e);}
  }

  // 비밀번호 수정 메소드
  void updatePwrd () async {
    if(currentPassCon.text.trim().isEmpty ||
    newPassCon.text.trim().isEmpty ||
    checkPassCon.text.trim().isEmpty)
    { Fluttertoast.showToast(msg: "입력값을 채워주세요.",backgroundColor: Colors.red);
    print("입력값을 채워주세요.");
    return;}
    // if (newPassword != checkPassword) { return alert(t("myinfoupdate.checkNewPassword")) }
    if( newPassCon.text != checkPassCon.text ){
      print("비밀번호 불일치 , 새 비밀번호: ${newPassCon.text}, 비밀번호 확인: ${checkPassCon.text} ");
      Fluttertoast.showToast(msg: "비밀번호가 다릅니다. 다시 확인해주세요.",backgroundColor: Colors.red);
      return; 
    }
    try{
      final sendData = {"currentPassword":currentPassCon.text,"newPassword":newPassCon.text};
      final response = await ApiClient.dio.put(
        "/saykorean/updatepwrd",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
    }catch(e){print(e);}
  }
  // 탈퇴 메소드
  void deleteUserStatus () async {
    try{

    }catch(e){print(e);}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("정보 수정 페이지"),),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("사용자 정보 수정"),
              SizedBox(height: 20,),

              TextField(controller: nameCon,
                decoration: InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  )
                ),),
              SizedBox(height: 10,),

              TextField(controller: nickCon,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  )
                ),),
              SizedBox(height: 10,),

              IntlPhoneField(
                controller: phoneCon,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                initialCountryCode: 'KR',
                autovalidateMode: AutovalidateMode.disabled,
                validator: (value) => null, // 자리수 검증 제거// ,
                onChanged: (phone) {
                  emailPhoneNumber = phone;
                  print("입력한 번호: ${phone.number}");
                }, // 입력 위젯, 전화번호
              ),
              ElevatedButton(onPressed: checkPhone, child: Text("중복 확인")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: updateUserInfo, child: Text("수정")),
              SizedBox(height: 30,),

              Text("비밀번호 수정"),
              TextField(
                controller: currentPassCon,
                obscureText: true, // 비번 가리기
                decoration: InputDecoration(
                  labelText: "기존 비밀번호", border: OutlineInputBorder()),
                ),
              SizedBox(height: 10,),
              TextField(
                controller: newPassCon,
                obscureText: true, // 비번 가리기
                decoration: InputDecoration(
                    labelText: "새 비밀번호", border: OutlineInputBorder()),
                ),
              SizedBox(height: 10,),
              TextField(
                controller: checkPassCon,
                obscureText: true, // 비번 가리기
                decoration: InputDecoration(
                    labelText: "새 비밀번호 확인", border: OutlineInputBorder()),
                ),
              SizedBox(height: 10,),
              ElevatedButton(onPressed: updatePwrd, child: Text("수정")),              SizedBox(height: 30,),

              Text("회원 탈퇴"),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: deleteUserStatus, child: Text("탈퇴"))
            ],
          ),
        ),
      ),
    );
  }
}