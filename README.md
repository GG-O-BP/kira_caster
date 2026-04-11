# kira_caster

씨미(ci.me) 방송에서 쓸 수 있는 챗봇이야~!

채팅창에 명령어를 치면 키라캐스터가 대답해주는 거야! 출석체크도 하고, 포인트도 모으고, 미니게임도 하고, 투표도 하고, 룰렛도 돌리고, 퀴즈도 풀 수 있어!! 진짜 재밌겠지?!

씨미 공식 API 연동으로 후원/구독 알림, 방송 제어, 유저 차단, 팔로워 추적까지 다 된다~!

## 이런 걸 할 수 있어!

| 기능 | 설명 |
|------|------|
| 출석체크 | `!출석` 치면 오늘 출석 완료~! 하루에 한 번만 가능해! |
| 포인트 | 출석하면 포인트가 쌓여! `!포인트`로 확인, `!포인트 순위`로 랭킹! |
| 미니게임 | 주사위 굴리기, 가위바위보 할 수 있어! 이기면 포인트 UP! |
| 채팅 필터 | 나쁜 말은 자동으로 걸러줘! 금칙어 위반 시 자동 차단까지! |
| 커스텀 명령 | 매니저가 직접 명령어를 만들 수 있어! 템플릿 변수도 지원! |
| 고급 명령 | 방송자가 Gleam 코드로 프로그래밍 가능한 명령어를 만들 수 있어! |
| 업타임 | `!업타임`으로 봇이 얼마나 켜져있었는지 알 수 있어! |
| 투표 | 채팅으로 투표할 수 있어! 다 같이 정하자~! |
| 룰렛 | `!룰렛` 돌려서 운 시험해봐! 대박 나면 +100포인트! |
| 퀴즈 | 퀴즈 맞추면 포인트 GET! 누가 제일 빠를까~? |
| 타이머 | `!타이머 30` 하면 30초 후에 알려줘! |
| 신청곡 | YouTube 신청곡! 시청자가 URL로 신청하면 대기열에 추가되고 OBS에서 재생! |
| 후원 알림 | 채팅/영상 후원이 오면 알림! 익명 후원도 지원! `!후원순위`로 랭킹! |
| 구독 알림 | 구독하면 환영 메시지! 티어, 연속 구독 개월 수 표시! |
| 방송 제어 | 채팅으로 방송 제목, 태그, 카테고리, 슬로우모드, 공지 변경! |
| 차단 관리 | `!차단`, `!차단해제`, `!차단목록`으로 유저 관리! |
| 팔로워 추적 | 새 팔로워 자동 환영! `!팔로워`로 팔로워 수 확인! |
| 관리 대시보드 | 웹에서 유저, 금칙어, 명령어, 퀴즈, 투표, 신청곡, 씨미 연동, 방송/채팅 설정, 차단, 채널 정보 전부 관리! |

## 시작하는 방법

### 방법 1: 릴리스 다운로드 (가장 쉬움!)

1. [Releases](../../releases)에서 OS에 맞는 파일 다운로드
2. 실행!
   - **macOS**: `.dmg` 파일을 열고 `kira_caster.app`을 더블클릭
   - **Windows**: 압축 풀고 `start.bat`을 더블클릭
   - **Linux**: 압축 풀고 `start.sh`를 더블클릭 (또는 `kira-caster.desktop` 사용)
3. 브라우저가 자동으로 열리면 설정 마법사를 따라가면 끝!

> 모든 플랫폼에서 Erlang 런타임이 포함되어 있어서 별도 설치 필요 없어!

### 방법 2: Docker (한 줄이면 끝!)

```sh
bash scripts/docker-start.sh   # .env 자동 생성 + 브라우저 자동 열기!
```

또는 직접:

```sh
cp .env.example .env     # 설정 파일 복사 (원하면 편집)
docker compose up         # 실행!
```

브라우저에서 `http://localhost:8080` 접속하면 설정 마법사가 나와!

### 방법 3: 소스에서 직접 실행

Gleam 1.15.2 + Erlang/OTP 28 설치 후:

```sh
gleam deps download   # 필요한 것들 다운받기
gleam build           # 빌드하기
./start.sh            # 실행! (브라우저 자동 열림)
# 또는 gleam run
```

### 처음 실행하면?

처음 실행하면 **설정 마법사**가 나와! 두 단계만 거치면 돼:

