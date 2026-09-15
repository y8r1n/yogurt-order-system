import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menu_management_provider.dart';
import 'option_group_form.dart';

class MenuOptionEditSection
    extends ConsumerStatefulWidget {
  const MenuOptionEditSection({
    super.key,
  });

  @override
  ConsumerState<MenuOptionEditSection>
      createState() =>
          _MenuOptionEditSectionState();
}

class _MenuOptionEditSectionState
    extends ConsumerState<MenuOptionEditSection> {
  List<StaffOptionGroup> groups = [];

  bool isLoading = true;
  String? loadError;

  StaffOptionGroup? editingGroup;
bool isCreating = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(
      _loadOptionGroups,
    );
  }

  Future<void> _loadOptionGroups() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final notifier = ref.read(
        menuManagementProvider.notifier,
      );

      final loadedGroups =
          await notifier.fetchOptionGroups();

      if (!mounted) return;

      setState(() {
        groups = loadedGroups;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _closeFormAndReload() async {
  if (!mounted) return;

  setState(() {
    isCreating = false;
    editingGroup = null;
  });

  await _loadOptionGroups();
}

Future<void> _deleteOptionGroup(
  StaffOptionGroup group,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          '옵션 그룹 삭제',
        ),
        content: Text(
          '\'${group.name}\' 옵션 그룹을 삭제하시겠습니까?\n\n'
          '연결된 메뉴에서는 더 이상 이 옵션 그룹을 사용할 수 없습니다.',
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

  try {
    final notifier = ref.read(
      menuManagementProvider.notifier,
    );

    await notifier.deleteOptionGroup(
      optionGroupId: group.id,
    );

    if (!mounted) return;

    await _loadOptionGroups();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '\'${group.name}\' 옵션 그룹이 삭제되었습니다.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '옵션 그룹 삭제 중 오류가 발생했습니다.\n$e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '옵션 편집',
                  style:
                      AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

             ElevatedButton.icon(
  onPressed: () {
    setState(() {
      isCreating = true;
      editingGroup = null;
    });
  },
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  '새 옵션 그룹',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '옵션 그룹, 옵션 항목 가격, 품절, 숨김 상태 관리',
            style: AppTextStyles.caption,
          ),

          const SizedBox(height: 24),

         Expanded(
  child: isCreating
      ? OptionGroupForm(
  group: null,
  onClose: () {
    _closeFormAndReload();
  },
)
      : editingGroup != null
          ? OptionGroupForm(
  group: editingGroup,
  onClose: () {
    _closeFormAndReload();
  },
)
          : _buildContent(),
),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '옵션 그룹을 불러오지 못했습니다.',
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: _loadOptionGroups,
              child: const Text(
                '다시 불러오기',
              ),
            ),
          ],
        ),
      );
    }

    if (groups.isEmpty) {
      return const Center(
        child: Text(
          '등록된 옵션 그룹이 없습니다.',
        ),
      );
    }

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];

        return _OptionGroupCard(
  group: group,
  onEdit: () {
    setState(() {
      editingGroup = group;
      isCreating = false;
    });
  },
  onDelete: () {
    _deleteOptionGroup(group);
  },
);
      },
    );
  }
}

class _OptionGroupCard
    extends StatefulWidget {
const _OptionGroupCard({
  required this.group,
  required this.onEdit,
  required this.onDelete,
});

final StaffOptionGroup group;
final VoidCallback onEdit;
final VoidCallback onDelete;

  @override
  State<_OptionGroupCard> createState() =>
      _OptionGroupCardState();
}

class _OptionGroupCardState
    extends State<_OptionGroupCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded =
                    !isExpanded;
              });
            },
            borderRadius:
                BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            style:
                                AppTextStyles.bodyMedium
                                    .copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!group.isActive) ...[
                          const SizedBox(
                            width: 8,
                          ),

                          _SmallStatusBadge(
                            text: '숨김',
                          ),
                        ],
                      ],
                    ),
                  ),

                  Text(
  '${group.items.length}개',
  style: AppTextStyles.caption,
),

const SizedBox(width: 8),

TextButton(
  onPressed: widget.onEdit,
  child: const Text('수정'),
),

TextButton(
  onPressed: widget.onDelete,
  child: const Text(
    '삭제',
    style: TextStyle(
      color: Colors.red,
    ),
  ),
),

const SizedBox(width: 4),

Icon(
  isExpanded
      ? Icons.keyboard_arrow_up
      : Icons.keyboard_arrow_down,
  color: AppColors.primary,
),

                ],
              ),
            ),
          ),

          if (isExpanded)
            _OptionItemsPreview(
              items: group.items,
            ),
        ],
      ),
    );
  }
}

class _OptionItemsPreview
    extends StatelessWidget {
  const _OptionItemsPreview({
    required this.items,
  });

  final List<StaffOptionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        child: Align(
          alignment:
              Alignment.centerLeft,
          child: Text(
            '등록된 옵션 항목이 없습니다.',
            style:
                AppTextStyles.caption.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),
      child: Column(
        children: items.map(
          (item) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style:
                                AppTextStyles.bodyMedium,
                          ),
                        ),

                        if (!item.isActive) ...[
                          const SizedBox(
                            width: 8,
                          ),

                          _SmallStatusBadge(
                            text: '숨김',
                          ),
                        ],
                      ],
                    ),
                  ),

                  Text(
                    item.additionalPrice == 0
                        ? '추가금 없음'
                        : '+${_formatPrice(item.additionalPrice)}원',
                    style:
                        AppTextStyles.caption
                            .copyWith(
                      color:
                          AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

class _SmallStatusBadge
    extends StatelessWidget {
  const _SmallStatusBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
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