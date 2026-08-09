# 리뷰팡(ReviewPang) 인수인계 — 2026-08 핑크팽귄 리브랜딩 + 데이터 원장

> **이 문서가 최신 인수인계 문서입니다.** `HANDOFF.md`·`ERP-HANDOFF.md`·`PROGRESS.md`는
> 2026-07 초 시점(주사위 게임 도입 이전) 문서라 지금 상태와 다릅니다. 참고만 하고
> 실제 작업은 이 문서 기준으로 진행하세요. `CLAUDE.md`는 게임 엔진 등 코드 구조
> 상세 설명이 잘 정리돼 있으니 계속 참고하되, 브랜치/DB/배포 최신 상태는 이 문서를 따르세요.

---

## 0. 한 줄 요약

기존 리뷰팡(주사위 게임 리뷰 이벤트 SaaS)을 **핑크팽귄 시그니처 브랜드**로 전면 리뷰랜딩하고,
**고객 행동을 원장(ledger)으로 남기는 데이터 인프라**를 새로 깔았습니다.
지금 `pink-penguin-mascot` 브랜치가 사실상 최신 본선이고, 별도 Vercel 프로젝트
(`reviewpanguin.vercel.app`)로 독립 배포 중입니다. 기존 라이브(`reviewpang.vercel.app`,
`main` 브랜치)는 건드리지 않았습니다.

---

## 1. 전략적 맥락 (왜 이렇게 했는가)

### 1-1. 사업 모델 (변하지 않은 축)
리뷰팡은 신규 고객 수집 도구가 **아닙니다**. 사장님이 이미 보유한 고객 DB(문의·예약 연락처)에
"다시 연락할 명분"을 만들어주는 재접촉 엔진입니다. 무료 체험 → 유료 전환 → 마케팅 대행 연계로
이어지는 구조는 `CLAUDE.md`에 정리된 그대로 유지됩니다.

### 1-2. 이번 세션의 전략 판단 — "핑크색 펭귄이 되어라"
경쟁 서비스들이 회색·주황 톤의 흔한 리뷰 이벤트 앱으로 보이는 상황에서, **눈에 띄는 존재가
되는 것 자체를 브랜드 전략**으로 삼았습니다. 사장님이 직접 제작한 실사 3D 렌더 이미지
(핑크색 아기 황제펭귄, 대기 자세·점프 자세 2종)를 시그니처 마스코트로 채택하고, 게임판·홈
화면·랜딩(퍼널) 페이지 전체에 통일 적용했습니다.

### 1-3. "감이 아니라 데이터로" — 두 번째 전략 축
경쟁 서비스는 "리뷰 이벤트 돌려드립니다"에서 끝나지만, 리뷰팡은 QR 조회부터 재방문까지
**전 단계를 원장에 기록해 전환율을 보여주는 것**을 차별점으로 삼았습니다. 이게 나중에
장사 ERP 연동, 웨이팅 데이터 통합의 기반이 됩니다. (4장 참고)

---

## 2. 브랜치 구조 (★ 반드시 먼저 이해할 것)

```
main               ← 기존 라이브 사이트 (reviewpang.vercel.app). 이번 세션에서 안 건드림 원칙이었으나
                     ↑ 확률 조정·잭팟 리브랜딩 등 "게임 공통 개선"은 new-game-v2 → main에도 병합됨
new-game-v2        ← main과 사실상 동일한 라인(계속 fast-forward 병합)
pink-penguin-mascot ← ★ 이번 세션 대부분의 작업이 여기 있음. main에서 분기, 이후 new-game-v2의
                     공통 개선사항을 merge로 흡수. 지금 이 브랜치가 가장 최신·완성도 높음.
```