1. **관리자 비밀번호** 설정 (선택사항 - 비워둬도 됩니다)
2. **씨미 연동** 설정 (선택사항 - 마법사에 준비 방법이 단계별로 안내되어 있어!)
   - Redirect URI **복사 버튼**이 있어서 클릭 한 번으로 복사 가능!
   - 앱 이름은 자유롭게 지으면 돼!

설정을 마치면 **자동으로 재시작**되고 대시보드로 이동해!

> **"씨미 연결 없이 시작하기"**를 누르면 씨미 연동 없이 바로 시작할 수 있어. 대부분의 기능을 미리 체험할 수 있고, 나중에 대시보드 설정 탭에서 언제든 씨미를 연결할 수 있어!

비밀번호를 설정했으면 **로그인 페이지**가 나와. 브라우저가 비밀번호를 기억해줘서 한 번만 입력하면 돼! 비밀번호를 잊어버렸다면 로그인 페이지의 "비밀번호를 잊으셨나요?"를 참고해!

### 설정은 어디서 바꾸나요?

모든 설정은 **대시보드 설정 탭**에서 바로 변경할 수 있어! 환경변수나 파일 편집 없이 웹에서 다 돼!

- **게임 설정** (쿨다운, 포인트 등): 저장하면 **바로 적용**! 각 설정에 단위와 설명이 표시되니까 헷갈릴 일 없어!
- **시스템 설정** (비밀번호, 씨미 연동 등): 저장 후 **"재시작하여 적용" 버튼** 클릭!

> **설정 우선순위**: 대시보드에서 저장한 설정(DB) > 환경변수 > 기본값. 대시보드에서 설정하면 환경변수보다 우선 적용돼!

### 환경변수 (고급 사용자용)

환경변수는 `.env` 파일이나 Docker 환경에서 초기값을 제공하고 싶을 때만 쓰면 돼. 대시보드에서 설정한 값이 항상 우선이야!

| 환경변수 | 설명 | 기본값 |
|----------|------|--------|
| `KIRA_DB_PATH` | 데이터베이스 파일 경로 | `kira_caster.db` |
| `KIRA_COOLDOWN_MS` | 명령어 쿨타임 (밀리초) | `5000` |
| `KIRA_ADMIN_PORT` | 대시보드 포트 | `8080` |
| `KIRA_ADMIN_KEY` | 대시보드 비밀번호 (비워두면 누구나 접근 가능) | `` |
| `KIRA_SECRET_KEY` | 서버 암호화 키 | 기본값 있음 |
| `KIRA_ATTENDANCE_POINTS` | 출석 보상 포인트 | `10` |
| `KIRA_DICE_WIN_POINTS` | 주사위 승리 포인트 | `50` |
| `KIRA_DICE_LOSS_POINTS` | 주사위 패배 포인트 | `-20` |
| `KIRA_RPS_WIN_POINTS` | 가위바위보 승리 포인트 | `30` |
| `KIRA_RPS_LOSS_POINTS` | 가위바위보 패배 포인트 | `-10` |
| `KIRA_YOUTUBE_API_KEY` | YouTube Data API v3 키 (없으면 제목 대신 영상 ID 사용) | `` |
| `CIME_CLIENT_ID` | 씨미 앱 Client ID (설정하면 씨미 연동 활성화!) | `` |
| `CIME_CLIENT_SECRET` | 씨미 앱 Client Secret | `` |
| `CIME_REDIRECT_URI` | OAuth 콜백 URL | `http://localhost:8080/oauth/callback` |
| `CIME_CHANNEL_ID` | 봇이 연결할 채널 ID (씨미 연동 후 자동 조회됨!) | `` |

> 위 환경변수를 설정하지 않아도 설정 마법사나 대시보드에서 전부 설정할 수 있어! 환경변수 없이 시작해도 아무 문제 없어!

## 명령어 목록

### 일반 명령어 (누구나!)

