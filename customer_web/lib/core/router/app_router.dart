import 'package:go_router/go_router.dart';

import '../../features/menu/menu_page.dart';
import '../../features/order_type/order_type_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/takeout_option/takeout_option_page.dart';
import '../../features/menu/menu_detail_page.dart';
import '../../features/cart/cart_page.dart';
import '../../features/order_complete/order_complete_page.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/order-type',
        builder: (context, state) => const OrderTypePage(),
      ),
         GoRoute(
        path: '/takeout-option',
        builder: (context, state) => const TakeoutOptionPage(),
      ),

      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
  path: '/menu-detail/:menuId',
  builder: (context, state) {
    final menuId = state.pathParameters['menuId']!;

    return MenuDetailPage(
      menuId: menuId,
    );
  },
),

      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/order-complete/:pickupNumber',
        builder: (context, state) {
        final pickupNumber = int.parse(
        state.pathParameters['pickupNumber']!,
        );

        return OrderCompletePage(
          pickupNumber: pickupNumber,
        );
        },
      ),
    ],
  );
}