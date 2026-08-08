# 리뷰팡 — Claude Code / Codex 인수인계

## 프로젝트 기본 정보

| 항목 | 내용 |
|------|------|
| 브랜드명 | **리뷰팡** (ReviewPang) |
| 메인 파일 | `index.html` (단일 파일, ~7,700줄) |
| 기술 스택 | Vanilla JS + HTML5 Canvas + Supabase JS v2 |
| 저장소 | localStorage (캐시) + Supabase (클라우드 동기화) |
| GitHub | https://github.com/jangsamarketing-hub/reviewpang |
| 라이브 URL | https://reviewpang.vercel.app |
| Vercel 대시보드 | https://vercel.com/dashboard (jangsa.marketing@gmail.com) |
| 배포 방식 | GitHub push → Vercel 자동 배포 |
| Supabase | https://pauzkmqmliuumybpinqi.supabase.co |
| 최종 업데이트 | 2026-08-06 (주사위 게임 배포) |

---

## 개발 규칙 (반드시 지켜야 함)

1. **수정 후 항상 브라우저에서 직접 확인** — 콘솔 에러(F12) 없는지 체크
2. **비개발자 사용자** — 전문용어 최소화, 뭘 왜 하는지 한 줄씩 설명하며 진행
3. **큰 구조 변경(파일 분리 등)은 사용자 승인 후에만** 진행
4. **단일 HTML 파일 유지** — 별도 JS/CSS 파일 분리하지 말 것
5. 로컬 개발: `python -m http.server 8420` → http://localhost:8420

### 토큰 절약 전략

6. **search-first** — 코드를 읽기 전에 Grep/Glob으로 먼저 위치를 찾는다
7. **minimal-edit** — 변경할 함수/섹션만 파악 후 최소 범위만 Edit. 전체 파일 재작성 금지
8. **offset+limit** — 긴 파일(index.html)은 필요한 줄만 읽어라

---

## 비즈니스 모델 (2026-08-06 기준)

**리뷰팡은 신규 DB 수집용이 아니다.** 사용자는 이미 고객·문의 DB 약 1만 개 보유.
앱의 진짜 목적은 ① **재접촉 명분** (기존 고객에게 "이런 거 만들었으니 쓰세요"로 다시 연락)
② 무료로 써보게 한 뒤 **자연스러운 유료 전환** ③ 잘 쓰는 대표님은 **마케팅 대행/컨설팅 연계**.
→ 앞으로 만드는 모든 기능은 이 관점으로 설계할 것.

**플랜 구조 (`forceAllPremium=false`, 개별 플랜 적용 중)**
- 무료: 네이버 리뷰 + 메인게임 + **카카오맵**
- 유료: 구글맵 · 인스타 · CRM 문자 · 기간별/주월별 통계
- `isPremium()` = `_platformConfig.forceAllPremium || STORE.premium`
- 총괄관리자 "전체 개방 ON/OFF"로 언제든 일괄 전환 가능

> ⚠️ `_platformConfig`는 브라우저 localStorage 기반. 과거 "전체 개방"을 눌렀던
> 브라우저는 `true`가 남아있을 수 있어 총괄관리자에서 "🔒 플랜 적용"을 한 번 눌러야 동기화됨.

**결제:** Stripe는 한국 미지원으로 중단 → **PortOne(포트원)** 예정. 계정 미생성.
계획: 4,900원/월 (정가 9,900원), 가입 후 7일 이내 할인, 고객포털 방식 해지.

---

## 완료된 기능 목록 (2026-07-18 기준)

### 🎲 주사위 게임 (2026-08-06 배포, 이번 작업의 핵심)

메인 게임의 **4번째 선택지**. 기존 룰렛·복권·사다리는 그대로 살아있고,
사장님이 게임 설정 탭에서 넷 중 하나를 고른다 (`STORE.gameMode='dice'`). **기본값은 여전히 룰렛.**

**⚠️ 가장 중요한 설계 원리 — 결과 먼저, 주사위는 나중**
주사위 2개 합은 7이 몰리는 종 모양이라 굴려서 정하면 확률 통제가 불가능하다.
그래서 `① 가중치 추첨 → ② 그 상품이 있는 칸까지 거리 역산 → ③ 맞는 눈 배정 → ④ 연출`
순서로 간다. 한 번에 못 가면(거리 1 또는 13~21) **'더블' 2연속 굴림**으로 처리.
고객 눈엔 똑같지만 확률은 설정값을 그대로 따른다.

