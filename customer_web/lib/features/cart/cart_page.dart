import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'cart_provider.dart';
import '../../services/order_service.dart';
import '../order_type/order_session_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    final orderSession =
    ref.watch(orderSessionProvider);

    final totalPrice = cart.fold<int>(0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 32, 48, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =========================
                  // 상단
                  // =========================
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/menu'),
                        icon: const Icon(Icons.arrow_back, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '장바구니',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // =========================
                  // 장바구니가 비어 있을 때
                  // =========================
                  if (cart.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          '장바구니가 비어 있습니다.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    )
                  else
                    // =========================
                    // 장바구니 목록
                    // =========================
                    Expanded(
                      child: ListView.separated(
                        itemCount: cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = cart[index];

                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.menuName,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),

                                    Text(
                                      '${_formatPrice(item.totalPrice)}원',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    IconButton(
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeItem(index);
                                      },
                                      tooltip: '삭제',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                               if (item.sizeName != null &&
    item.sizeName!.isNotEmpty)
  Text(
    '사이즈: ${item.sizeName}',
    style: AppTextStyles.bodyMedium,
  ),

                                if (item.toppings.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '추가 토핑',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...item.toppings.map(
                                    (topping) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '· ${topping.name} '
                                        'x${topping.quantity} '
                                        '(+${_formatPrice(topping.price * topping.quantity)}원)',
                                        style: AppTextStyles.caption,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      // =========================
      // 최종 주문 버튼
      // =========================
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 12, 48, 24),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                   onPressed: () async {
  // 주문 방식이 저장되지 않은 이상 상태 방지
  if (orderSession.orderType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('주문 방식을 확인할 수 없습니다.'),
      ),
    );
    return;
  }

  try {
    debugPrint('최종 주문 금액: $totalPrice');
    debugPrint('주문 방식: ${orderSession.orderType}');
    debugPrint('아이스팩: ${orderSession.icePack}');
    debugPrint('숟가락 개수: ${orderSession.spoonCount}');

    final createdOrder = await OrderService.createOrder(
      cart: cart,
      subtotal: totalPrice,
      orderType: orderSession.orderType!,
      icePack: orderSession.icePack,
      spoonCount: orderSession.spoonCount,
    );

    if (!context.mounted) return;

    debugPrint('주문 생성 완료');
    debugPrint('주문 ID: ${createdOrder.orderId}');
    debugPrint('픽업 번호: ${createdOrder.orderNumber}');

    context.go(
      '/order-complete/${createdOrder.orderNumber}',
    );
  } catch (e) {
    if (!context.mounted) return;

    debugPrint('주문 생성 실패: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '주문 처리 중 오류가 발생했습니다.\n$e',
        ),
      ),
    );
  }
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '총 ${_formatPrice(totalPrice)}원 주문하기',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

String _formatPrice(int price) {
  final text = price.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}
