import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderSession {
  const OrderSession({
    this.orderType,
    this.icePack = false,
    this.spoonCount = 0,
  });

  // Supabase orders.order_type에 그대로 넣을 값
  final String? orderType;

  final bool icePack;
  final int spoonCount;

  OrderSession copyWith({
    String? orderType,
    bool? icePack,
    int? spoonCount,
  }) {
    return OrderSession(
      orderType: orderType ?? this.orderType,
      icePack: icePack ?? this.icePack,
      spoonCount: spoonCount ?? this.spoonCount,
    );
  }
}

class OrderSessionNotifier extends Notifier<OrderSession> {
  @override
  OrderSession build() {
    return const OrderSession();
  }

 void setDineIn({
  required int spoonCount,
}) {
  state = OrderSession(
    orderType: 'dine_in',
    icePack: false,
    spoonCount: spoonCount,
  );
}

  void setTakeOut({
    required bool icePack,
    required int spoonCount,
  }) {
    state = OrderSession(
      orderType: 'take_out',
      icePack: icePack,
      spoonCount: spoonCount,
    );
  }


  void selectOrderType(String orderType) {
  state = OrderSession(
    orderType: orderType,
    icePack: false,
    spoonCount: 0,
  );
}

  void clear() {
    state = const OrderSession();
  }
}

final orderSessionProvider =
    NotifierProvider<OrderSessionNotifier, OrderSession>(
  OrderSessionNotifier.new,
);