**무한 트랙 + 카메라 고정**
- `state.pos`는 누적 절대값(순환 안 함). 상품 조회만 `tiles[pos % 20]`
- 펭귄은 **고정**, 트랙이 흘러간다 (`_diceApplyCamera`)
- 현재 위치 앞뒤만 렌더 (`pos-4 ~ pos+30`) — 더블 최대 21칸이라 넉넉히 확보

**핵심 함수**
| 함수 | 역할 |
|------|------|
| `_diceDefaultGame()` | 기본 상품·확률·미션 (`v:3`, migrateStore가 버전 비교로 자동 교체) |
| `_diceWeightedPick(list)` | 가중치 추첨 |
| `_diceBuildTiles(prizes,20)` | 확률 비례로 20칸 자동 배치 (Smooth Weighted Round-Robin) |
| `_diceRouteToPrize(tiles,pos,id)` | 목표 칸까지 필요한 눈 역산 (+더블 처리) |
| `rollDice()` | 소모→추첨→이동→지급 |
| `_diceMiniBoard(start,count,scale)` | 홈·랜딩·대기화면 공용 보드 축소판 |
| `_penguinSvg(size)` | 인라인 SVG 펭귄 (외부 이미지 없음) |

**상품 구성 (기대원가 약 1,220원 / 실질 약 610원)**
음료 32% · 지정사이드 18% · 스탬프+1 16% · 희망사이드 10% · 한번더 8% ·
스탬프+2 7% · **잭팟 5%** · 스탬프+3 4%
→ 잭팟 칸 도착 시 **주사위를 한 번 더 굴려** 2차 추첨 (10만원 식사권 = 전체 0.05%)

**주사위 획득 = 리뷰 미션 사다리** (이게 진짜 엔진)
설문(내부검증) → 네이버 → 카카오맵 → 🔒구글 → 🔒인스타 → 재방문.
팝업은 **다음 미션 1개만 강조** (5개 다 보여주면 피로해서 다 안 함).

**체류시간 검증 (`verifySeconds`, 기본 75초)**
리뷰는 API가 없어 검증 불가 → 외부 이동 후 복귀까지의 시간으로 판정.
`visibilitychange` + `pageshow(bfcache)` 감지, localStorage에 보관해 페이지가 날아가도 이어짐.
> 🔒 **남은 시간을 고객에게 절대 노출하지 않는다.** 기준이 알려지면 시간만 때우는 우회가 생긴다.

**리뷰 문구 조립기 (네이버 어뷰징 방지 — 필수)**
고정 문구를 복붙시키면 유사 리뷰가 쌓여 네이버 필터에 걸리고 **리뷰 노출 제외·순위 하락**으로
사장님이 피해를 본다. 그래서 설문 답변(방문계기·매트릭스 8점↑) + 선택 칩 + 표현 변형을 조합해
매번 다른 문장을 만든다. **검증: 200회 생성 시 고유 문장 197개.**

### 고객 화면
- **로그인**: 닉네임 + 전화번호 (개인정보 동의 포함)
- **메인 게임 4종**: 룰렛 / 카드뽑기 / 긁는복권 / 🎲주사위
- **추가이벤트 3종**: 카카오맵 / 구글 / 티맵 (플랫폼별 독립 게임)
- **VIP 등급**: 브론즈~다이아 5단계 + 자동 쿠폰
- **스탬프 카드**: 설문 제출 시 자동 적립 (게임 당첨분은 아래 정책 참조)
- **만족도 설문**: 방문경로·방문계기·이동시간(선택) + 별점(필수) + 주관식(필수)
- **쿠폰함 / 네이버 플레이스 리뷰 유도**

### 매장 관리자 화면
- **통계**: 일/주/월 참여 차트, VIP 분포
- **고객·연락처**: 방문/미방문 필터 + 기간 슬라이더, CSV/TXT 다운로드
- **CRM**: 고객 선택 + 문자 템플릿 발송
- **QR코드**: 매장별 고유 QR
- **게임 설정**: 룰렛/카드/복권 상품·확률
- **쿠폰·설문·추가이벤트·매장설정** 관리

---

## 💰 비용 통제 정책 (전 게임 공통 · 2026-08-06)

### ① 스탬프는 직원 확인 후에만 적립
게임에서 스탬프에 당첨돼도 **자동 적립하지 않는다.** 클라이언트에서 바로 쌓으면
검증 없이 무한정 누적될 위험이 있어, 잭팟이 쓰던 `staffCheck` 패턴을 그대로 적용:

