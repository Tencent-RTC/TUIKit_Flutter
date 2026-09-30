import 'package:flutter/widgets.dart';

/// pusher 页面框架与各模块共享的视觉令牌。
///
/// 取值对齐 PC 设计稿（uikit_interaction_design/live/pc/index.html）
/// 的默认配色（:root 主题变量）与玻璃面板样式；当前为硬编码静态值，
/// 多配色主题化能力后续统一抽取。
class PusherStyle {
  PusherStyle._();

  // === 品牌与语义色（--c-*） ===
  static const Color brand = Color(0xFFE0266B);
  static const Color brand2 = Color(0xFFEB5A8F);
  static const Color accent = Color(0xFF00D1B2);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color gold = Color(0xFFFFB020);

  // === 文字色（设计稿 tailwind gray 系） ===
  static const Color textPrimary = Color(0xFFE5E7EB); // gray-200
  static const Color textSecondary = Color(0xFFD1D5DB); // gray-300
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400
  static const Color textHint = Color(0xFF6B7280); // gray-500
  static const Color textDisabled = Color(0xFF4B5563); // gray-600
  static const Color textEmphasis = Color(0xFFF3F4F6); // gray-100
  static const Color iconMuted = Color(0xFF9AA1AD); // 数据总结卡

  // === 半透明白（设计稿 white/N%） ===
  static const Color white4 = Color(0x0AFFFFFF);
  static const Color white5 = Color(0x0DFFFFFF);
  static const Color white6 = Color(0x0FFFFFFF);
  static const Color white8 = Color(0x14FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white15 = Color(0x26FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color whitePure = Color(0xFFFFFFFF);

  // === 窗口背景（--bg-*） ===
  static const Color bgBase1 = Color(0xFF060408);
  static const Color bgBase2 = Color(0xFF201628);
  static const Color bgBase3 = Color(0xFF3B2440);
  static const Color bgGlow1 = Color(0x7AFF4691); // rgba(255,70,145,0.48)
  static const Color bgGlow2 = Color(0x4D14EBC8); // rgba(20,235,200,0.3)
  static const Color shadowBlack = Color(0x42000000);
  static const Color transparent = Color(0x00000000);
  static const Color menuBg = Color(0xD9211E2E); // 菜单底 #211E2E 85%

  /// 玻璃面板：rgba(35,33,48,0.4) 底 + 白 10% 描边 + 圆角。
  static BoxDecoration glassPanel({double radius = 16}) => BoxDecoration(
        color: const Color(0x66232130),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: white10),
      );

  /// 软面板：白 5.5% 底 + 白 8% 描边。
  static BoxDecoration softPanel({double radius = 8}) => BoxDecoration(
        color: const Color(0x0EFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: white8),
      );

  /// 弹窗面板：不透明纯色底 + 白 10% 描边 + 投影。
  ///
  /// 与玻璃面板同色系但完全不透明——半透明弹窗会与主窗口内容
  /// 重叠显示，观感眩晕（对齐设计稿弹窗的实心深色面板）。
  static BoxDecoration dialogPanel({double radius = 16}) => BoxDecoration(
        color: const Color(0xFF232130),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000), // black 50%（本文件不引入 material Colors）
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      );
}
