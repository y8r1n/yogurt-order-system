import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../today_orders/staff_order_provider.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  late DateTime selectedDate;

int? expandedOrderNumber;

List<StaffOrder> historyOrders = [];
bool isLoadingHistory = true;
Object? historyError;

  @override
void initState() {
  super.initState();

  final now = DateTime.now();

  selectedDate = DateTime(
    now.year,
    now.month,
    now.day,
  );

  Future.microtask(_loadHistoryOrders);
}


Future<void> _loadHistoryOrders() async {
  setState(() {
    isLoadingHistory = true;
    historyError = null;
  });

  try {
    final orders = await ref
        .read(staffOrderProvider.notifier)
        .fetchCompletedOrdersByDate(selectedDate);

    if (!mounted) return;

    orders.sort(
      (a, b) => b.completedAt!.compareTo(
        a.completedAt!,
      ),
    );

    setState(() {
      historyOrders = orders;
      isLoadingHistory = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      historyError = e;
      isLoadingHistory = false;
    });
  }
}




  DateTime get today {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  DateTime get oldestAvailableDate {
    return today.subtract(const Duration(days: 6));
  }

  bool get canGoPrevious {
    return selectedDate.isAfter(oldestAvailableDate);
  }

  bool get canGoNext {
    return selectedDate.isBefore(today);
  }

 

 void movePreviousDate() {
  if (!canGoPrevious) return;

  setState(() {
    selectedDate = selectedDate.subtract(
      const Duration(days: 1),
    );

    expandedOrderNumber = null;
  });

  _loadHistoryOrders();
}

void moveNextDate() {
  if (!canGoNext) return;

  setState(() {
    selectedDate = selectedDate.add(
      const Duration(days: 1),
    );

    expandedOrderNumber = null;
  });

  _loadHistoryOrders();
}

  void toggleOrder(int number) {
    setState(() {
      if (expandedOrderNumber == number) {
        expandedOrderNumber = null;
      } else {
        expandedOrderNumber = number;
      }
    });
  }

  @override
Widget build(BuildContext context) {
  if (isLoadingHistory) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (historyError != null) {
    return Scaffold(
      body: Center(
        child: Text(
          '지난 주문을 불러오지 못했습니다.\n$historyError',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  final orders = historyOrders;

  final selectedTotal = orders.fold<int>(
    0,
    (sum, order) => sum + order.totalPrice,
  );

  return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // =========================
            // 로고
            // =========================
            Text(
              'YOGURTWORLD',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // 상단 탭
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TopTab(
                    title: '오늘의 주문',
                    selected: false,
                    onTap: () {
                      context.go('/');
                    },
                  ),

                  _TopTab(title: '지난 주문', selected: true, onTap: () {}),

                  _TopTab(
                    title: '메뉴 관리',
                    selected: false,
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

            const SizedBox(height: 20),

            // =========================
            // 날짜 선택
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: [
                  IconButton(
                    onPressed: canGoPrevious ? movePreviousDate : null,
                    icon: Icon(
                      Icons.arrow_left,
                      color: canGoPrevious
                          ? AppColors.primary
                          : AppColors.border,
                      size: 34,
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _formatDate(selectedDate),
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text('최근 7일 간의 주문', style: AppTextStyles.caption),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: canGoNext ? moveNextDate : null,
                    icon: Icon(
                      Icons.arrow_right,
                      color: canGoNext ? AppColors.primary : AppColors.border,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // 주문 없음
            // =========================
            if (orders.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    '해당 날짜의 주문 내역이 없습니다',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else ...[
              // =========================
              // 날짜 요약
              // =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_formatDate(selectedDate)}'
                    ' · ${orders.length}건'
                    ' / Total: ${_formatPrice(selectedTotal)}원',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // 지난 주문 목록
              // =========================
                            Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return _HistoryOrderCard(
                      order: order,
                      expanded:
                          expandedOrderNumber == order.number,
                      onTap: () =>
                          toggleOrder(order.number),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
// 지난 주문 카드
// ============================================================

class _HistoryOrderCard extends StatelessWidget {
  const _HistoryOrderCard({
    required this.order,
    required this.expanded,
    required this.onTap,
  });

  final StaffOrder order;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        children: [
          // =========================
          // 접힌 헤더
          // =========================
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Row(
                children: [
                  Text(
                    'NUMBER : ${order.number}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    '· ${_formatPrice(order.totalPrice)}원',
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '· ${_formatTime(order.completedAt!)}',
                    style: AppTextStyles.caption,
                  ),

                  const Spacer(),

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

          // =========================
          // 펼친 주문 상세
          // =========================
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

                  Text('사이즈', style: AppTextStyles.caption),

                  const SizedBox(height: 4),

                  Text(order.sizeName, style: AppTextStyles.bodyMedium),

                  if (order.toppings.isNotEmpty) ...[
                    const SizedBox(height: 12),

                    Text('추가 토핑', style: AppTextStyles.caption),

                    const SizedBox(height: 6),

                    ...order.toppings.map(
                      (topping) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('· $topping', style: AppTextStyles.caption),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  Divider(color: AppColors.border),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatDate(order.completedAt!)} '
                          '${_formatTime(order.completedAt!)}',
                          style: AppTextStyles.caption,
                        ),
                      ),

                      Text(
                        '${_formatPrice(order.totalPrice)}원',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
// 포맷 함수
// ============================================================


String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}.$month.$day';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');

  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
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