**왜 나눴는가**: 핑크팽귄 이미지 자산(`penguin-idle.webp`, `penguin-jump.webp`)과 브랜드 교체를
기존 라이브 사이트에 바로 얹지 않고, 별도 버전으로 독립 검증할 수 있게 하기 위함입니다.
`new-game-v2`에서 만든 범용 개선(확률 확정, 카카오맵 URL 자동변환, 이모지 선택기, 업종 추가,
잭팟→"당첨!" 리브랜딩)은 `main`과 `pink-penguin-mascot` **양쪽에 다 병합**되어 있습니다.

**다음 작업(웨이팅 관리)**: `pink-penguin-mascot`에서 새 브랜치를 팠습니다 → 6장 참고.

---

## 3. 배포 현황

| 브랜치 | Vercel 프로젝트 | URL | 배포 방식 |
|---|---|---|---|
| `main` | `reviewpang` | https://reviewpang.vercel.app | GitHub 연동 자동배포 |
| `pink-penguin-mascot` | `reviewpanguin` (신규) | https://reviewpanguin.vercel.app | **수동** — `vercel --prod --yes` (아래 참고) |

⚠️ **`reviewpanguin` 프로젝트는 GitHub 자동배포가 아직 안 걸려있습니다.** 브랜치에 새로 커밋해도
자동 반영되지 않고, 매번 로컬에서 아래 명령으로 수동 배포해야 합니다:
```bash
vercel --prod --yes
```
(이 저장소 루트에 `.vercel/project.json`이 이미 `reviewpanguin` 프로젝트로 링크되어 있음.
Vercel CLI는 로컬에 로그인되어 있음 — `jaydenkim90-9134` 계정)

자동배포를 원하면 Vercel 대시보드 → `reviewpanguin` 프로젝트 → Settings → Git →
**Production Branch를 `pink-penguin-mascot`로 지정**하면 됩니다. (API로는 설정 불가, 대시보드에서 1회 클릭 필요)

---

## 4. 데이터베이스 — 3개 테이블 구조 (★ 코드 검수 시 핵심)

Supabase 프로젝트: `https://pauzkmqmliuumybpinqi.supabase.co` (anon key는 코드에 하드코딩,
RLS 비활성화 — 기존부터 있던 알려진 리스크, 이번 세션에서 새로 만든 건 아님)

### 4-1. `stores` (기존) — 매장 1건 = JSON 블롭 1개
매장의 모든 설정·고객·쿠폰·게임상태가 `data` 컬럼(JSONB) 하나에 들어있습니다.

**⚠️ 이번 세션에서 발견하고 고친 치명적 결함**: `saveState()` → `_sbPush()`가 로컬 상태를
그대로 원격에 upsert만 했습니다. 손님 여러 명이 동시에 QR을 찍으면 나중에 저장한 기기가
앞사람이 등록한 고객을 통째로 덮어써 **사실상 마지막 1명만 남는 구조**였습니다.
지금은 `_sbPush()`가 **저장 직전 원격을 다시 읽어 병합**합니다 (`_mergeRemoteIntoLocal`,
index.html 검색). users/surveys/spinLog 등은 합집합, 쿠폰은 '사용됨'이 이기고, 스탬프는
더 많이 쌓인 쪽을 인정합니다. 저장이 연타돼도 `_pushBusy` 플래그로 직렬화됩니다.

### 4-2. `store_events` (신규, ★ 이번 세션 핵심 산출물) — 고객 행동 원장
append-only 로그. `stores` 블롭에 안 넣은 이유: 넣으면 매장 데이터가 무한히 커집니다
(예전에 사진 업로드를 걷어낸 것과 같은 이유).

| 컬럼 | 설명 |
|---|---|
| `event` | `visit`(QR조회) · `login` · `game_play` · `mission_done`(리뷰미션) · `survey_done` · `coupon_used`(=재방문) · `waiting_join`(예정, 미사용) |
| `uid` | 고객 id (익명 조회는 NULL) |
| `meta` | jsonb, 이벤트별 부가정보 |
| `day` | 생성 컬럼, KST 기준 날짜 (집계 성능용) |

