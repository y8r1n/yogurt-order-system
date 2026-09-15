import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MenuDetailPage extends ConsumerStatefulWidget {
  const MenuDetailPage({
    super.key,
    required this.menuId,
  });

  final String menuId;

  @override
  ConsumerState<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends ConsumerState<MenuDetailPage> {
  int basePrice = 0;

  String menuName = '';
  String englishName = '';
  String? description;
  String? menuImageUrl;

  bool isLoadingMenu = true;
  String? menuError;
  
  bool isMenuAvailable = true;

  bool isLoadingOptions = true;
  String? optionError;

  final List<_OptionGroup> optionGroups = [];

  int? selectedSizeIndex;

  _OptionGroup? get sizeGroup {
    for (final group in optionGroups) {
      if (group.selectionType == 'single' && group.isRequired) {
        return group;
      }
    }

    return null;
  }

  List<_OptionGroup> get toppingGroupsFromDb {
  return optionGroups
      .where((group) => group.selectionType == 'multiple')
      .toList();
}

@override
void initState() {
  super.initState();
  _loadMenu();
  _loadOptions();
}

Future<void> _loadMenu() async {
  try {
    final data = await Supabase.instance.client
        .from('menus')
        .select(
  'name, english_name, description, price, image_url, is_available',
)
        .eq('id', widget.menuId)
.eq('is_active', true)
.eq('is_deleted', false)
.single();

    if (!mounted) return;

    setState(() {
      menuName = data['name'] as String;
      englishName = (data['english_name'] as String?) ?? '';
      description = data['description'] as String?;
      basePrice = data['price'] as int;
      isMenuAvailable = data['is_available'] as bool;

      menuImageUrl = data['image_url'] as String?;

      isLoadingMenu = false;
      menuError = null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingMenu = false;
      menuError = e.toString();
    });

    debugPrint('메뉴 상세 불러오기 실패: $e');
  }
}

Future<void> _loadOptions() async {
  try {
    final linkData = await Supabase.instance.client
        .from('menu_option_groups')
        .select(
          '''
          display_order,
          is_required_override,
          min_select_override,
          max_select_override,
          option_groups!inner(
            id,
            name,
            selection_type,
            is_required,
            min_select,
            max_select,
            is_active
          )
          ''',
        )
      .eq('menu_id', widget.menuId)
.eq('is_active', true)
.eq('option_groups.is_active', true)
.eq('option_groups.is_deleted', false)
.order('display_order', ascending: true);

    final loadedGroups = <_OptionGroup>[];

    for (final linkRow in linkData) {
      final groupRow =
          linkRow['option_groups'] as Map<String, dynamic>;

      final groupId = groupRow['id'] as String;

      final itemData = await Supabase.instance.client
          .from('option_items')
          .select(
            '''
            id,
            name,
            additional_price,
            max_quantity,
            display_order,
            is_available
            ''',
          )
       .eq('option_group_id', groupId)
.eq('is_active', true)
.eq('is_deleted', false)
.order('display_order', ascending: true);

      loadedGroups.add(
        _OptionGroup(
          id: groupId,
          name: groupRow['name'] as String,
          selectionType:
              groupRow['selection_type'] as String,

          isRequired:
              (linkRow['is_required_override'] as bool?) ??
              groupRow['is_required'] as bool,

          minSelect:
              (linkRow['min_select_override'] as int?) ??
              groupRow['min_select'] as int,

          maxSelect:
              (linkRow['max_select_override'] as int?) ??
              groupRow['max_select'] as int,

          items: itemData
              .map(
                (itemRow) => _OptionItem(
                  id: itemRow['id'] as String,
                  name: itemRow['name'] as String,
                  additionalPrice:
                      itemRow['additional_price'] as int,
                  maxQuantity:
                      itemRow['max_quantity'] as int,
                  isAvailable:
                      itemRow['is_available'] as bool,
                ),
              )
              .toList(),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      optionGroups
        ..clear()
        ..addAll(loadedGroups);

      isLoadingOptions = false;
      optionError = null;
    });

    debugPrint(
      '옵션 그룹 ${optionGroups.length}개 로드 완료',
    );

    for (final group in optionGroups) {
      debugPrint(
        '${group.name} / ${group.items.length}개 / '
        '${group.selectionType} / '
        'required=${group.isRequired} / '
        'max=${group.maxSelect}',
      );
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingOptions = false;
      optionError = e.toString();
    });

    debugPrint('옵션 불러오기 실패: $e');
  }
}

 

  // ============================================================
  // 토핑 옵션
  // ============================================================

 
  // 현재 펼쳐져 있는 그룹
  int? expandedToppingGroup;

  // key = "그룹번호-옵션번호"
  // value = 선택 수량
  final Set<String> selectedToppingKeys = {};

  String toppingKey(int groupIndex, int itemIndex) {
  return '$groupIndex-$itemIndex';
}

void toggleToppingGroup(int groupIndex) {
  setState(() {
    if (expandedToppingGroup == groupIndex) {
      expandedToppingGroup = null;
    } else {
      expandedToppingGroup = groupIndex;
    }
  });
}

  //============================================================가격

  int get totalPrice {
    int total = basePrice;

    // 사이즈 추가금
    final currentSizeGroup = sizeGroup;

    if (selectedSizeIndex != null && currentSizeGroup != null) {
      total += currentSizeGroup
      .items[selectedSizeIndex!]
      .additionalPrice;
}

    // 토핑 추가금
 for (final key in selectedToppingKeys) {
  final parts = key.split('-');

  final groupIndex = int.parse(parts[0]);
  final itemIndex = int.parse(parts[1]);

  final topping =
      toppingGroupsFromDb[groupIndex].items[itemIndex];

  total += topping.additionalPrice;
}

    return total;
  }

  // ============================================================ 사이즈 함수
  void selectSize(int index) {
  final currentSizeGroup = sizeGroup;

  if (currentSizeGroup == null) return;

  setState(() {
    selectedSizeIndex = index;
  });

  debugPrint(
    '선택 사이즈: ${currentSizeGroup.items[index].name}',
  );

  debugPrint('현재 총액: $totalPrice');
}

  // ============================================================ 토핑 함수
 void toggleTopping(int groupIndex, int itemIndex) {
  final group = toppingGroupsFromDb[groupIndex];
  final key = toppingKey(groupIndex, itemIndex);

  final isSelected = selectedToppingKeys.contains(key);

  if (isSelected) {
    setState(() {
      selectedToppingKeys.remove(key);
    });

    return;
  }

int selectedCount = 0;

for (
  int itemIndex = 0;
  itemIndex < group.items.length;
  itemIndex++
) {
  final key =
      toppingKey(groupIndex, itemIndex);

  if (selectedToppingKeys.contains(key)) {
    selectedCount++;
  }
}

  if (group.maxSelect > 0 &&
      selectedCount >= group.maxSelect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${group.name}은 최대 ${group.maxSelect}개까지 선택할 수 있습니다.',
        ),
      ),
    );

    return;
  }

  setState(() {
    selectedToppingKeys.add(key);
  });
}

