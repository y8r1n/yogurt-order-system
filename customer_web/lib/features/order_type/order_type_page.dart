import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_session_provider.dart';

enum OrderType {
  dineIn,
  takeOut,
}

class OrderTypePage extends ConsumerStatefulWidget  {
  const OrderTypePage({super.key});

  @override
  ConsumerState<OrderTypePage> createState() =>
    _OrderTypePageState();
}

class _OrderTypePageState
    extends ConsumerState<OrderTypePage> {
  OrderType? selectedType;

void selectOrderType(OrderType type) {
  setState(() {
    selectedType = type;
  });

  final orderType = type == OrderType.dineIn
      ? 'dine_in'
      : 'take_out';

  ref
      .read(orderSessionProvider.notifier)
      .selectOrderType(orderType);

  debugPrint('선택된 주문 방식: $orderType');

  context.go('/takeout-option');
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 40,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _OrderTypeCard(
                      icon: Icons.restaurant,
                      label: '매장에서 먹어요',
                      isSelected: selectedType == OrderType.dineIn,
                      onTap: () => selectOrderType(OrderType.dineIn),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: _OrderTypeCard(
                      icon: Icons.shopping_bag_outlined,
                      label: '포장해서 가요',
                      isSelected: selectedType == OrderType.takeOut,
                     onTap: () => selectOrderType(OrderType.takeOut),
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

class _OrderTypeCard extends StatelessWidget {
  const _OrderTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 380,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedBackground
                : AppColors.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedBorder
                  : Colors.transparent,
              width: 4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 100,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 48),
              Text(
                label,
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}