import 'package:flutter/material.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:saykoreanapp_f/api.dart';

class FindPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FindState();
  }
}

class _FindState extends State<FindPage>{
  // 1.1 이메일 찾기 입력상자 컨트롤러
  TextEditingController name1Con = TextEditingController();
  TextEditingController phone1Con = TextEditingController();
  // 1.2 비밀번호 찾기 입력상자 컨트롤러
  TextEditingController name2Con = TextEditingController();
  TextEditingController phone2Con = TextEditingController();
  TextEditingController emailCon = TextEditingController();

  // 서버 전송용 국제번호 저장 변수
  PhoneNumber? emailPhoneNumber;

  // 2. 이메일 찾기, 자바 통신
  void onFindEmail() async {
    print("onFindEmail.exe");
    try{
      final plusPhone = emailPhoneNumber?.completeNumber ?? phone1Con.text;

      final sendData = {
        "name" : name1Con.text,
        "phone" : plusPhone};
      print(sendData);
      final response = await ApiClient.dio.get(
        '/saykorean/findemail',
        queryParameters: sendData);
      print(response.data);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('찾으시는 이메일은 : ${response.data} 입니다.'),
                  duration: Duration(seconds: 15) // 스낵바 시간
              ),);
    } catch(e){print("오류발생 : 이메일 찾기 실패, $e");}
  }
  // 3. 비밀번호 찾기, 자바 통신
  void onFindPass() async{
    print("onFindPass.exe");
    try{
      final plusPhone = emailPhoneNumber?.completeNumber ?? phone2Con.text;

      final sendData = {
        "name" : name2Con.text,
        "phone" : plusPhone,
        "email" : emailCon.text};
      print(sendData);
      final response = await ApiClient.dio.get(
        '/saykorean/findpwrd',
        queryParameters: sendData);
      print(response.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('임시 비밀번호가 발급되었습니다. 임시 비밀번호 : ${response.data} 입니다. '),
                 duration: Duration(seconds: 15) // 스낵바 시간
        ),);
    }catch(e){print("오류발생 : 비밀번호 찾기 실패, $e");}
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("찾기 페이지")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("이메일 찾기"),
              SizedBox(height: 20),

              TextField(controller: name1Con,
                decoration: InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  )
                ),),
              SizedBox(height: 10,),

              IntlPhoneField(
                controller: phone1Con,
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
                },
              ),
              ElevatedButton(onPressed: onFindEmail, child: Text("이메일 찾기")),

              Text("비밀번호 찾기"),
              SizedBox(height: 20),

              TextField(controller: name2Con,
                decoration: InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  )
                ),),
              SizedBox(height: 10,),

              IntlPhoneField(
                controller: phone2Con,
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
                },
              ),
              SizedBox(height: 10,),

              TextField(controller: emailCon,
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  )
                ),),
              ElevatedButton(onPressed: onFindPass, child: Text("비밀번호 찾기")),

            ],
          ),
        ),
      ),
    );
  }
}

