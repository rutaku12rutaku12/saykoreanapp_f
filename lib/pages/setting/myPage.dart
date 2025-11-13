import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/genre.dart';
import 'package:saykoreanapp_f/pages/setting/language.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';

// ─────────────────────────────────────────────────────────────────────────────

class Mypage extends StatelessWidget {
  const Mypage({super.key});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);
    const bg = Color(0xFFFFF9F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "마이페이지",
          style: TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: brown),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 인사/타이틀 영역
              const Text(
                "내 계정",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "프로필과 학습 환경을 한 곳에서 관리해요.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
              const SizedBox(height: 20),

              // 1. 계정 설정 카드
              _SectionTitle("계정 설정"),
              const SizedBox(height: 8),
              _SettingCard(
                icon: Icons.person_outline,
                title: "정보 수정",
                subtitle: "닉네임, 이메일, 비밀번호 등을 변경할 수 있어요.",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyInfoUpdatePage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 2. 학습 설정 카드들
              _SectionTitle("학습 설정"),
              const SizedBox(height: 8),
              _SettingCard(
                icon: Icons.category_outlined,
                title: "장르 설정",
                subtitle: "관심 있는 학습 주제를 선택해요.",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GenrePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _SettingCard(
                icon: Icons.language_outlined,
                title: "언어 설정",
                subtitle: "앱에서 사용할 학습 언어를 바꿔요.",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguagePage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 3. 학습 기록 / 완수 목록
              _SectionTitle("학습 기록"),
              const SizedBox(height: 8),
              _SettingCard(
                icon: Icons.emoji_events_outlined,
                title: "완수한 주제 목록",
                subtitle: "지금까지 끝낸 학습 주제를 다시 확인해요.",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuccessListPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 작은 컴포넌트들
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7C5A48),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5CF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: brown, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9C7C68),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB89C8A),
            )
          ],
        ),
      ),
    );
  }
}