```
당첨 → '⭐ 스탬프 N개 적립권' 쿠폰만 발급 (grantsStamp: N)
     → 고객이 매장에서 직원에게 제시
     → useCpn() / ownerConfirmCoupon() 에서 grantStampToUser() 호출 → 그때 적립
```
`grantStampToUser(uid, amount, reason)`는 `currentUser`가 아닌 **특정 uid 대상**이라
직원이 다른 고객 것을 처리할 수 있다. 마일스톤 달성 쿠폰도 여기서 발급.

### ② 쿠폰 하루 사용 한도 (`STORE.couponPolicy.dailyUseLimit`, 기본 2)
**당첨은 비용이 아니다.** 매장에서 직원이 확인하는 순간에만 실제 지출이 생긴다.
그래서 상품은 후하게 주고 **사용만** 하루 N개로 묶으면:
- 손님 1명당 **1일 최대 지출이 확정**됨 (평균 쿠폰 1,932원 × 2 = 약 3,900원)
- 쌓인 쿠폰이 **재방문 이유**가 됨
- 직원이 거절할 필요 없이 시스템이 대신 안내

> 🔑 **스탬프 적립권(원가 0원)은 한도에서 제외.** 포함하면 공짜 쿠폰이 한도를 잡아먹어
> 손님은 손해 본 기분, 사장님은 이득도 없다.
>
> 매장설정에서 한도를 바꾸면 "손님 1명당 최대 N원" 이 실시간 환산돼 표시된다 —
> 기대원가(평균)보다 **상한 보장**이라 영업 시 설득력이 다르다.

### ③ 사진 업로드 전면 제거
매장 배경사진·스탬프 보상사진이 base64로 Supabase JSONB에 그대로 저장돼
매장이 늘수록 DB 용량을 직접 갉아먹었다. 업로드 기능 삭제, **기존 등록분은
'사진 제거' 버튼만 남겨 용량 회수 가능.** 랜딩 히어로는 대신 `_diceMiniBoard`로 그린다.

### ④ 확률은 고객에게 절대 비공개
확률표·당첨 안내 화면 만들지 말 것. 확률 표시는 **관리자 화면에만** 존재한다.

---

## ✉️ 주기적 재접촉 (CRM)

사장님이 주 1회 주사위를 충전해주고 문자로 알려 다시 오게 만드는 흐름.
주사위를 굴리려면 리뷰 미션이 필요하므로 **충전 → 문자 → 재방문 → 리뷰**가 한 줄로 이어진다.

| 문자 | 함수 | 주사위 |
|------|------|--------|
| 🎲 주사위 충전 알림 | `bulkRechargeDice(1)` | 충전됨 |
| 📢 매장 이벤트 안내 | `bulkSendPromo()` | 충전 안 됨 |

- 템플릿: `STORE.crmTemplates.{dice, promo}` — 변수 `{고객명} {매장명} {링크} {주사위}`
- `STORE.diceRechargeDays`(기본 7) 이내 충전한 고객은 **자동 제외**, 표의 '충전' 컬럼에 `🎲 가능 / N일 전` 표시
- 발송은 `sms:` 링크로 문자 앱을 열어주는 방식 → **발송 비용 0원**, 대신 사장님이 직접 전송
  (iOS는 단체 수신자 1명만 인식하는 한계 있음. 불편하면 문자 API 연동 검토)

> 💡 **매일 주사위(카카오 방식)는 보류.** 웹앱이라 푸시 알림이 없어 "매일 열기"가 안 일어나고,
> 월 30회 굴리면 발급이 사용 가능량을 4배 초과해 쿠폰이 쌓였다 만료 → 오히려 신뢰가 깎인다.
> 대신 **재방문 주사위**가 훨씬 강력하다.

---

### 총괄 관리자
- **매장 현황**: 신호등(7일/8~14일/15일+) + 휴면순 정렬
- **매장 관리**: 승인/정지, 프리미엄 개별 부여
- **🔓 전체 기능 개방 토글**: 일괄 ON/OFF 버튼
- **🔄 데이터 초기화 / 🗑️ 매장 삭제 / DB 다운로드**

---

## 접속 정보 (개발용)

| 구분 | 계정 | 비밀번호 |
|------|------|---------|
| 총괄관리자 | jayden | 194360 |
| 사장님(demo 매장) | admin@example.com | admin1234 |
| 직원 | STAFF001 | 1234 |

---

## Supabase 구조

```
URL: https://pauzkmqmliuumybpinqi.supabase.co
테이블: stores (store_id TEXT PK, data JSONB, updated_at TIMESTAMPTZ)
RLS: 비활성화 (anon key로 직접 읽기/쓰기)
```

