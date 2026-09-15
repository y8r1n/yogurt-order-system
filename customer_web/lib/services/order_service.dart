import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/cart/cart_provider.dart';

class CreatedOrder {
  const CreatedOrder({
    required this.orderId,
    required this.orderNumber,
  });

  final String orderId;
  final int orderNumber;
}

class OrderService {
  OrderService._();

  static Future<CreatedOrder> createOrder({
    required List<CartItem> cart,
    required int subtotal,
    required String orderType,
    bool icePack = false,
    int spoonCount = 0,
    String? customerNote,
  }) async {
    final supabase = Supabase.instance.client;

    if (cart.isEmpty) {
      throw Exception('장바구니가 비어 있습니다.');
    }

    // ============================================================
    // 1. orders 생성
    // order_number는 DB trigger가 자동 생성
    // ============================================================

    final orderData = await supabase
        .from('orders')
        .insert({
          'order_type': orderType,
          'ice_pack': orderType == 'take_out' ? icePack : false,
          'spoon_count': orderType == 'take_out' ? spoonCount : 0,
          'subtotal': subtotal,
          'customer_note': customerNote,
        })
        .select('id, order_number')
        .single();

    final orderId = orderData['id'] as String;
    final orderNumber = orderData['order_number'] as int;

    // ============================================================
    // 2. 장바구니 상품 저장
    // ============================================================

    for (final cartItem in cart) {
      final orderItemData = await supabase
          .from('order_items')
          .insert({
            'order_id': orderId,
            'menu_id': cartItem.menuId,

            // 주문 당시 스냅샷
            'menu_name': cartItem.menuName,
            'unit_price': cartItem.basePrice,

            // 현재 장바구니는 같은 메뉴도 개별 CartItem이므로 1
            'quantity': 1,

            // 사이즈 + 토핑까지 포함된 최종 상품 가격
            'item_total': cartItem.totalPrice,
          })
          .select('id')
          .single();

      final orderItemId = orderItemData['id'] as String;

      // ============================================================
// 3. 사이즈 옵션 저장
// 사이즈가 있는 메뉴만 저장
// ============================================================

if (cartItem.sizeOptionItemId != null) {
  await supabase.from('order_item_options').insert({
    'order_item_id': orderItemId,
    'option_item_id': cartItem.sizeOptionItemId,

    // 주문 당시 스냅샷
    'option_group_name': cartItem.sizeGroupName,
    'option_name': cartItem.sizeName,
    'additional_price': cartItem.sizeAdditionalPrice,
    'quantity': 1,
  });
}

      // ============================================================
      // 4. 토핑 옵션 저장
      // ============================================================

      if (cartItem.toppings.isNotEmpty) {
        final toppingRows = cartItem.toppings
            .map(
              (topping) => {
                'order_item_id': orderItemId,
                'option_item_id': topping.optionItemId,
                'option_group_name': topping.optionGroupName,
                'option_name': topping.name,
                'additional_price': topping.price,
                'quantity': topping.quantity,
              },
            )
            .toList();

        await supabase
            .from('order_item_options')
            .insert(toppingRows);
      }
    }

    return CreatedOrder(
      orderId: orderId,
      orderNumber: orderNumber,
    );
  }
}