import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';


// =============================================================
// 카테고리 모델
// =============================================================

class MenuCategoryItem {
  const MenuCategoryItem({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;

  factory MenuCategoryItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return MenuCategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      displayOrder:
          map['display_order'] as int? ?? 0,
      isActive:
          map['is_active'] as bool? ?? true,
    );
  }
}

// =============================================================
// 메뉴 모델
// =============================================================

class StaffMenuItem {
  const StaffMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.englishName,
    required this.description,
    required this.price,
    required this.badge,
    required this.imageUrl,
    required this.displayOrder,
    required this.isAvailable,
    required this.isActive,
  });

  final String id;
  final String categoryId;

  final String name;
  final String? englishName;
  final String? description;

  final int price;

  final String? badge;
  final String? imageUrl;

  final int displayOrder;

  // false = 품절
  final bool isAvailable;

  // false = 숨김
  final bool isActive;

  factory StaffMenuItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return StaffMenuItem(
      id: map['id'] as String,
      categoryId:
          map['category_id'] as String,
      name: map['name'] as String,
      englishName:
          map['english_name'] as String?,
      description:
          map['description'] as String?,
      price:
          map['price'] as int? ?? 0,
      badge:
          map['badge'] as String?,
      imageUrl:
          map['image_url'] as String?,
      displayOrder:
          map['display_order'] as int? ?? 0,
      isAvailable:
          map['is_available'] as bool? ?? true,
      isActive:
          map['is_active'] as bool? ?? true,
    );
  }
}

class StaffOptionItem {
  const StaffOptionItem({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final int additionalPrice;
  final int displayOrder;
  final bool isActive;

  factory StaffOptionItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return StaffOptionItem(
      id: map['id'] as String,
      name: map['name'] as String,
      additionalPrice:
          map['additional_price'] as int? ?? 0,
      displayOrder:
          map['display_order'] as int? ?? 0,
      isActive:
          map['is_active'] as bool? ?? true,
    );
  }
}

class StaffOptionGroup {
  const StaffOptionGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.displayOrder,
    required this.isActive,
    required this.items,
  });

  final String id;
  final String name;

  final String selectionType;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;

  final int displayOrder;
  final bool isActive;

  final List<StaffOptionItem> items;

  factory StaffOptionGroup.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawItems =
        map['option_items'] as List<dynamic>? ?? [];

    final items = rawItems
        .map(
          (item) => StaffOptionItem.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort(
        (a, b) =>
            a.displayOrder.compareTo(b.displayOrder),
      );

    return StaffOptionGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      selectionType:
          map['selection_type'] as String? ??
              'multiple',
      isRequired:
          map['is_required'] as bool? ?? false,
      minSelect:
          map['min_select'] as int? ?? 0,
      maxSelect:
          map['max_select'] as int? ?? 1,
      displayOrder:
          map['display_order'] as int? ?? 0,
      isActive:
          map['is_active'] as bool? ?? true,
      items: items,
    );
  }
}

  class OptionItemSaveInput {
  const OptionItemSaveInput({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.isActive,
  });

  final String? id;
  final String name;
  final int additionalPrice;
  final bool isActive;
}
// =============================================================
// 메뉴 관리 전체 데이터
// =============================================================

class MenuManagementData {
  const MenuManagementData({
    required this.categories,
    required this.menus,
  });

  final List<MenuCategoryItem> categories;
  final List<StaffMenuItem> menus;
}

// =============================================================
// Provider
// =============================================================

