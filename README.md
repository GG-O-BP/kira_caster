# kira_caster

씨미(ci.me) 방송에서 쓸 수 있는 챗봇이야~!

채팅창에 명령어를 치면 키라캐스터가 대답해주는 거야! 출석체크도 하고, 포인트도 모으고, 미니게임도 하고, 투표도 하고, 룰렛도 돌리고, 퀴즈도 풀 수 있어!! 진짜 재밌겠지?!

## 이런 걸 할 수 있어!

| 기능 | 설명 |
|------|------|
| 출석체크 | `!출석` 치면 오늘 출석 완료~! 하루에 한 번만 가능해! |
| 포인트 | 출석하면 포인트가 쌓여! `!포인트`로 확인, `!포인트 순위`로 랭킹! |
| 미니게임 | 주사위 굴리기, 가위바위보 할 수 있어! 이기면 포인트 UP! |
| 채팅 필터 | 나쁜 말은 자동으로 걸러줘! 착한 채팅만~ |
| 커스텀 명령 | 매니저가 직접 명령어를 만들 수 있어! |
| 업타임 | `!업타임`으로 봇이 얼마나 켜져있었는지 알 수 있어! |
| 투표 | 채팅으로 투표할 수 있어! 다 같이 정하자~! |
| 룰렛 | `!룰렛` 돌려서 운 시험해봐! 대박 나면 +100포인트! |
| 퀴즈 | 퀴즈 맞추면 포인트 GET! 누가 제일 빠를까~? |
| 관리 대시보드 | 웹에서 유저 정보, 금칙어, 명령어, 투표 관리할 수 있어! |

## 시작하는 방법

Gleam이랑 Erlang/OTP가 설치되어 있어야 해!

```sh
gleam deps download   # 필요한 것들 다운받기
gleam build           # 빌드하기
gleam run             # 실행하기!
gleam test            # 테스트 돌리기 (143개나 있어!)
```

실행하면 이렇게 나와!

```
kira_caster started with mock adapter
kira_caster running
Listening on http://127.0.0.1:8080
```

지금은 연습용(mock) 모드로 돌아가는 거야~ 씨미 API가 공개되면 진짜 방송이랑 연결할 수 있어!

### 환경변수로 설정 바꾸기

전부 선택사항이야! 안 넣으면 기본값으로 돌아가~

| 환경변수 | 설명 | 기본값 |
|----------|------|--------|
| `KIRA_DB_PATH` | 데이터베이스 파일 경로 | `kira_caster.db` |
| `KIRA_COOLDOWN_MS` | 명령어 쿨타임 (밀리초) | `5000` |
| `KIRA_ADMIN_PORT` | 대시보드 포트 | `8080` |
| `KIRA_ADMIN_KEY` | 대시보드 API 키 (비워두면 인증 없음) | `` |
| `KIRA_SECRET_KEY` | 서버 암호화 키 | 기본값 있음 |
| `KIRA_ATTENDANCE_POINTS` | 출석 보상 포인트 | `10` |
| `KIRA_DICE_WIN_POINTS` | 주사위 승리 포인트 | `50` |
| `KIRA_DICE_LOSS_POINTS` | 주사위 패배 포인트 | `-20` |
| `KIRA_RPS_WIN_POINTS` | 가위바위보 승리 포인트 | `30` |
| `KIRA_RPS_LOSS_POINTS` | 가위바위보 패배 포인트 | `-10` |

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

### 매니저 전용 명령어

| 명령어 | 설명 |
|--------|------|
| `!필터 추가 <단어>` | 금칙어 추가 |
| `!필터 삭제 <단어>` | 금칙어 삭제 |
| `!필터 목록` | 금칙어 목록 보기 |
| `!명령 추가 <이름> <응답>` | 커스텀 명령어 만들기 |
| `!명령 삭제 <이름>` | 커스텀 명령어 삭제 |
| `!명령 목록` | 커스텀 명령어 목록 보기 |
| `!투표 시작 <주제> <선택지1> <선택지2> ...` | 투표 시작하기 |
| `!투표 종료` | 투표 끝내고 결과 발표! |
| `!퀴즈 시작` | 랜덤 퀴즈 출제 |

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
curl -X POST http://localhost:8080/commands -H "Content-Type: application/json" -d '{"name":"인사","response":"안녕!"}'
curl -X DELETE http://localhost:8080/commands -H "Content-Type: application/json" -d '{"name":"인사"}'

