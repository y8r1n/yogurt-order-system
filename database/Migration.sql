begin;

-- 1. 메뉴 ↔ 옵션 그룹 연결 테이블 생성
create table public.menu_option_groups (

  id uuid primary key default gen_random_uuid(),

  menu_id uuid not null
    references public.menus(id)
    on delete cascade,

  option_group_id uuid not null
    references public.option_groups(id)
    on delete cascade,

  display_order integer not null default 0
    check (display_order >= 0),

  is_required_override boolean,

  min_select_override integer
    check (
      min_select_override is null
      or min_select_override >= 0
    ),

  max_select_override integer
    check (
      max_select_override is null
      or max_select_override >= 1
    ),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),

  updated_at timestamptz not null default now(),

  unique (menu_id, option_group_id),

  constraint menu_option_groups_select_range_check
    check (
      min_select_override is null
      or max_select_override is null
      or max_select_override >= min_select_override
    )
);


-- 2. 기존 option_groups.menu_id 연결을 새 테이블에 복사
insert into public.menu_option_groups (
  menu_id,
  option_group_id,
  display_order,
  is_active
)
select
  menu_id,
  id,
  display_order,
  true
from public.option_groups;


-- 3. updated_at 트리거 추가
create trigger set_menu_option_groups_updated_at
before update on public.menu_option_groups
for each row
execute function public.set_updated_at();


-- 4. 새 인덱스 생성
create index idx_menu_option_groups_menu_display_order
on public.menu_option_groups (
  menu_id,
  is_active,
  display_order
);

create index idx_menu_option_groups_option_group_id
on public.menu_option_groups (
  option_group_id
);


-- 5. 기존 menu_id 기반 인덱스 삭제
drop index if exists public.idx_option_groups_menu_display_order;


-- 6. option_groups.menu_id 제거
alter table public.option_groups
drop column menu_id;

commit;