| 명령어 | 설명 |
|--------|------|
| `!출석` | 오늘 출석체크! 하루에 한 번, +10포인트! |
| `!포인트` | 내 포인트 확인하기 |
| `!포인트 순위` | 포인트 TOP 5 보기 |
| `!게임 주사위` | 주사위 굴리기! 이기면 +50pt, 지면 -20pt |
| `!게임 가위바위보 <가위/바위/보>` | 가위바위보! 이기면 +30pt, 지면 -10pt |
| `!업타임` | 봇 가동 시간 확인 |
| `!투표 <선택지>` | 진행중인 투표에 참여하기 |
| `!투표 결과` | 현재 투표 결과 보기 |
| `!룰렛` | 룰렛 돌리기! 대박(+100), 좋음(+30), 보통(+10), 꽝(-10) |
| `!퀴즈 <답>` | 퀴즈 정답 맞추기 |
| `!타이머 <초>` | N초 후 알림 (1~3600초) |
| `!타이머 <초> <메시지>` | 커스텀 메시지로 타이머 설정 |
| `!노래 <YouTube URL>` | 신청곡 추가! 대기열에 넣어줘! |
| `!노래 목록` | 대기열 보기 (상위 5곡) |
| `!노래 현재` | 지금 재생 중인 곡 확인 |
| `!후원순위` | 후원 랭킹 TOP 5 |
| `!팔로워` | 현재 팔로워 수 확인 |
| `!방송상태` | 방송 중 여부, 제목, 시작 시간 |
| `!라이브` | 씨미 전체 라이브 목록 (상위 5개) |

### 매니저 전용 명령어

| 명령어 | 설명 |
|--------|------|
| `!필터 추가 <단어>` | 금칙어 추가 |
| `!필터 삭제 <단어>` | 금칙어 삭제 |
| `!필터 목록` | 금칙어 목록 보기 |
| `!명령 추가 <이름> <응답>` | 커스텀 명령어 만들기 (템플릿 지원!) |
| `!명령 삭제 <이름>` | 커스텀 명령어 삭제 |
| `!명령 목록` | 커스텀 명령어 목록 보기 |
| `!노래 스킵` | 신청곡 건너뛰기 |
| `!노래 삭제 <번호>` | 대기열에서 곡 삭제 |
| `!노래 비우기` | 대기열 전체 초기화 |
| `!노래 공지` | 현재 재생곡을 채팅 공지로 등록 |
| `!제목 <새 제목>` | 방송 제목 변경 |
| `!태그 <태그1> <태그2> ...` | 방송 태그 변경 (최대 6개) |
| `!카테고리 <검색어>` | 카테고리 검색 후 변경 |
| `!슬로우모드 <초>` / `!슬로우모드 끄기` | 채팅 슬로우모드 설정/해제 |
| `!팔로워전용` / `!팔로워전용 끄기` | 팔로워 전용 채팅 토글 |
| `!공지 <메시지>` | 채팅 상단 공지 등록 |
| `!차단 <채널ID>` | 유저 차단 |
| `!차단해제 <채널ID>` | 차단 해제 |
| `!차단목록` | 차단된 유저 목록 |

### 방송자 전용 명령어

| 명령어 | 설명 |
|--------|------|
| `!명령 고급추가 <이름> <Gleam코드>` | Gleam으로 프로그래밍 가능한 고급 명령어 등록 |
| `!명령 고급삭제 <이름>` | 고급 명령어 삭제 |
| `!투표 시작 <주제> <선택지1> <선택지2> ...` | 투표 시작하기 |
| `!투표 종료` | 투표 끝내고 결과 발표! |
| `!퀴즈 시작` | 랜덤 퀴즈 출제 |

## 신청곡 (YouTube)

시청자가 채팅에서 YouTube URL로 곡을 신청하면 대기열에 추가돼! 스트리머는 대시보드에서 관리하고, OBS 브라우저 소스로 영상을 보여줄 수 있어!

### OBS 설정

1. OBS에서 **브라우저 소스** 추가
2. URL에 `http://localhost:8080/player` 입력
3. 곡이 재생되면 자동으로 영상이 나오고, 끝나면 다음 곡으로 넘어가!

### 대시보드 "신청곡" 탭

- **재생 컨트롤**: 이전 / 처음부터 / 다음 버튼으로 곡 조작
- **대기열 관리**: 곡 추가, 삭제, 순서 변경 (▲▼ 버튼)
- **설정**: 유저당 신청 제한, 포인트 비용, 중복 방지 등 대시보드에서 바로 변경 가능!

### 신청곡 설정 (대시보드에서 변경 가능)

| 설정 | 설명 | 기본값 |
|------|------|--------|
| `song_max_per_user` | 유저당 최대 신청 수 | `1` |
| `song_count_playing` | 재생 중인 곡도 제한에 포함할지 | `false` |
| `song_cost_points` | 신청 시 차감 포인트 (0=무료) | `0` |
| `song_prevent_duplicate` | 같은 곡 중복 신청 방지 | `false` |
| `song_max_duration` | 최대 영상 길이 초 (0=무제한) | `0` |

### YouTube API 키 설정 (선택)

