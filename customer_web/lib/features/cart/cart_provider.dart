import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartTopping {
  const CartTopping({
    required this.optionItemId,
    required this.optionGroupName,
    required this.name,
    required this.price,
    required this.quantity,
  });

  // Supabase option_items.id
  final String optionItemId;

  // 주문 당시 옵션 그룹명 스냅샷
  final String optionGroupName;

  final String name;
  final int price;
  final int quantity;
}

class CartItem {
  const CartItem({
    required this.menuId,
    required this.menuName,

    required this.sizeOptionItemId,
    required this.sizeGroupName,
    required this.sizeName,

    required this.basePrice,
    required this.sizeAdditionalPrice,

    required this.toppings,
    required this.totalPrice,
  });

  // Supabase menus.id
  final String menuId;

  final String menuName;

  final String? sizeOptionItemId;
  final String? sizeGroupName;
  final String? sizeName;

  final int basePrice;
  final int sizeAdditionalPrice;

  final List<CartTopping> toppings;

  final int totalPrice;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addItem(CartItem item) {
    state = [...state, item];
  }

  void removeItem(int index) {
    final newCart = [...state];
    newCart.removeAt(index);
    state = newCart;
  }

  void clear() {
    state = [];
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);