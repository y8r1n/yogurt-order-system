import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menu_management_provider.dart';

// =============================================================
// 메뉴 등록/수정 폼
// =============================================================

class MenuForm extends ConsumerStatefulWidget {
  const MenuForm({
    super.key,
    required this.menu,
    required this.categories,
    required this.onClose,
    required this.onDeleted,
  });

  final StaffMenuItem? menu;
  final List<MenuCategoryItem> categories;
  final VoidCallback onClose;
  final VoidCallback onDeleted;

  @override
  ConsumerState<MenuForm> createState() =>
      _MenuFormState();
}

class _MenuFormState
    extends ConsumerState<MenuForm> {
  late final TextEditingController nameController;
  late final TextEditingController englishNameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;

String? selectedCategoryId;

Uint8List? selectedImageBytes;
String? selectedImageName;

List<StaffOptionGroup> optionGroups = [];
Set<String> selectedOptionGroupIds = {};

  bool isLoadingOptions = true;
  bool isSaving = false;
  String? optionLoadError;

  bool get isCreate => widget.menu == null;

  @override
  void initState() {
    super.initState();

    final menu = widget.menu;

    selectedCategoryId =
        menu?.categoryId ??
        (widget.categories.isNotEmpty
            ? widget.categories.first.id
            : null);

    nameController = TextEditingController(
      text: menu?.name ?? '',
    );

    englishNameController =
        TextEditingController(
      text: menu?.englishName ?? '',
    );

    descriptionController =
        TextEditingController(
      text: menu?.description ?? '',
    );

    priceController = TextEditingController(
      text: menu == null
          ? ''
          : menu.price.toString(),
    );

    Future.microtask(
      _loadOptionGroups,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    englishNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    super.dispose();
  }

  // -----------------------------------------------------------
  // 옵션 그룹 로딩
  // -----------------------------------------------------------

  Future<void> _loadOptionGroups() async {
    setState(() {
      isLoadingOptions = true;
      optionLoadError = null;
    });

    try {
      final notifier = ref.read(
        menuManagementProvider.notifier,
      );

      final groups =
          await notifier.fetchOptionGroups();

      Set<String> linkedIds = {};

      if (widget.menu != null) {
        linkedIds =
            await notifier.fetchLinkedOptionGroupIds(
          widget.menu!.id,
        );
      }

      if (!mounted) return;

      setState(() {
        optionGroups = groups;
        selectedOptionGroupIds = linkedIds;
        isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        optionLoadError = e.toString();
        isLoadingOptions = false;
      });
    }
  }

  // -----------------------------------------------------------
  // 저장
  // -----------------------------------------------------------

  Future<void> _saveMenu() async {
    if (isSaving) return;

    final categoryId =
        selectedCategoryId;

    if (categoryId == null) {
      _showMessage(
        '카테고리를 선택해주세요.',
      );
      return;
    }

    final name =
        nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        '메뉴명을 입력해주세요.',
      );
      return;
    }

    final price = int.tryParse(
      priceController.text
          .replaceAll(',', '')
          .trim(),
    );

    if (price == null || price < 0) {
      _showMessage(
        '가격을 확인해주세요.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final notifier = ref.read(
  menuManagementProvider.notifier,
);

final savedMenuId = await notifier.saveMenu(
  menuId: widget.menu?.id,
  categoryId: categoryId,
  name: name,
  englishName:
      englishNameController.text,
  description:
      descriptionController.text,
  price: price,
  optionGroupIds:
      selectedOptionGroupIds,
);

if (selectedImageBytes != null &&
    selectedImageName != null) {
  await notifier.uploadMenuImage(
    menuId: savedMenuId,
    bytes: selectedImageBytes!,
    fileName: selectedImageName!,
  );
}

      if (!mounted) return;

      _showMessage(
        isCreate
            ? '메뉴가 등록되었습니다.'
            : '메뉴가 수정되었습니다.',
      );

      widget.onClose();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        '저장 중 오류가 발생했습니다.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }


  Future<void> _deleteMenu() async {
  final menu = widget.menu;

  if (menu == null || isSaving) {
    return;
  }

  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          '메뉴 삭제',
        ),
        content: Text(
          '\'${menu.name}\' 메뉴를 삭제하시겠습니까?\n\n'
          '삭제된 메뉴는 고객 화면과 관리자 목록에서 사라집니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext)
                  .pop(true);
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !mounted) {
    return;
  }

  setState(() {
    isSaving = true;
  });

  try {
    final notifier = ref.read(
      menuManagementProvider.notifier,
    );

    await notifier.deleteMenu(
      menuId: menu.id,
    );

    if (!mounted) return;

   _showMessage(
  '\'${menu.name}\' 메뉴가 삭제되었습니다.',
);

widget.onDeleted();


await notifier.refresh();

    widget.onClose();
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      '메뉴 삭제 중 오류가 발생했습니다.\n$e',
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}



 Future<void> _addCategory() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '카테고리명',
              hintText: '예: 시즌 메뉴',
            ),
            onSubmitted: (_) {
              final value = controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || !mounted) return;

    try {
      final categoryId = await ref
          .read(menuManagementProvider.notifier)
          .addCategory(name: name);

      if (!mounted) return;

      setState(() {
        selectedCategoryId = categoryId;
      });

      _showMessage('카테고리가 추가되었습니다.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        '카테고리 추가 중 오류가 발생했습니다.\n$e',
      );
    }
  }

