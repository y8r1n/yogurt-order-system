import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cart/cart_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  int selectedCategoryIndex = 0;

  RealtimeChannel? _menusChannel;
  RealtimeChannel? _categoriesChannel;

// 카테고리
final List<_MenuCategory> categories = [];

bool isLoadingCategories = true;
String? categoryError;

@override
void initState() {
  super.initState();
  _loadCategories();
}

void _subscribeToMenus() {
  if (_menusChannel != null) return;

  _menusChannel = Supabase.instance.client
      .channel('customer-menus-realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'menus',
        callback: (payload) {
          if (!mounted || categories.isEmpty) return;

          debugPrint('메뉴 변경 감지: ${payload.eventType}');

          final categoryId =
              categories[selectedCategoryIndex].id;

          _loadMenus(categoryId);
        },
      )
      .subscribe();
}

@override
void dispose() {
  final menusChannel = _menusChannel;
  final categoriesChannel = _categoriesChannel;

  if (menusChannel != null) {
    Supabase.instance.client
        .removeChannel(menusChannel);
  }

  if (categoriesChannel != null) {
    Supabase.instance.client
        .removeChannel(categoriesChannel);
  }

  super.dispose();
}

Future<void> _loadCategories() async {
  try {
    final data = await Supabase.instance.client
        .from('menu_categories')
        .select('id, name')
        .eq('is_active', true)
        .order('display_order', ascending: true);

    if (!mounted) return;

    final loadedCategories = data
        .map(
          (row) => _MenuCategory(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();

   String? selectedCategoryId;

if (categories.isNotEmpty &&
    selectedCategoryIndex < categories.length) {
  selectedCategoryId =
      categories[selectedCategoryIndex].id;
}

setState(() {
  categories
    ..clear()
    ..addAll(loadedCategories);

  if (categories.isEmpty) {
    selectedCategoryIndex = 0;
  } else if (selectedCategoryId != null) {
    final newIndex = categories.indexWhere(
      (category) =>
          category.id == selectedCategoryId,
    );

    selectedCategoryIndex =
        newIndex >= 0 ? newIndex : 0;
  } else {
    selectedCategoryIndex = 0;
  }

  isLoadingCategories = false;
  categoryError = null;
});

if (categories.isNotEmpty) {
  await _loadMenus(
    categories[selectedCategoryIndex].id,
  );
}

_subscribeToMenus();
_subscribeToCategories();
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingCategories = false;
      categoryError = e.toString();
    });

    debugPrint('카테고리 불러오기 실패: $e');
  }
}


void _subscribeToCategories() {
  if (_categoriesChannel != null) return;

  _categoriesChannel = Supabase.instance.client
      .channel('customer-categories-realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'menu_categories',
        callback: (payload) async {
          if (!mounted) return;

          debugPrint(
            '카테고리 변경 감지: ${payload.eventType}',
          );

          await _loadCategories();
        },
      )
      .subscribe();
}


  // 메뉴
  final List<_Menu> menus = [];

bool isLoadingMenus = true;
String? menuError;

// 메뉴 불러오기

Future<void> _loadMenus(String categoryId) async {
  setState(() {
    isLoadingMenus = true;
    menuError = null;
  });

  try {
    final data = await Supabase.instance.client
        .from('menus')
        .select(
          'id, name, english_name, price, badge, image_url, is_available',
        )
        .eq('category_id', categoryId)
.eq('is_active', true)
.eq('is_deleted', false)
.order('display_order', ascending: true);

    if (!mounted) return;

    setState(() {
      menus
        ..clear()
        ..addAll(
          data.map(
            (row) => _Menu(
              id: row['id'] as String,
              name: row['name'] as String,
              englishName: row['english_name'] as String?,
              price: row['price'] as int,
              badge: row['badge'] as String?,
              imageUrl: row['image_url'] as String?,
              isAvailable: row['is_available'] as bool,
            ),
          ),
        );

      isLoadingMenus = false;
      menuError = null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingMenus = false;
      menuError = e.toString();
    });

    debugPrint('메뉴 불러오기 실패: $e');
  }
}

  void selectCategory(int index) {
  setState(() {
    selectedCategoryIndex = index;
  });

  _loadMenus(categories[index].id);
}

void selectMenu(_Menu menu) {
  if (!menu.isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('현재 품절된 메뉴입니다.'),
      ),
    );

    return;
  }

  debugPrint('선택된 메뉴: ${menu.name}');
  debugPrint('메뉴 ID: ${menu.id}');

  context.go('/menu-detail/${menu.id}');
}

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    final cartTotal = cart.fold<int>(0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Column(
                children: [
                  // =========================
                  // 카테고리
                  // =========================
                  SizedBox(
                    height: 72,
                    child: isLoadingCategories
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : categoryError != null
        ? const Center(
            child: Text('카테고리를 불러오지 못했습니다.'),
          )
       : ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: categories.length,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    separatorBuilder: (context, index) =>
        const SizedBox(width: 28),
    itemBuilder: (context, index) {
      final isSelected = selectedCategoryIndex == index;

      return InkWell(
        onTap: () => selectCategory(index),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              categories[index].name,
              maxLines: 1,
              softWrap: false,
              style: AppTextStyles.titleMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    },
  ),
                  ),

                  const SizedBox(height: 20),

                  // =========================
                  // 메뉴 목록
                  // =========================
                 Expanded(
  child: isLoadingMenus
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : menuError != null
          ? const Center(
              child: Text('메뉴를 불러오지 못했습니다.'),
            )
          : menus.isEmpty
              ? const Center(
                  child: Text('등록된 메뉴가 없습니다.'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: menus.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final menu = menus[index];

                    return _MenuCard(
                      menu: menu,
                      onTap: () => selectMenu(menu),
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
      // 장바구니 하단 버튼
      // =========================
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 12, 48, 24),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('장바구니 ${cart.length}개 / 총액 $cartTotal');
                      context.go('/cart');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '${cart.length}개 주문하기 · '
                      '${_formatPrice(cartTotal)}원',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// 메뉴 카드
// ============================================================

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.menu,
    required this.onTap,
  });

  final _Menu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // 이미지 영역
              // =========================
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Container(
    width: double.infinity,
    color: AppColors.selectedBackground,
    child: _buildMenuImage(menu),
  ),
),

                    // NEW / BEST 등 뱃지
                    if (menu.badge != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            menu.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // 품절 오버레이
                    if (!menu.isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '품절',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 메뉴명
              Text(
                menu.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // 영문명
              Text(
                menu.englishName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: 8),

              // 가격
              Text(
                '${_formatPrice(menu.price)}원',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget _buildMenuImage(_Menu menu) {
  final imageUrl = menu.imageUrl;

  if (imageUrl == null || imageUrl.isEmpty) {
    return Center(
      child: Icon(
        Icons.icecream_outlined,
        size: 72,
        color: AppColors.primary,
      ),
    );
  }

  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (
      context,
      error,
      stackTrace,
    ) {
      return Center(
        child: Icon(
          Icons.icecream_outlined,
          size: 72,
          color: AppColors.primary,
        ),
      );
    },
  );
}

// ============================================================


class _MenuCategory {
  const _MenuCategory({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}


// ============================================================
//  메뉴 모델
// ============================================================

class _Menu {
  const _Menu({
    required this.id,
    required this.name,
    required this.englishName,
    required this.price,
    required this.badge,
    required this.imageUrl,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String? englishName;
  final int price;
  final String? badge;
  final String? imageUrl;
  final bool isAvailable;
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