class MenuManagementNotifier
    extends AsyncNotifier<MenuManagementData> {
  @override
  Future<MenuManagementData> build() async {
    return _fetchData();
  }

  Future<MenuManagementData> _fetchData() async {
    final supabase =
        Supabase.instance.client;

    // ---------------------------------------------------------
    // 카테고리
    //
    // 관리자 화면이므로 is_active=false인 카테고리도
    // 나중에 수정할 수 있도록 전부 가져온다.
    // ---------------------------------------------------------

    final categoryRows = await supabase
        .from('menu_categories')
        .select(
          '''
          id,
          name,
          display_order,
          is_active
          ''',
        )
        .order(
          'display_order',
          ascending: true,
        );

    // ---------------------------------------------------------
    // 메뉴
    //
    // 숨김/품절 메뉴도 관리해야 하므로 전부 가져온다.
    // ---------------------------------------------------------

    final menuRows = await supabase
        .from('menus')
        .select(
          '''
          id,
          category_id,
          name,
          english_name,
          description,
          price,
          badge,
          image_url,
          display_order,
          is_available,
          is_active
          ''',
        )
        .eq(
          'is_deleted',
          false,
        )
        .order(
          'display_order',
          ascending: true,
        );

    final categories = categoryRows
        .map(
          (row) => MenuCategoryItem.fromMap(
            row,
          ),
        )
        .toList();

    final menus = menuRows
        .map(
          (row) => StaffMenuItem.fromMap(
            row,
          ),
        )
        .toList();

    return MenuManagementData(
      categories: categories,
      menus: menus,
    );
  }

Future<void> refresh() async {
  state = const AsyncLoading();

  state = await AsyncValue.guard(
    _fetchData,
  );
}

Future<List<StaffOptionGroup>>
    fetchOptionGroups() async {
  final supabase =
      Supabase.instance.client;

  final rows = await supabase
      .from('option_groups')
      .select(
        '''
        id,
        name,
        selection_type,
        is_required,
        min_select,
        max_select,
        display_order,
        is_active,
        option_items (
          id,
          name,
          additional_price,
          display_order,
          is_active,
          is_deleted
        )
        ''',
      )
      .eq(
        'is_deleted',
        false,
      )
      .eq(
        'option_items.is_deleted',
        false,
      )
      .order(
        'display_order',
        ascending: true,
      );

  return rows
      .map(
        (row) => StaffOptionGroup.fromMap(
          row,
        ),
      )
      .toList();
}

Future<Set<String>>
    fetchLinkedOptionGroupIds(
  String menuId,
) async {
  final supabase =
      Supabase.instance.client;

  final rows = await supabase
      .from('menu_option_groups')
      .select('option_group_id')
      .eq('menu_id', menuId)
      .eq('is_active', true);

  return rows
      .map(
        (row) =>
            row['option_group_id']
                as String,
      )
      .toSet();
}


Future<String> saveOptionGroup({
  String? optionGroupId,
  required String name,
  required String selectionType,
  required bool isRequired,
  required int minSelect,
  required int maxSelect,
  required bool isActive,
  required List<OptionItemSaveInput> items,
}) async {
  final supabase =
      Supabase.instance.client;

  late final String savedGroupId;

  // =========================================================
  // 1. 옵션 그룹 신규 등록 / 수정
  // =========================================================

  if (optionGroupId == null) {
    final lastGroupRows = await supabase
        .from('option_groups')
        .select('display_order')
        .order(
          'display_order',
          ascending: false,
        )
        .limit(1);

    int nextDisplayOrder = 0;

    if (lastGroupRows.isNotEmpty) {
      final lastOrder =
          lastGroupRows.first['display_order']
                  as int? ??
              0;

      nextDisplayOrder =
          lastOrder + 1;
    }

    final inserted = await supabase
        .from('option_groups')
        .insert({
          'name': name.trim(),
          'selection_type':
              selectionType,
          'is_required':
              isRequired,
          'min_select':
              minSelect,
          'max_select':
              maxSelect,
          'display_order':
              nextDisplayOrder,
          'is_active':
              isActive,
        })
        .select('id')
        .single();

    savedGroupId =
        inserted['id'] as String;
  } else {
    await supabase
        .from('option_groups')
        .update({
          'name': name.trim(),
          'selection_type':
              selectionType,
          'is_required':
              isRequired,
          'min_select':
              minSelect,
          'max_select':
              maxSelect,
          'is_active':
              isActive,
        })
        .eq(
          'id',
          optionGroupId,
        );

    savedGroupId =
        optionGroupId;
  }

  // =========================================================
  // 2. 현재 DB에 존재하는 옵션 항목 조회
  // =========================================================

 final existingRows = await supabase
    .from('option_items')
    .select('id')
    .eq(
      'option_group_id',
      savedGroupId,
    )
    .eq(
      'is_deleted',
      false,
    );

  final existingIds = existingRows
      .map(
        (row) => row['id'] as String,
      )
      .toSet();

  // =========================================================
  // 3. 폼에 남아 있는 옵션 항목 저장
  // =========================================================

  final submittedExistingIds =
      <String>{};

  for (int index = 0;
      index < items.length;
      index++) {
    final item = items[index];

    final trimmedName =
        item.name.trim();

    if (trimmedName.isEmpty) {
      continue;
    }

    if (item.id == null) {
      // -------------------------------------------------------
      // 신규 옵션 항목
      // -------------------------------------------------------

      await supabase
          .from('option_items')
          .insert({
            'option_group_id':
                savedGroupId,
            'name':
                trimmedName,
            'additional_price':
                item.additionalPrice,
            'display_order':
                index,
            'is_active':
                item.isActive,
          });
    } else {
      // -------------------------------------------------------
      // 기존 옵션 항목 수정
      // -------------------------------------------------------

      submittedExistingIds.add(
        item.id!,
      );

      await supabase
          .from('option_items')
          .update({
            'name':
                trimmedName,
            'additional_price':
                item.additionalPrice,
            'display_order':
                index,
            'is_active':
                item.isActive,
          })
          .eq(
            'id',
            item.id!,
          )
          .eq(
            'option_group_id',
            savedGroupId,
          );
    }
  }

  // =========================================================
  // 4. 폼에서 제거된 기존 옵션 항목 → soft delete
  // =========================================================

  final removedIds =
      existingIds.difference(
    submittedExistingIds,
  );

  for (final removedId
      in removedIds) {
    await supabase
        .from('option_items')
        .update({
          'is_active': false,
          'is_deleted': true,
        })
        .eq(
          'id',
          removedId,
        )
        .eq(
          'option_group_id',
          savedGroupId,
        );
  }

  return savedGroupId;
}


// =============================================================
// 옵션 그룹 삭제
// =============================================================

Future<void> deleteOptionGroup({
  required String optionGroupId,
}) async {
  final supabase =
      Supabase.instance.client;

  await supabase
      .from('option_groups')
      .update({
        'is_active': false,
        'is_deleted': true,
      })
      .eq(
        'id',
        optionGroupId,
      );

  await supabase
      .from('menu_option_groups')
      .update({
        'is_active': false,
      })
      .eq(
        'option_group_id',
        optionGroupId,
      );
}


// =============================================================
// 메뉴 저장
// =============================================================

Future<String> saveMenu({
  String? menuId,
  required String categoryId,
  required String name,
  required String? englishName,
  required String? description,
  required int price,
  required Set<String> optionGroupIds,
}) async {
  final supabase =
      Supabase.instance.client;

  late final String savedMenuId;

  // =========================================================
  // 1. 메뉴 신규 등록 / 수정
  // =========================================================

  if (menuId == null) {
    final lastMenuRows = await supabase
        .from('menus')
        .select('display_order')
        .eq(
          'category_id',
          categoryId,
        )
        .order(
          'display_order',
          ascending: false,
        )
        .limit(1);

    int nextDisplayOrder = 0;

    if (lastMenuRows.isNotEmpty) {
      final lastOrder =
          lastMenuRows.first[
                  'display_order']
              as int? ??
              0;

      nextDisplayOrder =
          lastOrder + 1;
    }

    final inserted = await supabase
        .from('menus')
        .insert({
          'category_id':
              categoryId,
          'name':
              name.trim(),
          'english_name':
              _nullableText(
            englishName,
          ),
          'description':
              _nullableText(
            description,
          ),
          'price':
              price,
          'display_order':
              nextDisplayOrder,
          'is_available':
              true,
          'is_active':
              true,
        })
        .select('id')
        .single();

    savedMenuId =
        inserted['id'] as String;
  } else {
    await supabase
        .from('menus')
        .update({
          'category_id':
              categoryId,
          'name':
              name.trim(),
          'english_name':
              _nullableText(
            englishName,
          ),
          'description':
              _nullableText(
            description,
          ),
          'price':
              price,
          'updated_at':
              DateTime.now()
                  .toUtc()
                  .toIso8601String(),
        })
        .eq('id', menuId);

    savedMenuId = menuId;
  }

  // =========================================================
  // 2. 현재 메뉴 ↔ 옵션 그룹 연결 조회
  // =========================================================

  final existingRows = await supabase
      .from('menu_option_groups')
      .select(
        '''
        option_group_id,
        display_order
        ''',
      )
      .eq(
        'menu_id',
        savedMenuId,
      );

  final existingIds = existingRows
      .map(
        (row) =>
            row['option_group_id']
                as String,
      )
      .toSet();

  // =========================================================
  // 3. 새로 체크된 옵션 그룹 추가
  // =========================================================

  final addedIds =
      optionGroupIds
          .difference(existingIds);

  for (final optionGroupId
      in addedIds) {
    final groupRow = await supabase
        .from('option_groups')
        .select('display_order')
        .eq(
          'id',
          optionGroupId,
        )
        .single();

    await supabase
        .from('menu_option_groups')
        .insert({
          'menu_id':
              savedMenuId,
          'option_group_id':
              optionGroupId,
          'display_order':
              groupRow[
                      'display_order']
                  as int? ??
                  0,
          'is_active':
              true,
        });
  }

  // =========================================================
  // 4. 체크 해제된 옵션 그룹 연결 제거
  // =========================================================

  final removedIds =
      existingIds
          .difference(optionGroupIds);

  for (final optionGroupId
      in removedIds) {
    await supabase
        .from('menu_option_groups')
        .delete()
        .eq(
          'menu_id',
          savedMenuId,
        )
        .eq(
          'option_group_id',
          optionGroupId,
        );
  }

  // =========================================================
  // 5. 관리자 메뉴 목록 새로고침
  // =========================================================

  state = await AsyncValue.guard(
    _fetchData,
  );

  return savedMenuId;
}


Future<void> deleteMenu({
  required String menuId,
}) async {
  final supabase =
      Supabase.instance.client;

  await supabase
      .from('menus')
      .update({
        'is_active': false,
        'is_available': false,
        'is_deleted': true,
        'updated_at':
            DateTime.now()
                .toUtc()
                .toIso8601String(),
      })
      .eq(
        'id',
        menuId,
      );

}


Future<void> updateMenuQuickSettings({
  required String menuId,
  required bool isActive,
  required bool isAvailable,
  required String? badge,
}) async {
  final supabase = Supabase.instance.client;

  await supabase
      .from('menus')
      .update({
        'is_active': isActive,
        'is_available': isAvailable,
        'badge': badge,
        'updated_at':
            DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', menuId);

  await refresh();
}




Future<String> uploadMenuImage({
  required String menuId,
  required Uint8List bytes,
  required String fileName,
}) async {
  final supabase = Supabase.instance.client;

  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : 'jpg';

  final storagePath =
      '$menuId/${DateTime.now().millisecondsSinceEpoch}.$extension';

  await supabase.storage
      .from('menu-images')
      .uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _imageContentType(extension),
          upsert: false,
        ),
      );

  final imageUrl = supabase.storage
      .from('menu-images')
      .getPublicUrl(storagePath);

  await supabase
      .from('menus')
      .update({
        'image_url': imageUrl,
        'updated_at':
            DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', menuId);

  await refresh();

  return imageUrl;
}


}


String? _nullableText(
  String? value,
) {
  if (value == null) {
    return null;
  }

  final trimmed =
      value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}


String _imageContentType(String extension) {
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'jpeg':
    case 'jpg':
    default:
      return 'image/jpeg';
  }
}

// =============================================================
// Provider 선언
// =============================================================

final menuManagementProvider =
    AsyncNotifierProvider<
        MenuManagementNotifier,
        MenuManagementData>(
  MenuManagementNotifier.new,
);