import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_edit_list.dart';
import 'menu_form.dart';
import 'menu_management_provider.dart';

enum MenuEditMode {
  list,
  create,
  edit,
}

class MenuEditSection
    extends ConsumerStatefulWidget {
  const MenuEditSection({
    super.key,
    required this.onMenuDeleted,
  });

  final VoidCallback onMenuDeleted;

  @override
  ConsumerState<MenuEditSection> createState() =>
      _MenuEditSectionState();
}

class _MenuEditSectionState
    extends ConsumerState<MenuEditSection> {
  MenuEditMode mode = MenuEditMode.list;
  StaffMenuItem? editingMenu;

  void startCreate() {
    setState(() {
      mode = MenuEditMode.create;
      editingMenu = null;
    });
  }

  void startEdit(StaffMenuItem menu) {
    setState(() {
      mode = MenuEditMode.edit;
      editingMenu = menu;
    });
  }

  void backToList() {
    setState(() {
      mode = MenuEditMode.list;
      editingMenu = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync =
        ref.watch(menuManagementProvider);

    return dataAsync.when(
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Text(
            '메뉴 데이터를 불러오지 못했습니다.\n$error',
            textAlign: TextAlign.center,
          ),
        );
      },
      data: (data) {
        if (mode == MenuEditMode.list) {
          return MenuEditList(
            menus: data.menus,
            onCreate: startCreate,
            onEdit: startEdit,
          );
        }

        return MenuForm(
  menu: editingMenu,
  categories: data.categories,
  onClose: backToList,
  onDeleted: widget.onMenuDeleted,
);
      },
    );
  }
}