ERP 연동용 뷰 `store_daily_funnel`이 매장×일자별로 6개 지표를 미리 집계해줍니다.
사장님 화면(통계 탭 상단 "📒 고객 전환 흐름" 카드)도 이 데이터를 직접 fetch해서 보여줍니다.

**기록 지점** (`logEvent()` 호출부, index.html 검색): `phoneLogin`, `rollDice`,
`_diceMarkMissionDone`, `staffGrantDiceMission`, `submitSurvey`, `ownerConfirmCoupon`,
`checkCpn`(직원 쿠폰확인), 앱 부팅 시(`logVisitOnce`).

**안전장치**: 테이블이 아직 없거나(404) 네트워크가 끊겨도 앱은 정상 동작. 실패한 이벤트는
재시도 큐에 잠깐 쌓였다가 버려짐(무한 누적 방지). 페이지 이탈 순간엔 `keepalive` fetch로 유실 방지.

### 4-3. `store_customers` (신규) — 연락처 전용 원장
`stores` 블롭 병합 로직과 별개로, **덮어써질 수 없는** phone 기준 upsert 테이블입니다.
JSON 블롭이 어떤 이유로 꼬여도 사장님의 연락처 자산은 여기서 복구 가능합니다.
광고 수신동의 시각(`marketing_consent_at`)도 저장 — 정보통신망법 입증자료.

### 4-4. ⚠️ 실행 필요 — 아직 스키마 미적용 상태
`schema.sql`에 3개 테이블 + 뷰 정의가 다 있지만, **Supabase에 아직 실행 안 됨** (제가 직접
실행 불가 — DDL은 대시보드 로그인이 필요하고 anon key로는 안 됩니다). 사장님이 아래에서
`schema.sql` 전체를 붙여넣고 Run 해야 원장이 쌓이기 시작합니다:
```
https://supabase.com/dashboard/project/pauzkmqmliuumybpinqi/sql/new
```
실행 전까지는 이벤트 기록이 전부 404로 조용히 실패하고(앱 동작엔 지장 없음), 통계 카드에는
"아직 집계 데이터가 없어요" 안내만 뜹니다. **검수 시 이 파일이 이미 실행됐는지부터 확인하세요.**

---

## 5. 이번 세션 기능 변경 목록 (pink-penguin-mascot 기준, 코드 순)

1. **시그니처 마스코트 핑크팽귄 교체** — `_penguinSvg()`(인라인 SVG) 제거, 실사 이미지
   `penguin-idle.webp`/`penguin-jump.webp`로 교체. 게임판 말(`#dice-pawn`)은 평소 대기
   이미지 ↔ 칸 이동 시 날개든 점프 이미지로 CSS `steps()` 키프레임 크로스페이드.
   홈/랜딩 미니보드(`#home-pawn`, `_diceMiniBoard`)도 동일 이미지 재사용.
2. **확률 최종 확정** — 25/20/20/15/8/6/3/3 (합 100%), `diceGame.v: 3→4`로 버전업해
   기존 매장도 자동 마이그레이션.
3. **카카오맵 리뷰 URL 자동 정규화** — `normalizeKakaoReviewUrl()`. 매장 고유번호만
   입력해도 `https://place.map.kakao.com/{번호}#addreview?rate=5`(5점 리뷰 작성 페이지)로 자동 변환.
4. **대표 이모지 선택 그리드** — 텍스트 입력 → 음식·술 테마 9세트 클릭 선택으로 교체
   (모바일 이모지 자판 입력 유실 문제의 근본 해결).
5. **업종 옵션 확장** — 아시안푸드·치킨·호프·술집·이자카야·고깃집·분식 등 추가(총 13개).
6. **"잭팟"→"당첨!" / 🏆→🎁 전면 리브랜딩** — 주사위·룰렛·복권·사다리 공용. 기존 매장
   데이터도 이름만 자동 갱신(하위 상품 구성은 보존).
