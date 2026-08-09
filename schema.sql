-- ============================================================
-- 리뷰팡 Supabase 스키마
-- Supabase 대시보드 → SQL Editor 에서 실행하세요
-- https://supabase.com/dashboard/project/pauzkmqmliuumybpinqi/sql
-- ============================================================

-- 매장 데이터 테이블 (JSONB 방식)
CREATE TABLE IF NOT EXISTS stores (
  store_id   text        PRIMARY KEY,
  data       jsonb       NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- anon key 로 직접 읽기/쓰기 허용 (RLS 비활성화)
ALTER TABLE stores DISABLE ROW LEVEL SECURITY;

-- updated_at 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at 자동 갱신 트리거
DROP TRIGGER IF EXISTS stores_updated_at ON stores;
CREATE TRIGGER stores_updated_at
  BEFORE UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 조회 성능용 인덱스
CREATE INDEX IF NOT EXISTS idx_stores_updated_at ON stores (updated_at DESC);

-- ============================================================
-- 📒 고객 행동 원장 (store_events)
-- ============================================================
-- QR 스캔 → 로그인 → 게임참여 → 리뷰미션 → 쿠폰사용 까지의 전환 흐름을
-- append-only 로 쌓는 원장. 나중에 장사 ERP에서 매장별 전환율을 계산하는 원천 데이터.
--
-- ⚠️ 왜 stores 테이블(JSONB)에 안 쌓는가:
--    stores.data 는 매장 1건 = 1 JSON 블롭이라 로그를 넣으면 무한히 커진다.
--    (예전 사진 업로드를 걷어낸 것과 같은 이유) 그래서 완전히 분리된 테이블로 둔다.
CREATE TABLE IF NOT EXISTS store_events (
  id         bigserial   PRIMARY KEY,
  store_id   text        NOT NULL,
  event      text        NOT NULL,   -- visit | login | game_play | survey_done | mission_done | coupon_used | store_signup | waiting_join(예정)
  uid        text,                   -- 고객 id (익명 QR 조회는 NULL)
  meta       jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  -- 한국 시간 기준 날짜를 미리 계산해 두면 일별 집계가 훨씬 빠르다
  day        date        GENERATED ALWAYS AS (((created_at AT TIME ZONE 'Asia/Seoul'))::date) STORED
);

ALTER TABLE store_events DISABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ev_store_day   ON store_events (store_id, day DESC);
CREATE INDEX IF NOT EXISTS idx_ev_store_event ON store_events (store_id, event, day DESC);
CREATE INDEX IF NOT EXISTS idx_ev_store_uid   ON store_events (store_id, uid);

-- ── ERP 연동용 일별 전환 집계 뷰 ──
-- 장사 ERP에서 이 뷰만 읽으면 매장별 퍼널 전환수를 바로 가져갈 수 있다.
CREATE OR REPLACE VIEW store_daily_funnel AS
SELECT
  store_id,
  day,
  count(*) FILTER (WHERE event='visit')                        AS qr_views,        -- 조회(=QR스캔 접근) 횟수
  count(DISTINCT uid) FILTER (WHERE uid IS NOT NULL)           AS unique_users,    -- 식별된 고객 수
  count(*) FILTER (WHERE event='login')                        AS logins,          -- 로그인(연락처 확보)
  count(*) FILTER (WHERE event='game_play')                    AS game_plays,      -- 리뷰이벤트 게임 참여
  count(*) FILTER (WHERE event='survey_done')                  AS surveys,         -- 설문 참여
  count(*) FILTER (WHERE event='mission_done')                 AS review_missions, -- 리뷰 미션 완료
  count(*) FILTER (WHERE event='coupon_used')                  AS coupons_used,    -- 실제 재방문(쿠폰 사용)
  count(*) FILTER (WHERE event='waiting_join')                 AS waiting_joins    -- 웨이팅 등록(추후 기능)
FROM store_events
GROUP BY store_id, day;

-- 확인용 쿼리
SELECT 'stores + store_events 생성 완료 ✅' AS result;
