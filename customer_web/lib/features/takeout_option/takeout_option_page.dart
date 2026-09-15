import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../order_type/order_session_provider.dart';

class TakeoutOptionPage extends ConsumerStatefulWidget {
  const TakeoutOptionPage({super.key});

@override
ConsumerState<TakeoutOptionPage> createState() =>
    _TakeoutOptionPageState();
}

class _TakeoutOptionPageState
    extends ConsumerState<TakeoutOptionPage> {
  bool? icePack;
  bool? spoon;
  int spoonCount = 1;

  void selectIcePack(bool value) {
    setState(() {
      icePack = value;
    });
  }

  void selectSpoon(bool value) {
    setState(() {
      spoon = value;

      // 숟가락 X 선택 시 실제 주문 수량은 0
      if (!value) {
        spoonCount = 0;
      } else if (spoonCount == 0) {
        spoonCount = 1;
      }
    });
  }

  void increaseSpoon() {
    if (spoonCount >= 4) return;

    setState(() {
      spoonCount++;
    });
  }

  void decreaseSpoon() {
    if (spoonCount <= 1) return;

    setState(() {
      spoonCount--;
    });
  }

  void goToMenu() {
  if (icePack == null || spoon == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아이스팩과 숟가락 옵션을 선택해주세요.'),
      ),
    );
    return;
  }

  final finalSpoonCount =
      spoon == true ? spoonCount : 0;

  ref.read(orderSessionProvider.notifier).setTakeOut(
    icePack: icePack!,
    spoonCount: finalSpoonCount,
  );

  debugPrint('주문 방식: take_out');
  debugPrint('아이스팩: $icePack');
  debugPrint('숟가락 개수: $finalSpoonCount');

  context.go('/menu');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단
                  Row(
                    children: [
                      Text(
                        '포장 옵션 선택',
                        style: AppTextStyles.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.go('/order-type'),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // =========================
                  // 아이스팩
                  // =========================
                  Text(
                    '아이스팩 선택',
                    style: AppTextStyles.titleMedium,
                  ),

                  const SizedBox(height: 20),

                  _OptionCard(
                    label: '아이스팩 X',
                    isSelected: icePack == false,
                    onTap: () => selectIcePack(false),
                  ),

                  const SizedBox(height: 12),

                  _OptionCard(
                    label: '아이스팩 O',
                    isSelected: icePack == true,
                    onTap: () => selectIcePack(true),
                  ),

                  const SizedBox(height: 40),

                  // =========================
                  // 숟가락
                  // =========================
                  Text(
                    '숟가락 선택',
                    style: AppTextStyles.titleMedium,
                  ),

                  const SizedBox(height: 20),

                  _OptionCard(
                    label: '숟가락 X',
                    isSelected: spoon == false,
                    onTap: () => selectSpoon(false),
                  ),

                  const SizedBox(height: 12),

                  _SpoonOptionCard(
                    isSelected: spoon == true,
                    count: spoonCount,
                    onTap: () => selectSpoon(true),
                    onDecrease: decreaseSpoon,
                    onIncrease: increaseSpoon,
                  ),

                  const Spacer(),

                  // =========================
                  // 다음 버튼
                  // =========================
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: goToMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '선택 완료',
                        style: AppTextStyles.button,
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

// ============================================================
// 일반 선택 카드
// ============================================================

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedBackground
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedBorder
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 숟가락 O + 수량 선택 카드
// ============================================================

class _SpoonOptionCard extends StatelessWidget {
  const _SpoonOptionCard({
    required this.isSelected,
    required this.count,
    required this.onTap,
    required this.onDecrease,
    required this.onIncrease,
  });

  final bool isSelected;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedBackground
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedBorder
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '숟가락 O',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(width: 32),

              Text(
                '(수량 최대 4개 가능)',
                style: AppTextStyles.caption,
              ),

              const Spacer(),

              // 숟가락 O를 선택한 경우에만 수량 조절 표시
              if (isSelected) ...[
                IconButton(
                  onPressed: count > 1 ? onDecrease : null,
                  icon: const Icon(Icons.remove),
                ),

                SizedBox(
                  width: 28,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),

                IconButton(
                  onPressed: count < 4 ? onIncrease : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}