Future<void> _showCategoryEditDialog() async {
 final data = ref.read(menuManagementProvider).value;

  if (data == null) {
    _showMessage('카테고리 정보를 불러오지 못했습니다.');
    return;
  }

  final activeCategories = data.categories
      .where((category) => category.isActive)
      .toList();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _CategoryEditDialog(
        categories: activeCategories,
      );
    },
  );
}


  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }


Future<void> _pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) {
    return;
  }

  final file = result.files.single;
  final bytes = file.bytes;

  if (bytes == null) {
    _showMessage('이미지를 불러오지 못했습니다.');
    return;
  }

  setState(() {
    selectedImageBytes = bytes;
    selectedImageName = file.name;
  });
}


  void _toggleOptionGroup(
    String groupId,
  ) {
    setState(() {
      if (selectedOptionGroupIds
          .contains(groupId)) {
        selectedOptionGroupIds
            .remove(groupId);
      } else {
        selectedOptionGroupIds
            .add(groupId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        32,
        0,
        32,
        120,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _FormHeader(
            title: isCreate
                ? '새 메뉴 등록'
                : '메뉴 수정',
            onClose: widget.onClose,
          ),

          const SizedBox(height: 20),

         _CategorySection(
  categories: widget.categories,
  selectedCategoryId: selectedCategoryId,
  onChanged: (categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
  },
  onAddCategory: _addCategory,
  onEditCategory: _showCategoryEditDialog,
),

          const SizedBox(height: 36),

          _MenuImagePreview(
  imageUrl: widget.menu?.imageUrl,
  selectedImageBytes: selectedImageBytes,
  onTap: _pickImage,
),

          const SizedBox(height: 24),

          _MenuBasicFields(
            nameController:
                nameController,
            englishNameController:
                englishNameController,
            descriptionController:
                descriptionController,
            priceController:
                priceController,
          ),

          const SizedBox(height: 36),

          _SectionLabel(
            text: '옵션 선택',
          ),

          const SizedBox(height: 20),

          _OptionGroupsSection(
            groups: optionGroups,
            selectedIds:
                selectedOptionGroupIds,
            isLoading:
                isLoadingOptions,
            error:
                optionLoadError,
            onRetry:
                _loadOptionGroups,
            onToggle:
                _toggleOptionGroup,
          ),

          const SizedBox(height: 36),

         _SaveButton(
  isSaving: isSaving,
  onPressed: _saveMenu,
),

if (!isCreate) ...[
  const SizedBox(height: 20),

  _DeleteMenuButton(
    isSaving: isSaving,
    onPressed: _deleteMenu,
  ),
],
        ],
      ),
    );
  }
}
// =============================================================
// 폼 상단
// =============================================================

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(
            Icons.close,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// 카테고리
// =============================================================

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.onAddCategory,
    required this.onEditCategory,
  });

  final List<MenuCategoryItem> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddCategory;
  final VoidCallback onEditCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
  children: [
    const _SectionLabel(text: '카테고리'),
    const Spacer(),

    TextButton.icon(
      onPressed: onAddCategory,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('카테고리 추가'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),

    const SizedBox(width: 8),

    TextButton.icon(
      onPressed: onEditCategory,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('카테고리 수정'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),
  ],
),

        const SizedBox(height: 16),

        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: categories.map(
            (category) {
              final selected =
                  selectedCategoryId ==
                      category.id;

              return InkWell(
                onTap: () {
                  onChanged(
                    category.id,
                  );
                },
                borderRadius:
                    BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons
                                .radio_button_checked
                            : Icons
                                .radio_button_unchecked,
                        size: 19,
                        color:
                            AppColors.primary,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        category.name,
                        style:
                            AppTextStyles.caption
                                .copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors
                                  .textPrimary,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .bold
                                  : FontWeight
                                      .normal,
                        ),
                      ),

                      if (!category
                          .isActive) ...[
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '숨김',
                          style:
                              AppTextStyles.caption
                                  .copyWith(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

class _CategoryEditDialog extends ConsumerStatefulWidget {
  const _CategoryEditDialog({
    required this.categories,
  });

  final List<MenuCategoryItem> categories;

  @override
  ConsumerState<_CategoryEditDialog> createState() =>
      _CategoryEditDialogState();
}

class _CategoryEditDialogState
    extends ConsumerState<_CategoryEditDialog> {
  late List<MenuCategoryItem> categories;

  final Set<String> selectedCategoryIds = {};
bool isSaving = false;

  @override
  void initState() {
    super.initState();

    categories = List<MenuCategoryItem>.from(
      widget.categories,
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);
    });
  }

  Future<void> _deleteSelectedCategories() async {
  if (selectedCategoryIds.isEmpty) {
    return;
  }

  final selectedCategories = categories
      .where(
        (category) =>
            selectedCategoryIds.contains(category.id),
      )
      .toList();

  final categoryNames = selectedCategories
      .map((category) => category.name)
      .join(', ');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) {
      return AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(
          '선택한 ${selectedCategories.length}개의 카테고리를 '
          '삭제하시겠습니까?\n\n'
          '$categoryNames\n\n'
          '키오스크에서는 숨겨지며, '
          '카테고리에 포함된 메뉴 데이터는 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(confirmContext).pop(false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(confirmContext).pop(true);
            },
            child: const Text('삭제'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !mounted) {
    return;
  }

  try {
    for (final category in selectedCategories) {
      await ref
          .read(menuManagementProvider.notifier)
          .deleteCategory(category.id);
    }

    if (!mounted) return;

    setState(() {
      categories.removeWhere(
        (category) =>
            selectedCategoryIds.contains(category.id),
      );

      selectedCategoryIds.clear();
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '카테고리 삭제 중 오류가 발생했습니다.\n$e',
        ),
      ),
    );
  }
}



  Future<void> _saveOrder() async {
    setState(() {
      isSaving = true;
    });

    try {
      await ref
          .read(menuManagementProvider.notifier)
          .reorderCategories(categories);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카테고리 순서 저장 중 오류가 발생했습니다.\n$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('카테고리 수정'),

      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '드래그하여 카테고리 노출 순서를 변경할 수 있습니다.',
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ReorderableListView.builder(
                itemCount: categories.length,
                onReorder: _reorder,
               itemBuilder: (context, index) {
  final category = categories[index];

  final isSelected =
      selectedCategoryIds.contains(category.id);

  return ListTile(
    key: ValueKey(category.id),

    onTap: () {
      setState(() {
        if (selectedCategoryIds.contains(category.id)) {
          selectedCategoryIds.remove(category.id);
        } else {
          selectedCategoryIds.add(category.id);
        }
      });
    },

    selected: isSelected,

    leading: const Icon(
      Icons.drag_handle,
    ),

    title: Text(category.name),

    trailing: isSelected
        ? const Icon(Icons.check)
        : null,
  );
},
              ),
            ),

            if (selectedCategoryIds.isNotEmpty) ...[
  const Divider(),

  Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: _deleteSelectedCategories,
      icon: const Icon(
        Icons.delete_outline,
      ),
      label: Text(
        '선택한 카테고리 삭제 (${selectedCategoryIds.length})',
      ),
    ),
  ),
],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),

        ElevatedButton(
          onPressed: isSaving ? null : _saveOrder,
          child: Text(
            isSaving ? '저장 중...' : '순서 저장',
          ),
        ),
      ],
    );
  }
}