7. **게임판 우측 여백에 당첨상품 미니 리스트** — `_diceSideJackpotHtml()`.
8. **직원 화면 — 주사위 수동 충전 기능** — 네이버 영수증 리뷰처럼 자동검증 불가한 미션을
   직원이 육안 확인 후 전화번호로 조회해 지급 (`grantDiceToUser`, `staffGrantDiceMission`).
9. **고객 행동 원장 + 퍼널 신규 섹션** — 4장 참고. 퍼널 페이지에 "리뷰 이벤트부터 CRM까지
   한 번에" 섹션 신설(핑크팽귄 + 5단계 순환 구조 + 데이터 차별점 메시지).
10. **동시접속 연락처 유실 버그 수정** — 4-1 참고. 이번 세션에서 가장 중요한 수정.
11. **퍼널 문구 편집기 (총괄관리자 전용)** — 섹션 제목/소제목 19개를 관리자 화면에서
    직접 수정. `applyFunnelTexts()`/`FUNNEL_FIELDS`. 이미지는 업로드가 아닌 URL 등록 방식만
    지원(서버 용량 문제로 파일 업로드 기능 자체를 배제 — 예전 사진 업로드 이슈와 동일 이유).
12. **연락처 정보 교체** — `jangsa.doctor` → `jangsa.master`(리틀리/오픈카카오),
    인스타그램(`instagram.com/jangsa.master`)·퍼널 사이트(`jangsa-master.vercel.app`)
    링크를 비즈니스 문의 섹션에 추가. 전부 총괄관리자 패널에서 편집 가능.

---

## 6. 다음 작업 — 웨이팅 관리 프로그램

`pink-penguin-mascot`에서 새 브랜치를 만들어 진행합니다 (아래 6-1 실행).

### 6-1. 브랜치 생성 방침
- 베이스: `pink-penguin-mascot` (최신 상태 + DB 원장 인프라가 이미 있어 재사용 가능)
- 브랜치명: `waiting-management`
- `store_events`에 이미 `waiting_join` 이벤트 타입을 예약해뒀으므로, 웨이팅 등록을
  같은 원장에 바로 합류시키면 매장 전환 퍼널(QR조회→...→재방문)에 웨이팅까지 한 화면에서 봄

### 6-2. 설계 시 참고할 기존 패턴
- 게임 상태 저장 패턴: `STORE.diceState[uid]` 방식 (매장별 독립 상태)
- 실시간성이 필요하므로 Supabase 폴링 주기, 혹은 Realtime 구독 여부를 초기에 정할 것
- 직원 화면 패턴(`s-staff-check`)에 웨이팅 관리 탭을 추가하는 형태를 권장
  (이미 전화번호 조회 UI 패턴이 있어 재사용 가능 — `lookupDiceCustomer` 참고)

---

## 7. 알려진 이슈 / 기술 부채 (검수 시 참고)

- Supabase anon key가 소스에 노출됨, RLS 비활성화 — 기존부터의 리스크, 아직 미해결
- `reviewpanguin` Vercel 프로젝트는 GitHub 자동배포 미설정 (3장 참고)
- `stores` 테이블은 여전히 JSON 블롭 구조. 이번 세션 수정으로 "안전"해졌지만, 정식 출시
  전에는 고객·쿠폰을 각각 정규화된 테이블로 분리하는 게 정석 (지금은 파일럿 통과 수준)
- `store_events`/`store_customers` 스키마가 실제 Supabase에 적용됐는지 재확인 필요 (4-4)
- 문자 발송이 `sms:` 링크 방식이라 iOS는 단체 수신자 인식 안 됨 (기존 이슈, 미해결)
- 실기기 파일럿 아직 미실시 — 폰으로 QR→리뷰→복귀→수령 전체 왕복 확인 필요

---

## 8. 접속 정보 (기존과 동일)

| 구분 | 계정 | 비밀번호 |
|---|---|---|
| 총괄관리자 | jayden | 194360 |
| 사장님(demo 매장) | admin@example.com | admin1234 |
| 직원 | STAFF001 | 1234 |

로컬 개발: `python -m http.server 8420` → http://localhost:8420?store=demo
