import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_provider.dart';
import '../order_type/order_session_provider.dart';

class OrderCompletePage extends ConsumerWidget {
  const OrderCompletePage({
    super.key,
    required this.pickupNumber,
  });

  final int pickupNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // =========================
                  // PICK-UP NUMBER
                  // =========================
                  const Text(
                    'PICK-UP NUMBER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =========================
                  // 픽업 번호
                  // =========================
                  Text(
                    '$pickupNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 110,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 64),

                  // =========================
                  // 안내 문구
                  // =========================
                  Text(
                    '결제는 직원 안내에 따라 진행해주세요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    '픽업 번호를 확인해주세요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // =========================
                  // 확인 버튼
                  // =========================
                  SizedBox(
                    width: 360,
                    height: 64,
                    child: OutlinedButton(
                      onPressed: () {
                            ref.read(cartProvider.notifier).clear();
ref.read(orderSessionProvider.notifier).clear();

context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}