// ============================================================
// 메뉴 이미지
// ============================================================

Widget _buildMenuImage() {
  final imageUrl = menuImageUrl;

  if (imageUrl == null || imageUrl.isEmpty) {
    return Icon(
      Icons.icecream_outlined,
      size: 120,
      color: AppColors.primary,
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
      return Icon(
        Icons.icecream_outlined,
        size: 120,
        color: AppColors.primary,
      );
    },
  );
}


 @override
Widget build(BuildContext context) {
 if (isLoadingMenu || isLoadingOptions) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

if (menuError != null || optionError != null) {
  return const Scaffold(
    body: Center(
      child: Text('메뉴 정보를 불러오지 못했습니다.'),
    ),
  );
}
  return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(56, 40, 56, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =========================
                      // 메뉴 이미지
                      // =========================
                      Center(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 230,
      height: 230,
      color: AppColors.selectedBackground,
      child: _buildMenuImage(),
    ),
  ),
),

                      const SizedBox(height: 36),

                      Text(
                        menuName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        englishName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),

                      const SizedBox(height: 44),

                      if (description != null && description!.isNotEmpty)
                      Text(
                      description!,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                            ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_formatPrice(basePrice)}원',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Divider(thickness: 2, color: AppColors.primary),

                      const SizedBox(height: 56),

                      // =========================
                      // 필수 사이즈 선택
                      // =========================
                     // =========================
