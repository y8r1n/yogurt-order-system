import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menu_management_provider.dart';

class OptionGroupForm extends ConsumerStatefulWidget {
  const OptionGroupForm({
    super.key,
    required this.group,
    required this.onClose,
  });

  final StaffOptionGroup? group;
  final VoidCallback onClose;

 @override
ConsumerState<OptionGroupForm> createState() =>
    _OptionGroupFormState();
}

class _OptionGroupFormState
    extends ConsumerState<OptionGroupForm> {
  late final TextEditingController
      nameController;

  late final TextEditingController
      minSelectController;

  late final TextEditingController
      maxSelectController;

  String selectionType = 'multiple';
  bool isRequired = false;
  bool isActive = true;
  bool isSaving = false;

  late List<_EditableOptionItem> items;

  bool get isCreate => widget.group == null;

  @override
  void initState() {
    super.initState();

    final group = widget.group;

    nameController = TextEditingController(
      text: group?.name ?? '',
    );

    
   selectionType =
    group?.selectionType ?? 'multiple';

isRequired =
    group?.isRequired ?? false;

minSelectController =
    TextEditingController(
  text: (group?.minSelect ?? 0).toString(),
);

maxSelectController =
    TextEditingController(
  text: (group?.maxSelect ?? 1).toString(),
);

isActive =
    group?.isActive ?? true;

    items = group?.items
            .map(
              (item) => _EditableOptionItem(
                id: item.id,
                name: item.name,
                additionalPrice:
                    item.additionalPrice,
                isActive: item.isActive,
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    nameController.dispose();
    minSelectController.dispose();
    maxSelectController.dispose();

    super.dispose();
  }

  void _addItem() {
    setState(() {
      items.add(
        const _EditableOptionItem(
          id: null,
          name: '',
          additionalPrice: 0,
          isActive: true,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _updateItemName(
    int index,
    String value,
  ) {
    setState(() {
      items[index] =
          items[index].copyWith(
        name: value,
      );
    });
  }

  void _updateItemPrice(
    int index,
    String value,
  ) {
    final parsed =
        int.tryParse(
          value
              .replaceAll(',', '')
              .trim(),
        ) ??
        0;

    setState(() {
      items[index] =
          items[index].copyWith(
        additionalPrice: parsed,
      );
    });
  }

  void _toggleItemActive(
    int index,
    bool value,
  ) {
    setState(() {
      items[index] =
          items[index].copyWith(
        isActive: value,
      );
    });
  }

  Future<void> _save() async {
  final name =
      nameController.text.trim();

  if (name.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '옵션 그룹명을 입력해주세요.',
        ),
      ),
    );

    return;
  }

  final minSelect =
      int.tryParse(
        minSelectController.text.trim(),
      ) ??
      0;

  final maxSelect =
      int.tryParse(
        maxSelectController.text.trim(),
      ) ??
      1;

  if (minSelect < 0 ||
      maxSelect < 0) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '선택 수는 0 이상이어야 합니다.',
        ),
      ),
    );

    return;
  }

  if (selectionType == 'single' &&
      maxSelect != 1) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '단일 선택 옵션은 최대 선택 수가 1이어야 합니다.',
        ),
      ),
    );

    return;
  }

  if (minSelect > maxSelect) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          '최소 선택 수가 최대 선택 수보다 클 수 없습니다.',
        ),
      ),
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

    await notifier.saveOptionGroup(
      optionGroupId:
          widget.group?.id,
      name: name,
      selectionType:
          selectionType,
      isRequired:
          isRequired,
      minSelect:
          minSelect,
      maxSelect:
          maxSelect,
      isActive:
          isActive,
      items: items
          .map(
            (item) =>
                OptionItemSaveInput(
              id: item.id,
              name: item.name,
              additionalPrice:
                  item.additionalPrice,
              isActive:
                  item.isActive,
            ),
          )
          .toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          isCreate
              ? '옵션 그룹이 등록되었습니다.'
              : '옵션 그룹이 수정되었습니다.',
        ),
      ),
    );

    widget.onClose();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '저장 중 오류가 발생했습니다.\n$e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        100,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: isCreate
                ? '새 옵션 그룹'
                : '옵션 그룹 수정',
            onClose: widget.onClose,
          ),

          const SizedBox(height: 24),

          _SectionTitle(
            text: '기본 정보',
          ),

          const SizedBox(height: 14),

          TextField(
            controller: nameController,
            decoration:
                const InputDecoration(
              labelText: '옵션 그룹명',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          _SelectionTypeSection(
            value: selectionType,
            onChanged: (value) {
              setState(() {
                selectionType = value;

                if (value == 'single') {
                  maxSelectController.text =
                      '1';
                }
              });
            },
          ),

          const SizedBox(height: 18),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            title: const Text(
              '필수 선택',
            ),
            subtitle: Text(
              isRequired
                  ? '고객이 반드시 선택해야 합니다.'
                  : '선택하지 않아도 됩니다.',
              style:
                  AppTextStyles.caption,
            ),
            value: isRequired,
            activeColor:
                AppColors.primary,
            onChanged: (value) {
              setState(() {
                isRequired = value;

                if (value &&
                    minSelectController
                            .text ==
                        '0') {
                  minSelectController
                      .text = '1';
                }
              });
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      minSelectController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        '최소 선택 수',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller:
                      maxSelectController,
                  keyboardType:
                      TextInputType.number,
                  enabled:
                      selectionType !=
                          'single',
                  decoration:
                      const InputDecoration(
                    labelText:
                        '최대 선택 수',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            title: const Text(
              '옵션 그룹 활성화',
            ),
            subtitle: Text(
              isActive
                  ? '메뉴에서 사용할 수 있습니다.'
                  : '숨김 상태입니다.',
              style:
                  AppTextStyles.caption,
            ),
            value: isActive,
            activeColor:
                AppColors.primary,
            onChanged: (value) {
              setState(() {
                isActive = value;
              });
            },
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  text: '옵션 항목',
                ),
              ),

              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  '항목 추가',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (items.isEmpty)
            Container(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color:
                      AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '등록된 옵션 항목이 없습니다.',
                  style:
                      AppTextStyles.caption,
                ),
              ),
            )
          else
            Column(
              children:
                  List.generate(
                items.length,
                (index) {
                  final item =
                      items[index];

                  return _OptionItemEditor(
                    key: ValueKey(
                      item.id ??
                          'new_$index',
                    ),
                    item: item,
                    onNameChanged:
                        (value) {
                      _updateItemName(
                        index,
                        value,
                      );
                    },
                    onPriceChanged:
                        (value) {
                      _updateItemPrice(
                        index,
                        value,
                      );
                    },
                    onActiveChanged:
                        (value) {
                      _toggleItemActive(
                        index,
                        value,
                      );
                    },
                    onRemove: () {
                      _removeItem(index);
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 32),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
    isSaving ? null : _save,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child: isSaving
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
    : Text(
        isCreate
            ? '옵션 그룹 등록'
            : '수정 내용 저장',
        style:
            AppTextStyles.button,
      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
                AppTextStyles.titleMedium
                    .copyWith(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        IconButton(
          onPressed: onClose,
          icon: Icon(
            Icons.close,
            color:
                AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          AppTextStyles.bodyMedium
              .copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SelectionTypeSection
    extends StatelessWidget {
  const _SelectionTypeSection({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '선택 방식',
          style:
              AppTextStyles.bodyMedium
                  .copyWith(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  '단일 선택',
                ),
                value: 'single',
                groupValue: value,
                activeColor:
                    AppColors.primary,
                onChanged:
                    (selected) {
                  if (selected !=
                      null) {
                    onChanged(
                      selected,
                    );
                  }
                },
              ),
            ),

            Expanded(
              child: RadioListTile<String>(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  '다중 선택',
                ),
                value: 'multiple',
                groupValue: value,
                activeColor:
                    AppColors.primary,
                onChanged:
                    (selected) {
                  if (selected !=
                      null) {
                    onChanged(
                      selected,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionItemEditor
    extends StatefulWidget {
  const _OptionItemEditor({
    super.key,
    required this.item,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onActiveChanged,
    required this.onRemove,
  });

  final _EditableOptionItem item;

  final ValueChanged<String>
      onNameChanged;

  final ValueChanged<String>
      onPriceChanged;

  final ValueChanged<bool>
      onActiveChanged;

  final VoidCallback onRemove;

  @override
  State<_OptionItemEditor>
      createState() =>
          _OptionItemEditorState();
}

class _OptionItemEditorState
    extends State<_OptionItemEditor> {
  late final TextEditingController
      nameController;

  late final TextEditingController
      priceController;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(
      text: widget.item.name,
    );

    priceController =
        TextEditingController(
      text: widget
          .item.additionalPrice
          .toString(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller:
                      nameController,
                  onChanged:
                      widget
                          .onNameChanged,
                  decoration:
                      const InputDecoration(
                    labelText:
                        '옵션명',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller:
                      priceController,
                  keyboardType:
                      TextInputType.number,
                  textAlign:
                      TextAlign.right,
                  onChanged:
                      widget
                          .onPriceChanged,
                  decoration:
                      const InputDecoration(
                    labelText:
                        '추가금',
                    suffixText: '원',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                onPressed:
                    widget.onRemove,
                tooltip: '항목 제거',
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            dense: true,
            title:
                const Text(
              '항목 활성화',
            ),
            value:
                widget.item.isActive,
            activeColor:
                AppColors.primary,
            onChanged:
                widget
                    .onActiveChanged,
          ),
        ],
      ),
    );
  }
}

class _EditableOptionItem {
  const _EditableOptionItem({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.isActive,
  });

  final String? id;
  final String name;
  final int additionalPrice;
  final bool isActive;

  _EditableOptionItem copyWith({
    String? name,
    int? additionalPrice,
    bool? isActive,
  }) {
    return _EditableOptionItem(
      id: id,
      name: name ?? this.name,
      additionalPrice:
          additionalPrice ??
              this.additionalPrice,
      isActive:
          isActive ??
              this.isActive,
    );
  }
}