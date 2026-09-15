import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

enum StaffOrderStatus {
  pending,
  accepted,
  completed,
}

class StaffOrder {
  const StaffOrder({
    required this.id,
    required this.number,
    required this.orderType,
    required this.icePack,
    required this.spoonCount,
    required this.menuName,
    required this.quantity,
    required this.sizeName,
    required this.toppings,
    required this.totalPrice,
    required this.createdAt,
    this.completedAt,
    required this.status,
  });

  // 실제 orders.id
  final String id;

  final int number;

  final String orderType;
  final bool icePack;
  final int spoonCount;

  final String menuName;
  final int quantity;
  final String sizeName;
  final List<String> toppings;
  final int totalPrice;

  final DateTime createdAt;
  final DateTime? completedAt;

  final StaffOrderStatus status;

}

class StaffOrderNotifier
    extends AsyncNotifier<List<StaffOrder>> {

  RealtimeChannel? _ordersChannel;

  @override
  Future<List<StaffOrder>> build() async {
    final supabase = Supabase.instance.client;

 _ordersChannel = supabase
    .channel('staff-orders-channel')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
    callback: (payload) async {
  debugPrint('Realtime 이벤트 수신');
  debugPrint('event = ${payload.eventType}');

  await Future.delayed(
    const Duration(milliseconds: 500),
  );

  await refreshOrders();

  debugPrint('Realtime refresh 완료');
},
        )
        .subscribe((status, error) {
      debugPrint('Realtime status = $status');
      if (error != null) {
        debugPrint('Realtime error = $error');
      }
    });

    return _fetchOrders();
  }

  // ============================================================
  // 날짜 문자열 변환
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 오늘 주문 조회
  // ============================================================

  Future<List<StaffOrder>> _fetchOrders() async {
    return _fetchOrdersByDate(
      DateTime.now(),
      statuses: [
        'pending',
        'accepted',
        'completed',
      ],
    );
  }

  // ============================================================
  // 지난 주문 조회
  // 선택한 날짜의 completed 주문만 조회
  // ============================================================

  Future<List<StaffOrder>> fetchCompletedOrdersByDate(
    DateTime date,
  ) async {
    return _fetchOrdersByDate(
      date,
      statuses: ['completed'],
    );
  }

  // ============================================================
  // 날짜별 주문 공통 조회
  // ============================================================

  Future<List<StaffOrder>> _fetchOrdersByDate(
    DateTime date, {
    required List<String> statuses,
  }) async {
    final supabase = Supabase.instance.client;
    final targetDate = _formatDate(date);

    debugPrint(' 주문 조회 날짜 = $targetDate');

    final data = await supabase
        .from('orders')
        .select(
          '''
          id,
          order_number,
          order_type,
          ice_pack,
          spoon_count,
          status,
          subtotal,
          created_at,
          accepted_at,
          completed_at,
          order_items (
            id,
            menu_name,
            quantity,
            item_total,
            order_item_options (
              option_group_name,
              option_name,
              additional_price,
              quantity
            )
          )
          ''',
        )
        .eq('order_date', targetDate)
        .inFilter(
          'status',
          statuses,
        )
        .order(
          'order_number',
          ascending: false,
        );

    final orders = <StaffOrder>[];

    for (final orderRow in data) {
      final items =
          (orderRow['order_items'] as List<dynamic>? ?? []);

      if (items.isEmpty) {
        continue;
      }

      final item =
          items.first as Map<String, dynamic>;

      final options =
          (item['order_item_options'] as List<dynamic>? ?? []);

      String sizeName = '';
      final toppings = <String>[];

      for (final rawOption in options) {
        final option =
            rawOption as Map<String, dynamic>;

        final groupName =
            option['option_group_name'] as String? ?? '';

        final optionName =
            option['option_name'] as String? ?? '';

        final quantity =
            option['quantity'] as int? ?? 1;

        if (groupName.contains('사이즈')) {
          sizeName = optionName;
        } else {
          toppings.add(
            '$optionName x$quantity',
          );
        }
      }

      orders.add(
        StaffOrder(
          id: orderRow['id'] as String,
          number: orderRow['order_number'] as int,
          orderType: orderRow['order_type'] as String,
          icePack: orderRow['ice_pack'] as bool? ?? false,
          spoonCount: orderRow['spoon_count'] as int? ?? 0,
          menuName: item['menu_name'] as String,
          quantity: item['quantity'] as int? ?? 1,
          sizeName: sizeName,
          toppings: toppings,
          totalPrice: orderRow['subtotal'] as int,
          createdAt: DateTime.parse(
            orderRow['created_at'] as String,
          ).toLocal(),
          completedAt: orderRow['completed_at'] != null
              ? DateTime.parse(
                  orderRow['completed_at'] as String,
                ).toLocal()
              : null,
          status: _parseStatus(
            orderRow['status'] as String,
          ),
        ),
      );
    }

    debugPrint(
      ' $targetDate 주문 조회 완료: ${orders.length}건',
    );

    return orders;
  }

  // ============================================================
  // 주문 접수
  // pending → accepted
  // ============================================================
Future<void> acceptOrder(String orderId) async {
  final supabase = Supabase.instance.client;

  debugPrint('DB 주문 접수 시작: $orderId');

  try {
    final result = await supabase
        .from('orders')
        .update({
          'status': 'accepted',
          'accepted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId)
        .select('id, order_number, status, accepted_at')
        .single();

    debugPrint('DB UPDATE 결과: $result');

    await refreshOrders();

    debugPrint('주문 목록 새로고침 완료');
  } catch (e, stackTrace) {
    debugPrint('주문 접수 실패: $e');
    debugPrint('$stackTrace');
    rethrow;
  }
}
  // ============================================================
  // 결제 완료
  // accepted → completed
  // ============================================================

  Future<void> completeOrder(String orderId) async {
  final supabase = Supabase.instance.client;

  try {
    final result = await supabase
        .from('orders')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId)
        .select('id, order_number, status, completed_at')
        .single();

    debugPrint('결제 완료 UPDATE 결과: $result');

    await refreshOrders();
  } catch (e, stackTrace) {
    debugPrint('결제 완료 실패: $e');
    debugPrint('$stackTrace');
    rethrow;
  }
}

  // ============================================================
  // 새로 조회
  // ============================================================

  Future<void> refreshOrders() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _fetchOrders,
    );
  }

  StaffOrderStatus _parseStatus(
    String status,
  ) {
    switch (status) {
      case 'accepted':
        return StaffOrderStatus.accepted;

      case 'completed':
        return StaffOrderStatus.completed;

      case 'pending':
      default:
        return StaffOrderStatus.pending;
    }
  }
}

final staffOrderProvider =
    AsyncNotifierProvider<
      StaffOrderNotifier,
      List<StaffOrder>
    >(
  StaffOrderNotifier.new,
);