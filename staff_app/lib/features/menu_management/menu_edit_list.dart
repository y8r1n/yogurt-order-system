import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'menu_management_provider.dart';

class MenuEditList extends StatelessWidget {
  const MenuEditList({
    super.key,
    required this.menus,
    required this.onCreate,
    required this.onEdit,
  });

  final List<StaffMenuItem> menus;
  final VoidCallback onCreate;
  final ValueChanged<StaffMenuItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24,
      ),
      itemCount: menus.length + 1,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CreateMenuCard(
            onTap: onCreate,
          );
        }

        final menu = menus[index - 1];

        return _EditMenuCard(
          menu: menu,
          onTap: () {
            onEdit(menu);
          },
        );
      },
    );
  }
}

// =============================================================
// 메뉴 등록 카드
// =============================================================

class _CreateMenuCard extends StatelessWidget {
  const _CreateMenuCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '메뉴 등록',
                style:
                    AppTextStyles.bodyMedium
                        .copyWith(
                  color: AppColors.primary,
                  fontWeight:
                      FontWeight.bold,
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
// 기존 메뉴 수정 카드
// =============================================================

class _EditMenuCard extends StatelessWidget {
  const _EditMenuCard({
    required this.menu,
    required this.onTap,
  });

  final StaffMenuItem menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MenuCardImage(
                  menu: menu,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                menu.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppTextStyles.bodyMedium
                        .copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                menu.englishName ?? '',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppTextStyles.caption,
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatPrice(menu.price)}원',
                style:
                    AppTextStyles.caption
                        .copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCardImage extends StatelessWidget {
  const _MenuCardImage({
    required this.menu,
  });

  final StaffMenuItem menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: menu.imageUrl == null
                ? Center(
                    child: Icon(
                      Icons
                          .icecream_outlined,
                      size: 48,
                      color:
                          AppColors.primary,
                    ),
                  )
                : ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: Image.network(
                      menu.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),

          const Positioned(
            top: 6,
            left: 6,
            child: _StatusBadge(
              text: '메뉴 수정',
              filled: true,
            ),
          ),

          if (!menu.isActive)
            const Positioned(
              top: 6,
              right: 6,
              child: _StatusBadge(
                text: '숨김',
              ),
            )
          else if (!menu.isAvailable)
            const Positioned(
              top: 6,
              right: 6,
              child: _StatusBadge(
                text: '품절',
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// 상태 뱃지
// =============================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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

// =============================================================
// 가격 포맷
// =============================================================

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