// 사이즈 선택
// =========================
if (sizeGroup != null) ...[
  Row(
    children: [
      const Text(
        '*',
        style: TextStyle(
          color: Colors.red,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        sizeGroup!.name,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),

  const SizedBox(height: 24),

  ...List.generate(
    sizeGroup!.items.length,
    (index) {
      final option = sizeGroup!.items[index];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SizeOptionCard(
          name: option.name,
          additionalPrice: option.additionalPrice,
          isSelected: selectedSizeIndex == index,
          onTap: () => selectSize(index),
        ),
      );
    },
  ),

  const SizedBox(height: 60),
],

                      // 토핑 옵션
                     if (toppingGroupsFromDb.isNotEmpty) ...[
  Text(
    '토핑 추가(선택)',
    style: AppTextStyles.titleMedium.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 8),

  Text(
    '* 선택의 기본 선택 시 시럽 함께 제공하지 않습니다. '
    '원하실 시 옵션 추가 부탁드립니다.',
    style: AppTextStyles.caption.copyWith(
      color: Colors.red,
    ),
  ),

  const SizedBox(height: 28),

  ...List.generate(
    toppingGroupsFromDb.length,
    (groupIndex) {
      final group = toppingGroupsFromDb[groupIndex];

      final isExpanded =
          expandedToppingGroup == groupIndex;

      int selectedCount = 0;

      for (
        int itemIndex = 0;
        itemIndex < group.items.length;
        itemIndex++
      ) {
        final key =
            toppingKey(groupIndex, itemIndex);

        if (selectedToppingKeys.contains(key)) {
          selectedCount++;
        }
      }

      return Column(
        children: [
          InkWell(
            onTap: () =>
                toggleToppingGroup(groupIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    '선택 $selectedCount/${group.maxSelect}',
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(width: 20),

                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 20),
              child: Column(
                children: List.generate(
                  group.items.length,
                  (itemIndex) {
                    final topping =
                        group.items[itemIndex];

                    final key = toppingKey(
                      groupIndex,
                      itemIndex,
                    );

                    final isSelected =
                        selectedToppingKeys
                            .contains(key);

                    return _ToppingOptionRow(
                      name: topping.name,
                      price: topping.additionalPrice,
                      isSelected: isSelected,
                      onTap: () => toggleTopping(
                        groupIndex,
                        itemIndex,
                      ),
                    );
                  },
                ),
              ),
            ),

          Divider(
            color: AppColors.border,
            height: 1,
          ),
        ],
      );
    },
  ),
],

const SizedBox(height: 120),
                    ],
                  ),
                ),

                // =========================
                // 닫기 버튼
                // =========================
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => context.go('/menu'),
                    icon: Icon(Icons.close, color: AppColors.primary, size: 30),
                  ),
                ),

                Positioned(
                  left: 40,
                  right: 40,
                  bottom: 24,
                  child: SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isMenuAvailable) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('현재 품절된 메뉴입니다.'),
    ),
  );
  return;
}
                      
final currentSizeGroup = sizeGroup;

if (currentSizeGroup != null &&
    selectedSizeIndex == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('사이즈를 선택해주세요.'),
    ),
  );
  return;
}

final selectedSize =
    currentSizeGroup != null
        ? currentSizeGroup.items[selectedSizeIndex!]
        : null;
                        final selectedToppings = <CartTopping>[];

                       for (final key in selectedToppingKeys) {
  final parts = key.split('-');

  final groupIndex = int.parse(parts[0]);
  final itemIndex = int.parse(parts[1]);

  final topping =
      toppingGroupsFromDb[groupIndex]
          .items[itemIndex];

  selectedToppings.add(
  CartTopping(
    optionItemId: topping.id,
    optionGroupName:
        toppingGroupsFromDb[groupIndex].name,
    name: topping.name,
    price: topping.additionalPrice,
    quantity: 1,
  ),
);
}

final cartItem = CartItem(
  menuId: widget.menuId,
  menuName: menuName,

  sizeOptionItemId: selectedSize?.id,
  sizeGroupName: currentSizeGroup?.name,
  sizeName: selectedSize?.name,

  basePrice: basePrice,
  sizeAdditionalPrice:
      selectedSize?.additionalPrice ?? 0,

  toppings: selectedToppings,
  totalPrice: totalPrice,
);

                        ref.read(cartProvider.notifier).addItem(cartItem);

                        debugPrint('장바구니 추가: ${cartItem.menuName}');

                        debugPrint('장바구니 총액: ${cartItem.totalPrice}');

                        context.go('/menu');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '총 ${_formatPrice(totalPrice)}원 주문 담기',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 사이즈 옵션
// ============================================================

class _SizeOptionCard extends StatelessWidget {
  const _SizeOptionCard({
    required this.name,
    required this.additionalPrice,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int additionalPrice;

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedBackground
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.selectedBorder : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(name, style: AppTextStyles.bodyMedium),
              ),
              Text(
                additionalPrice == 0
                ? '+0원'
              : '+${_formatPrice(additionalPrice)}원',
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

// ============================================================ 토핑
class _ToppingOptionRow extends StatelessWidget {
  const _ToppingOptionRow({
    required this.name,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int price;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedBackground
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.selectedBorder
                  : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyMedium,
                ),
              ),

              Text(
                '+${_formatPrice(price)}원',
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


 class _OptionGroup {
  const _OptionGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.items,
  });

  final String id;
  final String name;
  final String selectionType;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final List<_OptionItem> items;
}

class _OptionItem {
  const _OptionItem({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.maxQuantity,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final int additionalPrice;
  final int maxQuantity;
  final bool isAvailable;
}

//===================== 가격 포맷

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