// =============================================================
// 이미지
// =============================================================

class _MenuImagePreview extends StatelessWidget {
  const _MenuImagePreview({
    required this.imageUrl,
    required this.selectedImageBytes,
    required this.onTap,
  });

  final String? imageUrl;
  final Uint8List? selectedImageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 150,
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: _buildImage(),
            ),
          ),

          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              size: 18,
            ),
            label: Text(
              selectedImageBytes != null ||
                      imageUrl != null
                  ? '이미지 변경'
                  : '이미지 등록',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (selectedImageBytes != null) {
      return Image.memory(
        selectedImageBytes!,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl != null &&
        imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Icon(
      Icons.icecream_outlined,
      size: 72,
      color: AppColors.primary,
    );
  }
}

// =============================================================
// 기본 입력
// =============================================================

class _MenuBasicFields extends StatelessWidget {
  const _MenuBasicFields({
    required this.nameController,
    required this.englishNameController,
    required this.descriptionController,
    required this.priceController,
  });

  final TextEditingController nameController;
  final TextEditingController
      englishNameController;
  final TextEditingController
      descriptionController;
  final TextEditingController priceController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          textAlign: TextAlign.center,
          decoration:
              const InputDecoration(
            labelText: '메뉴명',
            border: InputBorder.none,
          ),
          style:
              AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        TextField(
          controller:
              englishNameController,
          textAlign: TextAlign.center,
          decoration:
              const InputDecoration(
            labelText: '영문명',
            border: InputBorder.none,
          ),
        ),

        const SizedBox(height: 24),

        TextField(
          controller:
              descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: '메뉴 설명',
            alignLabelWithHint: true,
            enabledBorder:
                UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder:
                UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        TextField(
          controller: priceController,
          keyboardType:
              TextInputType.number,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: '가격',
            suffixText: '원',
            enabledBorder:
                UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
            focusedBorder:
                UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// 옵션 그룹
// =============================================================

class _OptionGroupsSection extends StatelessWidget {
  const _OptionGroupsSection({
    required this.groups,
    required this.selectedIds,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onToggle,
  });

  final List<StaffOptionGroup> groups;
  final Set<String> selectedIds;

  final bool isLoading;
  final String? error;

  final VoidCallback onRetry;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Column(
        children: [
          const Text(
            '옵션 그룹을 불러오지 못했습니다.',
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 불러오기'),
          ),
        ],
      );
    }

    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Center(
          child: Text(
            '등록된 옵션 그룹이 없습니다.',
          ),
        ),
      );
    }

    return Column(
      children: groups.map(
        (group) {
          final selected =
              selectedIds.contains(
            group.id,
          );

          return _OptionGroupRow(
            group: group,
            selected: selected,
            onTap: () {
              onToggle(
                group.id,
              );
            },
          );
        },
      ).toList(),
    );
  }
}