# 투표 관리
curl http://localhost:8080/votes
curl -X POST http://localhost:8080/votes -H "Content-Type: application/json" -d '{"topic":"좋아하는 색","options":["빨강","파랑"]}'
curl -X DELETE http://localhost:8080/votes
```

`KIRA_ADMIN_KEY`를 설정하면 Bearer 토큰 인증이 필요해져!

```sh
curl -H "Authorization: Bearer 내비밀키" http://localhost:8080/users
```

## 구현 현황

### 핵심 기능
- [x] 메시지 처리 시스템
- [x] 명령어 파서 (`!명령어 인자1 인자2` 형식)
- [x] 쿨다운 관리 (도배 방지! 기본 5초)
- [x] 권한 체계 (방송인 > 매니저 > 구독자 > 시청자)
- [x] 설정 외부화 (환경변수로 전부 바꿀 수 있어!)
- [x] OTP 로깅 (info/warn/error)

### 플러그인 (9개!)
- [x] 출석체크 (`!출석`) - 하루 1회 제한, 포인트 보상
- [x] 포인트 시스템 (`!포인트`, `!포인트 순위`) - SQLite 저장
- [x] 미니게임 (`!게임 주사위`, `!게임 가위바위보`) - 포인트 연동
- [x] 채팅 필터 (`!필터 추가/삭제/목록`) - DB 영속화, 매니저 관리
- [x] 커스텀 명령 (`!명령 추가/삭제/목록`) - 매니저가 직접 만드는 명령어
- [x] 업타임 (`!업타임`) - 봇 가동 시간 표시
- [x] 투표 (`!투표 시작/투표/결과/종료`) - DB 저장, 중복 투표 방지
- [x] 룰렛 (`!룰렛`) - 확률 가중치, 포인트 보상
- [x] 퀴즈 (`!퀴즈 시작`, `!퀴즈 <답>`) - 내장 퀴즈 15문제, 복수정답 지원, 최초 정답자 보상

### 플랫폼 연결
- [x] 어댑터 인터페이스 (어떤 플랫폼이든 연결 가능하게!)
- [x] 연습용 Mock 어댑터
- [ ] 씨미(ci.me) 어댑터 (API 공개 대기중~)
- [x] WebSocket 상태 머신 (재연결 로직 포함)

### 시스템
- [x] 이벤트 버스 (OTP actor 기반, 쿨다운 내장)
- [x] 플러그인 레지스트리 (팩토리 패턴)
- [x] OTP Supervisor (자동 재시작!)
- [x] 플러그인 자동 재구독 (이벤트 버스 재시작 시)
- [x] SQLite 데이터 저장 (마이그레이션 포함)
- [x] 관리 대시보드 (wisp + mist REST API)
- [x] Bearer 토큰 인증
- [x] DB 마이그레이션 버전 관리
- [x] Docker 지원
- [x] 테스트 143개! 전부 통과!

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
- **웹 서버**: wisp + mist (관리 대시보드용!)
- **대상 플랫폼**: [씨미(ci.me)](https://ci.me)

## 프로젝트 구조

```
src/
├── kira_caster.gleam            # 여기서 시작해!
├── kira_caster/
│   ├── core/                    # 순수한 로직들 (외부 의존 없음!)
│   │   ├── config.gleam         # 설정 타입
│   │   ├── command.gleam        # 명령어 파서
│   │   ├── cooldown.gleam       # 쿨다운 관리
│   │   ├── message.gleam        # 메시지 타입
│   │   ├── permission.gleam     # 권한 체계
│   │   └── quiz_data.gleam      # 퀴즈 데이터
│   ├── plugin/                  # 플러그인들! (9개!)
│   │   ├── plugin.gleam         # 플러그인 인터페이스
│   │   ├── attendance.gleam     # 출석체크
│   │   ├── points.gleam         # 포인트
│   │   ├── minigame.gleam       # 미니게임
│   │   ├── filter.gleam         # 채팅 필터
│   │   ├── custom_command.gleam # 커스텀 명령
│   │   ├── uptime.gleam         # 업타임
│   │   ├── vote.gleam           # 투표
│   │   ├── roulette.gleam       # 룰렛
│   │   └── quiz.gleam           # 퀴즈
│   ├── platform/                # 플랫폼 연결
│   │   ├── adapter.gleam        # 어댑터 인터페이스
│   │   ├── mock_adapter.gleam   # 연습용
│   │   ├── cime_adapter.gleam   # 씨미 (준비중!)
│   │   └── ws.gleam             # 웹소켓 상태머신
│   ├── storage/                 # 데이터 저장
│   │   ├── repository.gleam     # 저장소 인터페이스
│   │   └── sqlight_repo.gleam   # SQLite 구현
│   ├── admin/                   # 관리 대시보드
│   │   ├── router.gleam         # HTTP 라우터
│   │   └── server.gleam         # 서버 시작
│   ├── util/
│   │   └── time.gleam           # 시간 유틸
│   ├── config_loader.gleam      # 환경변수 로더
│   ├── event_bus.gleam          # 이벤트 버스
│   ├── logger.gleam             # OTP 로거
│   ├── plugin_registry.gleam    # 플러그인 레지스트리
│   └── supervisor.gleam         # OTP 슈퍼바이저
└── kira_caster_ffi.erl          # Erlang FFI
```

## 라이선스

EPL-2.0