### 동기화 흐름
- `saveState()` → `STORE._sbTs = Date.now()` 타임스탬프 후 `_sbPush(storeId)` 자동 호출
- 앱 시작 시 → `_sbSync(storeId)` 백그라운드 실행 (원격이 더 최신이면 갱신)
- 어드민 진입 시 → `_sbSync` 후 더 최신 데이터면 재렌더
- QR로 첫 방문 (localStorage 없음) → `_sbLoad`로 Supabase에서 직접 로드
- 매장 가입 → `_sbPush` 즉시 실행 (다른 기기에서 QR 공유 즉시 접근 가능)
- 랜딩 매장 검색 → `_sbLoadAll()`로 Supabase 전체 조회

### 주요 Supabase 함수
| 함수 | 역할 |
|------|------|
| `_sbPush(storeId)` | 단일 매장 저장 |
| `_sbLoad(storeId)` | 단일 매장 로드 |
| `_sbSync(storeId)` | 타임스탬프 기반 스마트 동기화 |
| `_sbLoadAll()` | 전체 매장 목록 조회 |

---

## 코드 구조 지도

### HTML 섹션 (화면별 id)
| id | 화면 |
|----|------|
| `s-landing` | 시작 화면 |
| `s-login` | 고객 로그인 |
| `s-home` | 고객 홈 |
| `s-roulette` | 룰렛 게임 |
| `s-card` | 카드뽑기 |
| `s-scratch` | 긁는복권 |
| `s-ladder` | 사다리 게임 |
| `s-dice` | 🎲 주사위 게임 (보드+펭귄) |
| `s-result` | 게임 결과 (룰렛·복권·카드·사다리 공용) |
| `s-extra-roulette/card/scratch` | 추가이벤트 게임 |
| `s-coupons` | 쿠폰함 |
| `s-stamp` | 스탬프 카드 |
| `s-survey` | 만족도 설문 |
| `s-naver` | 네이버 플레이스 |
| `s-admin-login` | 사장님 로그인 |
| `s-admin` | 매장 관리자 대시보드 |
| `s-platform-login` | 총괄관리자 로그인 |
| `s-platform` | 총괄관리자 대시보드 |
| `s-owner-signup` | 사장님 회원가입 |
| `s-staff-check` | 직원 쿠폰 확인 |

### 주요 함수
| 함수 | 역할 |
|------|------|
| `show(id)` | 화면 전환 |
| `saveState()` | localStorage 저장 + Supabase push |
| `isPremium()` | 프리미엄 여부 (`forceAllPremium` 플래그 우선) |
| `bulkSetPremium(bool)` | 전체 기능 개방 ON/OFF |
| `phoneLogin()` | 고객 로그인 |
| `refreshHome()` | 홈 화면 갱신 |
| `doSpin()` | 룰렛 실행 |
| `renderAdmin(tab)` | 관리자 탭 렌더링 |
| `renderPlatform()` | 총괄관리자 렌더링 |
| `seedDemoStore()` | 새 매장 기본 데이터 생성 |
| `migrateStore(s)` | 구버전 데이터 마이그레이션 |
| `createStore()` | 사장님 회원가입 처리 |

### 전역 상태
```javascript
STORE_ID       // 현재 매장 ID (URL ?store= 파라미터)
STORE          // 현재 매장 데이터 객체
storesDB       // 전체 매장 { [storeId]: STORE }
currentUser    // 현재 로그인 고객
PLATFORM       // 총괄관리자 자격증명
_platformConfig // 플랫폼 전역 설정 { forceAllPremium: true }
```

---

## 데이터 구조 (STORE 객체)