class _OptionGroupRow extends StatefulWidget {
  const _OptionGroupRow({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final StaffOptionGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionGroupRow> createState() =>
      _OptionGroupRowState();
}

class _OptionGroupRowState
    extends State<_OptionGroupRow> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final selected = widget.selected;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: AppColors.primary,
                    size: 22,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            style:
                                AppTextStyles.bodyMedium
                                    .copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),

                        if (!group.isActive) ...[
                          const SizedBox(width: 8),
                          const _SmallBadge(
                            text: '숨김',
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (selected)
                    Text(
                      '연결됨',
                      style:
                          AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                34,
                0,
                12,
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  if (group.items.isEmpty)
                    Text(
                      '등록된 옵션 항목이 없습니다.',
                      style:
                          AppTextStyles.caption.copyWith(
                        color: Colors.grey,
                      ),
                    )
                  else
                    ...group.items.map(
                      (item) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style:
                                      AppTextStyles.caption,
                                ),
                              ),

                              Text(
                                item.additionalPrice == 0
                                    ? '추가금 없음'
                                    : '+${_formatPrice(item.additionalPrice)}원',
                                style:
                                    AppTextStyles.caption
                                        .copyWith(
                                  color: AppColors.primary,
                                ),
                              ),

                              if (!item.isActive) ...[
                                const SizedBox(width: 8),
                                const _SmallBadge(
                                  text: '숨김',
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
// =============================================================
// 저장 버튼
// =============================================================

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed:
            isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                '저장하기',
                style:
                    AppTextStyles.button,
              ),
      ),
    );
  }
}

// =============================================================
// 삭제 버튼
// =============================================================

class _DeleteMenuButton
    extends StatelessWidget {
  const _DeleteMenuButton({
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed:
            isSaving ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(
            color: Colors.red,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          '메뉴 삭제',
        ),
      ),
    );
  }
}

// =============================================================
// 공통 작은 UI
// =============================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary
              .withValues(
            alpha: 0.08,
          ),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style:
              AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    this.filled = false,
  });

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary
            : Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled
              ? Colors.white
              : AppColors.primary,
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

  for (int i = 0; i < text.length; i++) {
    if (i > 0 &&
        (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}
