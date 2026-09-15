import 'package:go_router/go_router.dart';

import '../../features/today_orders/today_orders_page.dart';
import '../../features/order_history/order_history_page.dart';
import '../../features/menu_management/menu_management_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TodayOrdersPage(),
      ),

      GoRoute(
        path: '/history',
        builder: (context, state) => const OrderHistoryPage(),
      ),

      GoRoute(
        path: '/menu-management',
        builder: (context, state) => const MenuManagementPage(),
      ),
    ],
  );
}