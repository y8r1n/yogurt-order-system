import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'staff_order_provider.dart';

class TodayOrdersPage extends ConsumerStatefulWidget {
  const TodayOrdersPage({super.key});

  @override
  ConsumerState<TodayOrdersPage> createState() => _TodayOrdersPageState();
}

class _TodayOrdersPageState extends ConsumerState<TodayOrdersPage> {
  int selectedTopTab = 0;
  int selectedOrderTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // 로고
            // =========================
            const SizedBox(height: 24),

            Text(
              'YOGURTWORLD',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // 상단 메뉴
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TopTab(
                    title: '오늘의 주문',
                    selected: selectedTopTab == 0,
                    onTap: () {
                      setState(() {
                        selectedTopTab = 0;
                      });
                    },
                  ),
                  _TopTab(
                    title: '지난 주문',
                    selected: false,
                    onTap: () {
                      context.go('/history');
                    },
                  ),
                  _TopTab(
                    title: '메뉴 관리',
                    selected: selectedTopTab == 2,
                    onTap: () {
                      context.go('/menu-management');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppColors.primary,
            ),

            const SizedBox(height: 24),

            // =========================
            // 오늘의 주문 내부 탭
            // =========================
            if (selectedTopTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedOrderTab = 0;
                          });
                        },
                        child: Text(
                          '신규 접수',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: selectedOrderTab == 0
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedOrderTab = 1;
                          });
                        },
                        child: Text(
                          '현장 결제 처리',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: selectedOrderTab == 1
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            // =========================
            // 내용
            // =========================
            Expanded(
              child: selectedTopTab == 0
                  ? _buildTodayOrders()
                  : selectedTopTab == 1
                  ? const Center(child: Text('지난 주문 화면'))
                  : const Center(child: Text('메뉴 관리 화면')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOrders() {
  final ordersAsync =
      ref.watch(staffOrderProvider);

  return ordersAsync.when(
    loading: () {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },

    error: (error, stackTrace) {
      debugPrint(
        '주문 조회 실패: $error',
      );

      return Center(
        child: Text(
          '주문을 불러오지 못했습니다.\n$error',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      );
    },

    data: (allOrders) {
      final currentOrders =
          allOrders.where((order) {
        if (selectedOrderTab == 0) {
          return order.status ==
              StaffOrderStatus.pending;
        }

        return order.status ==
            StaffOrderStatus.accepted;
      }).toList();

      if (currentOrders.isEmpty) {
        return Center(
          child: Text(
            selectedOrderTab == 0
                ? '신규 주문이 없습니다'
                : '결제 대기 주문이 없습니다',
            style: AppTextStyles.bodyMedium,
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        itemCount: currentOrders.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order =
              currentOrders[index];

          return _OrderCard(
            order: order,
            buttonText:
                selectedOrderTab == 0
                    ? '주문 접수'
                    : '결제 완료',
            onAction: () async {
  debugPrint('주문 접수 ');
  debugPrint('order.id = ${order.id}');
  debugPrint('order.number = ${order.number}');

  if (selectedOrderTab == 0) {
    await ref
        .read(staffOrderProvider.notifier)
        .acceptOrder(order.id);
  } else {
    _showPaymentDialog(order);
  }
},
          );
        },
      );
    },
  );
}

    

  Future<void> _showPaymentDialog(StaffOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.primary, width: 2),
          ),
          title: Text(
            '현장결제 ${_formatPrice(order.totalPrice)}원',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.point_of_sale, size: 72),
              const SizedBox(height: 24),
              Text(
                'POS 처리 하시겠습니까?',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '현장결제 완료 후 완료 버튼을 눌러주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('완료'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

   await ref
    .read(staffOrderProvider.notifier)
    .completeOrder(order.id);
  }
}

// ============================================================
// 상단 탭
// ============================================================

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 주문 카드
// ============================================================

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.order,
    required this.buttonText,
    required this.onAction,
  });

  final StaffOrder order;
  final String buttonText;
  final VoidCallback onAction;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'NUMBER : ${order.number}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (expanded) ...[
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.menuName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'x${order.quantity}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                 if (order.sizeName.isNotEmpty) ...[
  const SizedBox(height: 12),

  Text(
    '사이즈',
    style: AppTextStyles.caption,
  ),

  const SizedBox(height: 4),

  Text(
    order.sizeName,
    style: AppTextStyles.bodyMedium,
  ),
],

                  if (order.toppings.isNotEmpty) ...[
                    const SizedBox(height: 12),

                    Text('추가 토핑', style: AppTextStyles.caption),

                    const SizedBox(height: 6),

                    ...order.toppings.map(
                      (topping) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('· $topping', style: AppTextStyles.caption),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  const Divider(),

                  Row(
                    children: [
                      Expanded(
                        child: Text('총 금액', style: AppTextStyles.caption),
                      ),
                      Text(
                        '${_formatPrice(order.totalPrice)}원',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(widget.buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// 임시 주문 모델
// ============================================================

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
