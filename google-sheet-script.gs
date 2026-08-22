/**
 * 리뷰팽귄 — 사장님 가입 리드를 구글시트에 쌓는 스크립트
 * ------------------------------------------------------------
 * 쓰는 법 (약 3분)
 *  1) sheets.new  접속 → 빈 시트 생성 (머리글은 이 스크립트가 자동으로 만듭니다)
 *  2) 상단 메뉴 [확장 프로그램] → [Apps Script]
 *  3) 기존 코드 전부 지우고 이 파일 내용을 통째로 붙여넣기 (수정할 곳 없음)
 *  4) 우측 상단 [배포] → [새 배포] → 톱니바퀴 → [웹 앱]
 *  5) "다음 사용자로 실행: 나"  /  "액세스 권한: 모든 사용자"   ← 이 둘이 핵심
 *  6) [배포] → 권한 승인 → 나오는 URL 복사
 *     ("확인되지 않은 앱" 경고가 뜨면 → 고급 → 안전하지 않음(이동). 본인이 만든 스크립트라 정상입니다)
 *  7) 리뷰팽귄 총괄관리자 → "📗 구글시트로 가입 리드 받기" 에 URL 붙여넣고 [저장]
 *  8) [🧪 테스트 한 줄 보내기] 눌러서 시트에 줄이 생기는지 확인
 *
 * 알림 메일을 받고 싶으면 아래 NOTIFY_EMAIL 에 본인 메일 주소를 넣으세요.
 * (비워두면 메일은 안 보내고 시트에만 쌓입니다)
 */

var NOTIFY_EMAIL = '';   // 예: 'jangsa.marketing@gmail.com'
var SHEET_NAME   = '가입리드';

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var sheet = getSheet_();

    // 머리글이 없으면 첫 실행 때 자동 생성
    var headers = ['접수시각','구분','매장ID','매장명','대표자명','연락처','업종',
                   '네이버플레이스','관리자이메일','매장주소','마케팅수신동의'];
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(headers);
      sheet.getRange(1, 1, 1, headers.length)
           .setFontWeight('bold')
           .setBackground('#1D6F42')
           .setFontColor('#ffffff');
      sheet.setFrozenRows(1);
    }

    sheet.appendRow([
      data.at || new Date(),
      data.type || '',
      data['매장ID'] || '',
      data['매장명'] || '',
      data['대표자명'] || '',
      data['연락처'] || '',
      data['업종'] || '',
      data['네이버플레이스'] || '',
      data['관리자이메일'] || '',
      data['매장주소'] || '',
      data['마케팅수신동의'] || ''
    ]);

    // 실제 가입일 때만 메일 알림 (테스트 줄은 제외)
    if (NOTIFY_EMAIL && data.type === 'store_signup' && data['매장ID'] !== 'TEST') {
      MailApp.sendEmail({
        to: NOTIFY_EMAIL,
        subject: '[리뷰팽귄] 새 매장 가입 — ' + (data['매장명'] || ''),
        body: [
          '새 사장님이 가입하셨습니다.',
          '',
          '매장명   : ' + (data['매장명'] || ''),
          '대표자   : ' + (data['대표자명'] || ''),
          '연락처   : ' + (data['연락처'] || ''),
          '업종     : ' + (data['업종'] || ''),
          '플레이스 : ' + (data['네이버플레이스'] || ''),
          '매장주소 : ' + (data['매장주소'] || ''),
          '수신동의 : ' + (data['마케팅수신동의'] || ''),
          '',
          '접수시각 : ' + (data.at || '')
        ].join('\n')
      });
    }

    return ContentService.createTextOutput(JSON.stringify({ok: true}))
                         .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ok: false, error: String(err)}))
                         .setMimeType(ContentService.MimeType.JSON);
  }
}

// 배포 확인용 — 브라우저로 URL을 열면 이 문구가 보이면 정상입니다
function doGet() {
  return ContentService.createTextOutput('리뷰팽귄 시트 연동 정상 동작 중입니다.');
}

function getSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) sheet = ss.insertSheet(SHEET_NAME);
  return sheet;
}
