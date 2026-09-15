import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menu_management_provider.dart';

class MenuListSection extends ConsumerStatefulWidget {
  const MenuListSection({super.key});

  @override
  ConsumerState<MenuListSection> createState() =>
      _MenuListSectionState();
}

class _MenuListSectionState
    extends ConsumerState<MenuListSection> {
  String? selectedCategoryId;

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
        final categories = data.categories;
        final menus = data.menus;

        if (categories.isEmpty) {
          return Center(
            child: Text(
              '등록된 카테고리가 없습니다.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        selectedCategoryId ??=
            categories.first.id;

        final selectedMenus = menus
            .where(
              (menu) =>
                  menu.categoryId ==
                  selectedCategoryId,
            )
            .toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                scrollDirection:
                    Axis.horizontal,
                itemCount:
                    categories.length,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(
                  width: 24,
                ),
                itemBuilder:
                    (context, index) {
                  final category =
                      categories[index];

                  final selected =
                      category.id ==
                      selectedCategoryId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategoryId =
                            category.id;
                      });
                    },
                    child: Center(
                      child: Text(
                        category.name,
                        style: AppTextStyles
                            .caption
                            .copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors
                                  .textPrimary,
                          fontWeight:
                              selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child:
                  selectedMenus.isEmpty
                      ? Center(
                          child: Text(
                            '이 카테고리에 등록된 메뉴가 없습니다.',
                            style:
                                AppTextStyles
                                    .bodyMedium,
                          ),
                        )
                      : GridView.builder(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            20,
                            0,
                            20,
                            24,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing:
                                12,
                            mainAxisSpacing:
                                12,
                            childAspectRatio:
                                0.78,
                          ),
                          itemCount:
                              selectedMenus
                                  .length,
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final menu =
                                selectedMenus[
                                    index];

                            return _MenuCard(
                              menu: menu,
                              onTap: () {
                                _showMenuQuickSettings(
                                  context,
                                  menu,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMenuQuickSettings(
    BuildContext context,
    StaffMenuItem menu,
  ) async {
    bool isActive = menu.isActive;
    bool isAvailable = menu.isAvailable;
    String? selectedBadge = menu.badge;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(

                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                
              title: Text(
                menu.name,
                style:
                    AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('메뉴 노출'),
  subtitle: Text(
    isActive
        ? '고객 화면에 표시됩니다.'
        : '고객 화면에서 숨겨집니다.',
  ),
  value: isActive,
  activeColor: AppColors.primary,
  activeTrackColor:
      AppColors.primary.withValues(
    alpha: 0.35,
  ),
  onChanged: (value) {
    setDialogState(() {
      isActive = value;
    });
  },
),

                    const Divider(),

                    SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('판매 가능'),
  subtitle: Text(
    isAvailable
        ? '현재 주문 가능합니다.'
        : '품절 상태입니다.',
  ),
  value: isAvailable,
  activeColor: AppColors.primary,
  activeTrackColor:
      AppColors.primary.withValues(
    alpha: 0.35,
  ),
  onChanged: (value) {
    setDialogState(() {
      isAvailable = value;
    });
  },
),

                    const Divider(),

                    const SizedBox(height: 8),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        '뱃지',
                        style: AppTextStyles
                            .bodyMedium
                            .copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<
                        String?>(
                      value: selectedBadge,
                      decoration:
                          InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(8),
                          borderSide:
                              BorderSide(
                            color:
                                AppColors.border,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(8),
                          borderSide:
                              BorderSide(
                            color:
                                AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<
                            String?>(
                          value: null,
                          child: Text('없음'),
                        ),
                        DropdownMenuItem<
                            String?>(
                          value: 'NEW',
                          child: Text('NEW'),
                        ),
                        DropdownMenuItem<
                            String?>(
                          value: 'BEST',
                          child: Text('BEST'),
                        ),
                        DropdownMenuItem<
                            String?>(
                          value: '인기',
                          child: Text('인기'),
                        ),
                        DropdownMenuItem<
                            String?>(
                          value: '시즌',
                          child: Text('시즌'),
                        ),
                        DropdownMenuItem<
                            String?>(
                          value: '추천',
                          child: Text('추천'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedBadge =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                  ),
                  onPressed: () {
                    Navigator.of(
                            dialogContext)
                        .pop(false);
                  },
                  child:
                      const Text('취소'),
                ),
                FilledButton(
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(
                            dialogContext)
                        .pop(true);
                  },
                  child:
                      const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    try {
      await ref
          .read(
            menuManagementProvider.notifier,
          )
          .updateMenuQuickSettings(
            menuId: menu.id,
            isActive: isActive,
            isAvailable: isAvailable,
            badge: selectedBadge,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${menu.name} 설정이 저장되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '메뉴 설정 저장 실패: $e',
          ),
        ),
      );
    }
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.menu,
    required this.onTap,
  });

  final StaffMenuItem menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.primary
                            .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(10),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child:
                            menu.imageUrl ==
                                    null
                                ? Icon(
                                    Icons
                                        .icecream_outlined,
                                    size: 48,
                                    color:
                                        AppColors
                                            .primary,
                                  )
                                : ClipRRect(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                    child:
                                        Image.network(
                                      menu.imageUrl!,
                                      width:
                                          double
                                              .infinity,
                                      height:
                                          double
                                              .infinity,
                                      fit: BoxFit
                                          .cover,
                                    ),
                                  ),
                      ),

                      if (menu.badge !=
                              null &&
                          menu.badge!
                              .trim()
                              .isNotEmpty)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors
                                      .primary,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              menu.badge!,
                              style:
                                  AppTextStyles
                                      .caption
                                      .copyWith(
                                color:
                                    Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                menu.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: AppTextStyles
                    .bodyMedium
                    .copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              if (menu.englishName !=
                      null &&
                  menu.englishName!
                      .isNotEmpty)
                Text(
                  menu.englishName!,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      AppTextStyles.caption,
                ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatPrice(menu.price)}원',
                      style:
                          AppTextStyles
                              .caption
                              .copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  if (!menu.isActive)
                    const _StatusBadge(
                      text: '숨김',
                    )
                  else if (!menu
                      .isAvailable)
                    const _StatusBadge(
                      text: '품절',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _formatPrice(int price) {
  final text = price.toString();
  final buffer = StringBuffer();

  for (int i = 0;
      i < text.length;
      i++) {
    if (i > 0 &&
        (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}