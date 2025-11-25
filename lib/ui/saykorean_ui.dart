// lib/ui/saykorean_ui.dart
import 'package:flutter/material.dart';

/// 로그아웃 / 학습완료 등에 쓰는 연살구색 버튼 컬러
const Color skButtonBg = Color(0xFFFFE5CF); // 🔸 로그아웃 버튼이랑 같은 톤
const Color skButtonFg = Color(0xFF6B4E42);

// 상단 큰 제목 + 작은 설명
class SKPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SKPageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = theme.appBarTheme.foregroundColor
        ?? (isDark ? scheme.onSurface : const Color(0xFF6B4E42));
    final subtitleColor =
    isDark ? scheme.onSurface.withOpacity(0.7) : const Color(0xFF9C7C68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// 연살구색 기본 버튼 (로그아웃/학습완료/확인 등 공통)
class SKPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SKPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? scheme.primaryContainer : skButtonBg;
    final fg = isDark ? scheme.onPrimaryContainer : skButtonFg;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
