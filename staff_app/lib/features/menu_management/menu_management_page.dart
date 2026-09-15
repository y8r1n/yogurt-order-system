import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_management_provider.dart';
import 'menu_list_section.dart';
import 'menu_edit_section.dart';

import 'menu_option_edit_section.dart';

enum MenuManagementTab {
  menuList,
  menuEdit,
  optionEdit,
}

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() =>
      _MenuManagementPageState();
}

class _MenuManagementPageState
    extends State<MenuManagementPage> {
  MenuManagementTab selectedTab =
      MenuManagementTab.menuList;

  void selectTab(MenuManagementTab tab) {
    setState(() {
      selectedTab = tab;
    });
  }

  void goToMenuList() {
  setState(() {
    selectedTab = MenuManagementTab.menuList;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =========================================================
      // 본문
      // =========================================================
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ===================================================
            // 로고
            // ===================================================
            Text(
              'YOGURTWORLD',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 24),

            // ===================================================
            // 최상단 탭
            // 오늘의 주문 / 지난 주문 / 메뉴 관리
            // ===================================================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  _TopTab(
                    title: '오늘의 주문',
                    selected: false,
                    onTap: () {
                      context.go('/');
                    },
                  ),
                  _TopTab(
                    title: '지난 주문',
                    selected: false,
                    onTap: () {
                      context.go('/history');
                    },
                  ),
                  _TopTab(
                    title: '메뉴 관리',
                    selected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            // ===================================================
            // 메뉴 관리 내용
            // ===================================================
            Expanded(
              child: IndexedStack(
                index: selectedTab.index,
               children: [
  const MenuListSection(),

  MenuEditSection(
    onMenuDeleted: goToMenuList,
  ),

  const MenuOptionEditSection(),
],
              ),
            ),
          ],
        ),
      ),

      // =========================================================
      // 하단 메뉴 관리 네비게이터
      // =========================================================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomManagementTab(
                  title: '메뉴 목록',
                  selected:
                      selectedTab ==
                      MenuManagementTab.menuList,
                  onTap: () {
                    selectTab(
                      MenuManagementTab.menuList,
                    );
                  },
                ),
              ),
              Expanded(
                child: _BottomManagementTab(
                  title: '메뉴 등록/수정',
                  selected:
                      selectedTab ==
                      MenuManagementTab.menuEdit,
                  onTap: () {
                    selectTab(
                      MenuManagementTab.menuEdit,
                    );
                  },
                ),
              ),
              Expanded(
                child: _BottomManagementTab(
                  title: '옵션 편집',
                  selected:
                      selectedTab ==
                      MenuManagementTab.optionEdit,
                  onTap: () {
                    selectTab(
                      MenuManagementTab.optionEdit,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 최상단 탭
// =============================================================

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected
                  ? AppColors.primary
                  : AppColors.textPrimary,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 하단 메뉴 관리 탭
// =============================================================

class _BottomManagementTab extends StatelessWidget {
  const _BottomManagementTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected
                ? AppColors.primary
                : AppColors.textPrimary,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}