```javascript
STORE = {
  _sbTs,        // Supabase 동기화 타임스탬프
  approved,     // 총괄관리자 승인 여부
  premium,      // 개별 프리미엄 여부 (forceAllPremium이면 무관)
  plan,         // 'free' | 'premium'
  profile: { name, address, phone, emoji, bgImage, naverUrl, kakaoUrl, pin },
  adminEmail, adminPassword,
  owner: { name, phone },
  users: [{ id, name, phone, marketing, joined, visits, nameHistory }],
  coupons: [{ id, uid, name, benefit, status, issued, usedAt, sentAt,
              staffCheck?, grantsStamp? }],  // grantsStamp: 직원 확인 시 적립할 스탬프 수
  spinLog: [{ userId, date, gameType }],
  surveys: [{ userId, name, phone, date, answers: { q1, q2, q3, ... } }],
  surveyQuestions: [{ id, type, label, options?, items? }],
  staff: [{ code, pin, name, active }],
  stampSettings: { goal, reward, grantStamp },
  stampCards: { [userId]: { count, history } },
  vip: { tiers, autoCoupons },
  events: [{ id, platform, label, active, link, gameType, prizes }],
  extraSpinLog: { [userId_platform_date]: true },
  extraEventLog: [{ platform, date, userId, prize }],
  mainGame: { type, prizes },
  gameMode,     // 'roulette' | 'scratch' | 'ladder' | 'dice'  ← 매장이 고르는 메인 게임

  // ── 🎲 주사위 게임 (매장별 독립) ──
  diceGame: {
    v: 3,                    // 버전. migrateStore가 이 값으로 상품표 자동 교체
    boardSize: 20, verifySeconds: 75, maxAgainPerDay: 2,
    prizes: [{ id, label, icon, type, weight, cost, benefit?, amount?, sub? }],
                             // type: 'coupon' | 'stamp' | 'again' | 'jackpot'
    tiles: [prizeId × 20],   // 확률 비례 자동 배치 (확률 바뀌면 즉시 재생성)
    missions: [{ id, label, dice, verify, premium }],
    reviewParts: { intro, praise, outro }
  },
  diceState: {               // 고객별 진행 상태
    [uid]: { pos, dice, laps, missionsDone, againToday, lastDate,
             lastRecharge, rechargeCount }   // pos는 누적 절대값(순환 안 함)
  },

  // ── 비용 통제 / CRM ──
  couponPolicy: { dailyUseLimit: 2, unusedWarnAt: 5 },  // 0 = 무제한
  crmTemplates: { dice, promo },
  diceRechargeDays: 7,
}
```

**localStorage 키 (Supabase 아님, 기기별)**
| 키 | 용도 |
|----|------|
| `rp_sess_<storeId>` | 로그인 세션 + 마지막 화면 (12시간) — 리뷰 갔다 와도 복구 |
| `rp_dwell_<storeId>` | 진행 중인 리뷰 미션 + 이탈 시각 (1시간) |
| `reviewpang_platform_config` | 총괄관리자 설정 (`__platform__` 키로 Supabase에도 동기화) |

---

## Git / 배포

```bash
git add index.html
git commit -m "feat: 설명"
git push
# → Vercel 자동 배포 (1~2분)
```

---

## 알려진 이슈

- Supabase anon key가 HTML 소스에 노출됨 → RLS 도입 전까지는 공개 데이터로 취급
- 총괄관리자 "대신 관리" 기능은 같은 브라우저 세션에서만 작동
- 문자 발송이 `sms:` 링크 방식이라 **iOS는 단체 수신자를 1명만 인식** (안드로이드는 정상)
- 리뷰 링크가 네이버 **앱**으로 열리면 고객이 스스로 브라우저로 돌아와야 함
  → 안전망으로 "리뷰 스크린샷 찍어 직원에게 보여주세요" 안내를 체류 검증 화면에 배치해둠

---

## 다음 작업 우선순위

1. **실기기 파일럿** — 폰에서 리뷰 왕복(새 탭 → 복귀 → 주사위 수령) 실제 확인
2. **PortOne 결제 연동** — 계정 생성 후 빌링키 발급 → 자동결제
3. **직원 수동 주사위 지급** — 리뷰 쓰고 안 돌아온 고객 구제 (기존 직원 화면에 붙이면 됨)
4. **ERP 연동** — 업체관리 ERP에 리뷰게임 참여도/CRM/설문 데이터 연동
5. **Supabase Auth 도입** — 사장님 계정을 Supabase Auth로 이전 (보안 강화)
6. **문자 발송 API** — 파일럿 후 불편하면 검토 (예약 발송 → 매주 자동 충전+발송 가능)
7. **파일 분리 (JS/CSS)** — 코드베이스가 커지면 분리 논의

---

## ⛔ 하지 말 것 (사용자가 명시적으로 결정한 것)

- **확률표·당첨 안내 화면 만들지 말 것** — 고객에게 확률 비공개
- **체류 검증 남은 시간 노출 금지** — 기준이 알려지면 우회가 생김
- **사진 업로드 기능 되살리지 말 것** — 서버 용량
- **주류 상품 넣지 말 것** — 전 게임에서 제거됨
- **매일 접속 주사위 보류** — 푸시 없는 웹앱이라 쿠폰만 쌓였다 만료됨
- **친구 공유 바이럴 하지 말 것** — 안 올 사람에게 공유는 의미 없음
- **리뷰 문구를 고정 템플릿으로 복붙시키지 말 것** — 네이버 어뷰징 필터
