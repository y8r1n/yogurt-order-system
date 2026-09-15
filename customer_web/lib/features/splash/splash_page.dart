import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: InkWell(
        onTap: () => context.go('/order-type'),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '요거트월드 운정점',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'YOGURT\nWORLD',
                textAlign: TextAlign.center,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.primary,
                  fontSize: 54,
                  height: 0.85,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                '화면을 터치하여 주문 시작',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}