`KIRA_YOUTUBE_API_KEY` 환경변수에 [YouTube Data API v3](https://console.cloud.google.com/apis/api/youtube.googleapis.com) 키를 넣으면 곡 제목과 길이를 자동으로 가져와! 없어도 동작하지만 제목 대신 영상 ID가 표시돼~

## 커스텀 명령어

### 텍스트/템플릿 명령어

매니저가 `!명령 추가 인사 안녕하세요!` 처럼 단순 텍스트 응답을 등록할 수 있어! 그리고 `{{변수}}` 문법으로 동적 응답도 가능해!

```
!명령 추가 인사 {{user}}님 안녕하세요!
!명령 추가 내정보 {{user}} — {{points}}pt, 출석 {{attendance}}회
!명령 추가 환영 {{if args}}{{args}}에 오신 {{user}}님 환영!{{else}}{{user}}님 환영합니다!{{end}}
```

**사용 가능한 변수:**

| 변수 | 설명 |
|------|------|
| `{{user}}` | 명령어를 실행한 유저 이름 |
| `{{args}}` | 전체 인자 (공백으로 연결) |
| `{{args.0}}`, `{{args.1}}` | 개별 인자 (0번째, 1번째, ...) |
| `{{points}}` | 유저의 현재 포인트 |
| `{{attendance}}` | 유저의 출석 횟수 |
| `{{command}}` | 실행된 명령어 이름 |

**조건문:**

```
{{if 변수}}변수가 있을 때 출력{{end}}
{{if 변수}}있을 때{{else}}없을 때{{end}}
```

기존 일반 텍스트 명령어(`안녕하세요!`)도 그대로 동작해!

### 고급 명령어 (Gleam)

방송자가 Gleam 코드로 프로그래밍 가능한 명령어를 만들 수 있어! 대시보드에서 CodeMirror 6 에디터로 편하게 작성하고 실시간 컴파일!

```gleam
import gleam/string
import gleam/list

pub fn handle(user: String, args: List(String)) -> String {
  case args {
    ["안녕"] -> user <> "님 반가워요!"
    [first, ..rest] ->
      user <> "님이 " <> first <> " 외 "
      <> int.to_string(list.length(rest)) <> "개를 선택했어요!"
    _ -> "사용법: !인사 안녕"
  }
}
```

- `pub fn handle(user: String, args: List(String)) -> String` 시그니처를 맞춰야 해!
- `gleam_stdlib` 모듈 (`gleam/string`, `gleam/list`, `gleam/int` 등) 사용 가능!
- 런타임에 컴파일 + BEAM 핫로드되니까 봇 재시작 없이 바로 적용!
- 대시보드의 "재컴파일" 버튼으로 수정 후 즉시 반영!

## 씨미(ci.me) 연동

씨미 공식 OpenAPI를 통해 실제 방송 채팅과 연동할 수 있어!

### 설정 방법

1. **설정 마법사** 또는 **대시보드 설정 탭**에서 씨미 앱 ID와 비밀키 입력
   - 마법사에 씨미 개발자 센터 준비 방법이 단계별로 안내되어 있어!
   - Redirect URI, 채널 ID는 자동으로 설정되니까 입력 안 해도 돼!
2. 설정 저장하면 **자동으로 재시작**돼! (수동 재시작 필요 없어!)
3. 대시보드 "씨미 연동" 탭에서 "연결하기" 클릭
4. 씨미에서 권한 승인하면 자동으로 연결!

> 채널 ID는 직접 입력하지 않아도 돼! OAuth 인증이 완료되면 자동으로 조회해서 저장해줘!

대시보드 상태 탭에서 연결 상태를 실시간으로 확인할 수 있어:
- **씨미 연결됨** (녹색) - 정상 작동 중
- **씨미 연결 끊김** (빨간색) - 연결 안 됨
- **재연결 중 (3/5)** (노란색) - 자동 재연결 시도 중

### 연동되는 기능들

- **채팅 수신/송신**: WebSocket으로 실시간 채팅 연결 (PING 자동, 2시간/12시간 재연결)
- **후원 이벤트**: 채팅/영상 후원 실시간 알림 (익명 후원 포함)
- **구독 이벤트**: 구독 알림 (티어, 연속 개월 수)
- **방송 제어**: 채팅에서 제목/태그/카테고리/슬로우모드/공지 변경
- **유저 관리**: 차단/해제, 금칙어 위반 시 자동 차단
- **팔로워 추적**: 새 팔로워 자동 환영 메시지
- **역할 자동 매핑**: 채널 관리자 목록 → 권한 체계 자동 연동
- **OAuth 토큰 관리**: 자동 갱신, 재시작 시 DB에서 복원
- **대시보드**: 방송/채팅 설정, 차단 관리, 채널 정보, 스트림 키 조회

## 관리 대시보드 API

봇이랑 같이 웹 서버가 켜져! REST API로 관리할 수 있어~

```sh
# 상태 확인
curl http://localhost:8080/status

# 유저 목록
curl http://localhost:8080/users

# 금칙어 관리
curl http://localhost:8080/banned-words
curl -X POST http://localhost:8080/banned-words -H "Content-Type: application/json" -d '{"word":"나쁜말"}'
curl -X DELETE http://localhost:8080/banned-words -H "Content-Type: application/json" -d '{"word":"나쁜말"}'

# 커스텀 명령어 관리
curl http://localhost:8080/commands
curl -X POST http://localhost:8080/commands -H "Content-Type: application/json" -d '{"name":"인사","response":"{{user}}님 안녕!"}'
curl -X DELETE http://localhost:8080/commands -H "Content-Type: application/json" -d '{"name":"인사"}'

# 고급 명령어 (Gleam)
curl -X POST http://localhost:8080/commands/advanced -H "Content-Type: application/json" -d '{"name":"greet","source_code":"pub fn handle(user: String, _args: List(String)) -> String { user <> \"님!\" }"}'
curl -X POST http://localhost:8080/commands/compile -H "Content-Type: application/json" -d '{"name":"greet"}'

# 투표 관리
curl http://localhost:8080/votes
curl -X POST http://localhost:8080/votes -H "Content-Type: application/json" -d '{"topic":"좋아하는 색","options":["빨강","파랑"]}'
curl -X DELETE http://localhost:8080/votes

# 퀴즈 관리
curl http://localhost:8080/quizzes
curl -X POST http://localhost:8080/quizzes -H "Content-Type: application/json" -d '{"question":"1+1=?","answer":"2","reward":10}'
curl -X DELETE http://localhost:8080/quizzes -H "Content-Type: application/json" -d '{"question":"1+1=?"}'

# 플러그인 관리
curl http://localhost:8080/plugins
curl -X POST http://localhost:8080/plugins -H "Content-Type: application/json" -d '{"name":"attendance","enabled":false}'

# 신청곡 관리 (인증 불필요!)
curl http://localhost:8080/songs
curl http://localhost:8080/songs/current
curl -X POST http://localhost:8080/songs -H "Content-Type: application/json" -d '{"video_id":"dQw4w9WgXcQ","title":"Never Gonna Give You Up","duration_seconds":212}'
curl -X DELETE http://localhost:8080/songs -H "Content-Type: application/json" -d '{"id":1}'
curl -X POST http://localhost:8080/songs/next
curl -X POST http://localhost:8080/songs/previous
curl -X POST http://localhost:8080/songs/replay
curl -X POST http://localhost:8080/songs/reorder -H "Content-Type: application/json" -d '{"id":2,"new_position":0}'
```

```sh
# 씨미 연동 (CIME_CLIENT_ID 설정 시 활성화)
curl http://localhost:8080/oauth/status
curl http://localhost:8080/cime/live-status
curl http://localhost:8080/cime/live-setting
curl http://localhost:8080/cime/chat-settings
curl http://localhost:8080/cime/blocked-users
curl http://localhost:8080/cime/channel-info
curl http://localhost:8080/cime/stream-key
curl "http://localhost:8080/cime/categories?keyword=게임"
```

`KIRA_ADMIN_KEY`(또는 설정 마법사에서 설정한 비밀번호)가 있으면 인증이 필요해져!

- **브라우저**: 로그인 페이지에서 비밀번호 입력 (쿠키로 자동 기억)
- **API**: Bearer 토큰 사용

```sh
curl -H "Authorization: Bearer 내비밀키" http://localhost:8080/users
```

## 구현 현황

### 핵심 기능
- [x] 메시지 처리 시스템
- [x] 명령어 파서 (`!명령어 인자1 인자2` 형식)
- [x] 쿨다운 관리 (도배 방지! 기본 5초)
- [x] 권한 체계 (방송인 > 매니저 > 구독자 > 시청자)
- [x] 설정 외부화 (대시보드에서 전부 바꿀 수 있어! 환경변수 불필요!)
- [x] OTP 로깅 (info/warn/error)

### 플러그인 (17개!)
- [x] 출석체크 (`!출석`) - 하루 1회 제한, 포인트 보상
- [x] 포인트 시스템 (`!포인트`, `!포인트 순위`) - SQLite 저장
- [x] 미니게임 (`!게임 주사위`, `!게임 가위바위보`) - 포인트 연동
- [x] 채팅 필터 (`!필터 추가/삭제/목록`) - DB 영속화, 금칙어 위반 시 자동 차단
- [x] 커스텀 명령 (`!명령 추가/삭제/목록`) - 템플릿 DSL 지원 (`{{user}}`, `{{if}}`)
- [x] 고급 명령 (`!명령 고급추가/고급삭제`) - Gleam 런타임 컴파일 + BEAM 핫로드
- [x] 업타임 (`!업타임`) - 봇 가동 시간 표시
- [x] 투표 (`!투표 시작/투표/결과/종료`) - DB 저장, 중복 투표 방지
- [x] 룰렛 (`!룰렛`) - 확률 가중치, 포인트 보상
- [x] 퀴즈 (`!퀴즈 시작`, `!퀴즈 <답>`) - 내장 퀴즈 15문제, 복수정답 지원, 최초 정답자 보상, DB 퀴즈 우선 출제
- [x] 타이머 (`!타이머 <초>`) - 1~3600초, 커스텀 메시지 지원
- [x] 신청곡 (`!노래 <URL>`) - YouTube 대기열, OBS 플레이어, 대시보드 관리, 포인트 연동, 채팅 공지
- [x] 후원 알림 - 채팅/영상 후원 알림, 익명 후원 지원, `!후원순위` 랭킹
- [x] 구독 알림 - 구독 환영 메시지, 티어/개월 표시, 장기 구독자 특별 메시지
- [x] 방송 제어 - `!제목/태그/카테고리/슬로우모드/팔로워전용/공지/방송상태/라이브`
- [x] 차단 관리 - `!차단/차단해제/차단목록`, 필터 자동 차단 연동
- [x] 팔로워 추적 - 새 팔로워 자동 환영, `!팔로워` 카운트

### 플랫폼 연결
- [x] 어댑터 인터페이스 (어떤 플랫폼이든 연결 가능하게!)
- [x] 연습용 Mock 어댑터
- [x] 씨미(ci.me) 어댑터 (OAuth + WebSocket + REST API 전체 연동!)
- [x] WebSocket 상태 머신 (2시간 WS / 12시간 세션 자동 재연결)
- [x] OAuth 2.0 토큰 관리 (자동 갱신, DB 복원)
- [x] CimeApi 파사드 (24개 API 엔드포인트 래핑)
- [x] 역할 자동 매핑 (streaming-roles → 권한 체계)
- [x] 이모지 토큰 처리 (strip/placeholder/HTML 렌더링)

### 시스템
- [x] 이벤트 버스 (OTP actor 기반, 쿨다운 내장)
- [x] 플러그인 레지스트리 (팩토리 패턴)
- [x] OTP Supervisor (자동 재시작!)
- [x] 플러그인 자동 재구독 (이벤트 버스 재시작 시)
- [x] SQLite 데이터 저장 (마이그레이션 v6)
- [x] 관리 대시보드 (Lustre 서버 컴포넌트, WebSocket 실시간 업데이트, 14개 탭!)
- [x] 대시보드 탭 카테고리 그룹핑 (기본/채팅 관리/엔터테인먼트/씨미)
- [x] 테스트 모드 시 씨미 전용 탭 자동 숨김 (14 → 10개)
- [x] 첫 접속 환영 배너 + 다음 단계 가이드
- [x] 로그인 페이지 (비밀번호 + 쿠키 세션, Bearer 토큰도 지원)
- [x] 첫 실행 설정 마법사 (가이드 포함, Redirect URI 복사 버튼, 자동 재시작)
- [x] 대시보드 설정 탭에서 시스템/게임 설정 편집 (단위/범위 힌트 표시!)
- [x] 설정 우선순위: DB(UI 입력) > 환경변수 > 기본값 (환경변수 없이도 OK!)
- [x] 설정 변경 후 대시보드에서 원클릭 재시작
- [x] 탭 전환 로딩 스피너 (데이터 로딩 중 표시)
- [x] 씨미 연결 상태 실시간 표시 (연결됨/끊김/재연결 중)
- [x] 채널 ID 자동 조회 (OAuth 인증 후 자동 저장)
- [x] OAuth 결과 페이지 (성공/실패 안내 + 대시보드 링크)
- [x] 구체적 에러 메시지 (한국어 안내 + 다음 행동 안내)
- [x] 데이터 로드 실패 시 토스트 알림 (조용한 실패 제거)
- [x] DB 마이그레이션 버전 관리
- [x] Docker Compose 지원 (healthcheck, docker-start.sh 래퍼)
- [x] 플랫폼별 설치 패키지 (macOS .dmg, Windows .bat, Linux .desktop)
- [x] 대시보드 서버 사이드 렌더링 (Model-View-Update, DOM 패치 전송)
- [x] 퀴즈 DB 관리 (대시보드)
- [x] 플러그인 ON/OFF (대시보드, 17개 플러그인)
- [x] OBS 브라우저 소스 플레이어 (`/player`)
- [x] YouTube Data API v3 연동
- [x] 대시보드 씨미 연동 관리 (OAuth 인증/해제)
- [x] 대시보드 방송 설정 (제목/태그/카테고리 변경)
- [x] 대시보드 채팅 설정 (슬로우모드/팔로워전용)
- [x] 대시보드 차단 관리 (차단/해제 UI)
- [x] 대시보드 채널 정보 (봇 계정, 방송 상태, 스트림 키)
- [x] 릴리스 패키징 (Erlang 런타임 포함, GitHub Actions CI)
- [x] 비밀번호 분실 안내 (로그인 페이지에서 재설정 방법 안내)
- [x] 시작 스크립트 (Linux/Mac/Windows, 브라우저 자동 열기, 포트 충돌 감지)
- [x] 테스트 265개! 전부 통과!

## 퀴즈 문제 목록

내장 퀴즈 15문제가 들어있어! 추후 대시보드에서 스트리머가 직접 관리할 수 있게 할 예정이야~

| 문제 | 정답 | 보상 |
|------|------|------|
| 스토푸리의 정식 명칭은? | 스트로베리 프린스 | 10pt |
| 스토푸리의 리더는 누구? | 나나모리 | 10pt |
| 스토푸리가 결성된 날짜는? (YYYY-MM-DD) | 2016-06-04 | 20pt |
| 리누의 멤버 컬러는? | 빨강, 빨간색, 레드 | 10pt |
| 루토의 멤버 컬러는? | 노랑, 노란색, 옐로우 | 10pt |
| 코론의 멤버 컬러는? | 하늘색, 파랑, 파란색, 블루, 스카이블루 | 10pt |
| 사토미의 멤버 컬러는? | 핑크, 분홍, 분홍색 | 10pt |
| 제루의 멤버 컬러는? | 오렌지, 주황, 주황색 | 10pt |
| 나나모리의 멤버 컬러는? | 보라, 보라색, 퍼플 | 10pt |
| 스토푸리에서 작곡을 주로 담당하는 최연소 멤버는? | 루토 | 15pt |
| 스토푸리의 첫 번째 미니앨범 이름은? | 스트로베리 스타트 | 20pt |
| 요괴워치 애니메이션 오프닝으로 사용된 스토푸리 곡은? | 반짝쿵은하 | 20pt |
| 스토푸리 멤버 중 관서 사투리(칸사이벤)가 매력인 멤버는? | 제루 | 15pt |
| 스토푸리 멤버 중 최연장자는? | 사토미 | 15pt |
| 스토푸리 팬들의 이름은? | 스토푸리스나, 스토푸리스너 | 15pt |

띄어쓰기 무시하고 비교하니까 "스카이 블루"도 "스카이블루"로 인정돼!

## 기술 스택

- **언어**: [Gleam](https://gleam.run) (반짝반짝 예쁜 언어!)
- **런타임**: BEAM/OTP (엄청 안정적이야!)
- **데이터베이스**: SQLite via sqlight (가볍고 빨라!)
- **웹 서버**: wisp + mist (HTTP + WebSocket!)
- **대시보드**: [Lustre](https://hexdocs.pm/lustre/) v5 서버 컴포넌트 (TEA 아키텍처, WebSocket 실시간 업데이트!)
- **대상 플랫폼**: [씨미(ci.me)](https://ci.me)

## 프로젝트 구조

```
src/
├── kira_caster.gleam            # 여기서 시작해! (어댑터 자동 선택)
├── kira_caster/
│   ├── core/                    # 순수한 로직들 (외부 의존 없음!)
│   │   ├── config.gleam         # 설정 타입 (씨미 설정 포함)
│   │   ├── command.gleam        # 명령어 파서
│   │   ├── cooldown.gleam       # 쿨다운 관리
│   │   ├── message.gleam        # 메시지 타입
│   │   ├── permission.gleam     # 권한 체계
│   │   ├── quiz_data.gleam      # 퀴즈 데이터
│   │   └── template.gleam       # 템플릿 DSL 엔진
│   ├── plugin/                  # 플러그인들! (17개!)
│   │   ├── plugin.gleam         # 플러그인 인터페이스 + 이벤트 타입
│   │   ├── attendance.gleam     # 출석체크
│   │   ├── points.gleam         # 포인트
│   │   ├── minigame.gleam       # 미니게임
│   │   ├── filter.gleam         # 채팅 필터 (자동 차단 연동)
│   │   ├── custom_command.gleam # 커스텀 명령 (템플릿 + 고급)
│   │   ├── advanced_command.gleam # 고급 명령 Gleam 컴파일러
│   │   ├── uptime.gleam         # 업타임
│   │   ├── vote.gleam           # 투표
│   │   ├── roulette.gleam       # 룰렛
│   │   ├── quiz.gleam           # 퀴즈
│   │   ├── timer.gleam          # 타이머
│   │   ├── song_request.gleam   # 신청곡 (YouTube + 채팅 공지)
│   │   ├── donation_alert.gleam # 후원 알림 + 랭킹
│   │   ├── subscription_alert.gleam # 구독 알림
│   │   ├── broadcast_control.gleam  # 방송 제어 (제목/태그/카테고리/공지)
│   │   ├── block.gleam          # 차단 관리 (자동 차단 포함)
│   │   └── follower.gleam       # 팔로워 추적 + 환영
│   ├── platform/                # 플랫폼 연결
│   │   ├── adapter.gleam        # 어댑터 인터페이스
│   │   ├── mock_adapter.gleam   # 연습용
│   │   ├── cime_adapter.gleam   # 씨미 어댑터 (OAuth + WS + REST)
│   │   ├── ws.gleam             # 웹소켓 상태머신
│   │   └── cime/                # 씨미 API 연동 모듈
│   │       ├── api.gleam        # CimeApi 파사드 (24개 API)
│   │       ├── http_client.gleam # HTTP 클라이언트
│   │       ├── types.gleam      # API 응답 타입
│   │       ├── decoders.gleam   # JSON 디코더
│   │       ├── token_manager.gleam # OAuth 토큰 OTP actor
│   │       ├── ws_manager.gleam # WebSocket 세션 OTP actor
│   │       ├── emoji.gleam      # 이모지 토큰 처리
│   │       └── role_resolver.gleam # 역할 매핑 캐시
│   ├── storage/                 # 데이터 저장
│   │   ├── repository.gleam     # 저장소 인터페이스
│   │   ├── sqlight_repo.gleam   # SQLite 구현
│   │   ├── migrations.gleam     # DB 마이그레이션 (v6)
│   │   └── repos/               # 개별 테이블 구현
│   ├── admin/                   # 관리 대시보드
│   │   ├── router.gleam         # HTTP 라우터 (로그인/설정/인증 분기)
│   │   ├── server.gleam         # HTTP + WebSocket 서버
│   │   ├── auth.gleam           # 인증 (쿠키 세션 + Bearer 토큰)
│   │   ├── handlers/            # 12개 REST 핸들러 (씨미 + OAuth + 설정 마법사)
│   │   ├── dashboard/           # Lustre 서버 컴포넌트 (MVU)
│   │   │   ├── app.gleam        # 앱 생성 + init
│   │   │   ├── model.gleam      # Model, Msg, Tab, 연결 상태 타입
│   │   │   ├── update.gleam     # 상태 전이
│   │   │   ├── view.gleam       # 14개 탭 UI + 연결 상태 배지
│   │   │   └── effects.gleam    # 데이터 로딩 + CRUD + 연결 상태 조회
│   │   └── views/               # 로그인/설정/대시보드/플레이어 (SSR)
│   ├── util/
│   │   ├── time.gleam           # 시간 유틸
│   │   └── youtube.gleam        # YouTube URL 파서 + API 클라이언트
│   ├── config_loader.gleam      # 환경변수 로더
│   ├── event_bus.gleam          # 이벤트 버스
│   ├── logger.gleam             # OTP 로거
│   ├── plugin_registry.gleam    # 플러그인 레지스트리
│   └── supervisor.gleam         # OTP 슈퍼바이저
├── kira_caster_ffi.erl          # Erlang FFI (시간/로깅/Gleam 컴파일)
└── cime_ws_ffi.erl              # Erlang FFI (gun WebSocket 클라이언트)
```

## 라이선스

EPL-2.0
