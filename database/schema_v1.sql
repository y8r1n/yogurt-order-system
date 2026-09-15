-- =========================================================
-- 핵심 테이블 8개 + updated_at 트리거 + 인덱스
-- Yogurt Order System
-- Version: v1.0
-- Date: 2026-07-22
-- Status: NOT EXECUTED
-- =========================================================

begin;

-- 0. 메뉴 카테고리
create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),

  name text not null
    check (char_length(trim(name)) > 0),

  display_order integer not null default 0
    check (display_order >= 0),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- 1. 메뉴
create table public.menus (
  id uuid primary key default gen_random_uuid(),

  category_id uuid not null
    references public.menu_categories(id)
    on delete restrict,

 name text not null
  check (char_length(trim(name)) > 0),

english_name text,

description text,

price integer not null
  check (price >= 0),

badge text,

image_url text,

  display_order integer not null default 0
    check (display_order >= 0),

  -- false면 메뉴판에는 보이지만 품절 처리
  is_available boolean not null default true,

  -- false면 고객 메뉴판에서 숨김
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- 2. 옵션 그룹
-- 예: 사이즈 선택, 토핑 선택
create table public.option_groups (
  id uuid primary key default gen_random_uuid(),

  menu_id uuid not null
    references public.menus(id)
    on delete cascade,

  
  name text not null
    check (char_length(trim(name)) > 0),

  
  selection_type text not null
    check (selection_type in ('single', 'multiple')),

  is_required boolean not null default false,

  min_select integer not null default 0
    check (min_select >= 0),

  max_select integer not null default 1
    check (max_select >= 1),

  display_order integer not null default 0
    check (display_order >= 0),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint option_groups_select_range_check
    check (max_select >= min_select),

  constraint option_groups_single_selection_check
    check (
      selection_type <> 'single'
      or (min_select <= 1 and max_select = 1)
    ),

  constraint option_groups_required_check
    check (
      is_required = false
      or min_select >= 1
    )
);


-- 3. 실제 옵션 항목
-- 예: 기본 사이즈, 라지 / 그래놀라, 바나나
create table public.option_items (
  id uuid primary key default gen_random_uuid(),

  option_group_id uuid not null
    references public.option_groups(id)
    on delete cascade,

  name text not null
    check (char_length(trim(name)) > 0),

  additional_price integer not null default 0
    check (additional_price >= 0),

  -- 한 주문 상품에서 해당 옵션을 최대 몇 개까지 선택 가능한지
  max_quantity integer not null default 1
    check (max_quantity >= 1),

  display_order integer not null default 0
    check (display_order >= 0),

  -- false면 옵션만 품절
  is_available boolean not null default true,

  -- false면 고객 화면에서 숨김
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- 4. 주문
create table public.orders (
  id uuid primary key default gen_random_uuid(),

  order_date date not null
    default ((now() at time zone 'Asia/Seoul')::date),

  order_number integer not null,

  order_type text not null
    check (order_type in ('dine_in', 'take_out')),

  ice_pack boolean not null default false,

  spoon_count integer not null default 0
    check (spoon_count between 0 and 4),

  status text not null default 'pending'
    check (
      status in (
        'pending',
        'accepted',
        'completed',
        'cancelled'
      )
    ),

  subtotal integer not null
    check (subtotal >= 0),

  customer_note text,

  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,

  constraint orders_daily_number_unique
    unique (order_date, order_number),

  constraint orders_takeout_options_check
    check (
      order_type = 'take_out'
      or (
        ice_pack = false
        and spoon_count = 0
      )
    ),

  constraint orders_status_time_check
    check (
      (status <> 'accepted' or accepted_at is not null)
      and
      (status <> 'completed' or completed_at is not null)
      and
      (status <> 'cancelled' or cancelled_at is not null)
    )
);

-- =========================================================
-- 날짜별 주문번호 자동 생성
-- 매일 한국 시간 기준 1번부터 시작
-- =========================================================

create or replace function public.set_daily_order_number()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- 앱에서 날짜를 보내지 않으면 한국 시간 기준 오늘 날짜 사용
  if new.order_date is null then
    new.order_date :=
      (now() at time zone 'Asia/Seoul')::date;
  end if;

  -- 같은 날짜의 주문 생성 작업을 순서대로 처리
  -- 동시에 여러 주문이 들어와도 같은 번호가 생기지 않도록 함
  perform pg_advisory_xact_lock(
    hashtext(new.order_date::text)
  );

  select coalesce(max(o.order_number), 0) + 1
    into new.order_number
  from public.orders as o
  where o.order_date = new.order_date;

  return new;
end;
$$;


create trigger set_daily_order_number_before_insert
before insert on public.orders
for each row
execute function public.set_daily_order_number();


-- 5. 주문 상품
-- 메뉴가 나중에 수정되어도 과거 주문을 보존하기 위해
-- 주문 당시 이름과 가격을 복사해서 저장
create table public.order_items (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id)
    on delete cascade,

  menu_id uuid
    references public.menus(id)
    on delete set null,

  menu_name text not null
    check (char_length(trim(menu_name)) > 0),

  unit_price integer not null
    check (unit_price >= 0),

  quantity integer not null
    check (quantity > 0),

  -- 해당 상품의 옵션 가격까지 포함한 전체 금액
  item_total integer not null
    check (item_total >= 0),

  created_at timestamptz not null default now()
);


-- 6. 주문 상품에 선택된 옵션
-- 옵션이 수정되어도 과거 주문을 보존하기 위해
-- 주문 당시 그룹명, 옵션명, 가격을 복사해서 저장
create table public.order_item_options (
  id uuid primary key default gen_random_uuid(),

  order_item_id uuid not null
    references public.order_items(id)
    on delete cascade,

  option_item_id uuid
    references public.option_items(id)
    on delete set null,

  option_group_name text not null
    check (char_length(trim(option_group_name)) > 0),

  option_name text not null
    check (char_length(trim(option_name)) > 0),

  -- 옵션 1개당 추가 가격
  additional_price integer not null default 0
    check (additional_price >= 0),

  -- 고객이 실제로 선택한 옵션 수량
  quantity integer not null default 1
    check (quantity > 0),

  created_at timestamptz not null default now()
);

-- 7. 직원 기기
-- FCM 푸시 알림을 받을 기기 토큰 저장
create table public.staff_devices (
  id uuid primary key default gen_random_uuid(),

  device_token text not null unique
    check (char_length(trim(device_token)) > 0),

  device_name text,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- =========================================================
-- updated_at 자동 갱신 함수
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- 메뉴 수정 시간 자동 갱신
create trigger set_menus_updated_at
before update on public.menus
for each row
execute function public.set_updated_at();


-- 옵션 그룹 수정 시간 자동 갱신
create trigger set_option_groups_updated_at
before update on public.option_groups
for each row
execute function public.set_updated_at();


-- 옵션 항목 수정 시간 자동 갱신
create trigger set_option_items_updated_at
before update on public.option_items
for each row
execute function public.set_updated_at();


-- 직원 기기 수정 시간 자동 갱신
create trigger set_staff_devices_updated_at
before update on public.staff_devices
for each row
execute function public.set_updated_at();



create trigger set_menu_categories_updated_at
before update on public.menu_categories
for each row
execute function public.set_updated_at();

-- =========================================================
-- 조회 성능용 인덱스
-- PK와 UNIQUE에는 PostgreSQL이 인덱스를 자동 생성하므로
-- 별도로 중복 생성하지 않음
-- =========================================================

create index idx_menu_categories_active_display_order
on public.menu_categories (is_active, display_order);


-- 카테고리별 활성 메뉴 조회
create index idx_menus_category_display_order
on public.menus (category_id, is_active, display_order);


-- 특정 메뉴의 옵션 그룹 조회
create index idx_option_groups_menu_display_order
on public.option_groups (menu_id, is_active, display_order);


-- 특정 그룹의 옵션 항목 조회
create index idx_option_items_group_display_order
on public.option_items (option_group_id, is_active, display_order);


-- 오늘 주문을 번호 순서대로 조회
create index idx_orders_date_number
on public.orders (order_date desc, order_number);


-- 날짜와 상태별 주문 조회
create index idx_orders_date_status
on public.orders (order_date desc, status, order_number);


-- 주문에 포함된 상품 조회
create index idx_order_items_order_id
on public.order_items (order_id);


-- 주문 상품별 선택 옵션 조회
create index idx_order_item_options_order_item_id
on public.order_item_options (order_item_id);


-- 활성화된 직원 푸시 기기 조회
create index idx_staff_devices_is_active
on public.staff_devices (is_active);

commit;