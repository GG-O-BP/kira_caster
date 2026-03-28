# kira_caster

씨미(ci.me) 스트리밍 플랫폼용 챗봇. Gleam + BEAM/OTP 타겟.

## Quick Start

```sh
gleam deps download  # 의존성 다운로드
gleam build          # 빌드
gleam run            # 실행
gleam test           # 테스트 (gleeunit, 249개)
gleam format src test  # 포매팅
gleam format --check src test  # CI 포맷 검사
```

## Architecture

플랫폼 어댑터 패턴 + OTP actor 기반 이벤트 버스 + 플러그인 시스템 + 관리 대시보드.

```
src/
├── kira_caster.gleam            # 엔트리포인트
├── kira_caster/
│   ├── core/                    # 도메인 로직 (순수 함수, 외부 의존 없음)
│   │   ├── config.gleam         # 설정 타입 + default()
│   │   ├── command.gleam        # 명령어 파서
│   │   ├── cooldown.gleam       # 쿨다운 관리
│   │   ├── message.gleam        # 메시지 타입 정의
│   │   ├── permission.gleam     # 권한 체계 (Broadcaster > Moderator > Subscriber > Viewer)
│   │   └── quiz_data.gleam      # 내장 퀴즈 데이터 (추후 DB 관리 예정)
│   ├── plugin/                  # 플러그인 (11개)
│   │   ├── plugin.gleam         # 플러그인 인터페이스 + Event 타입
│   │   ├── attendance.gleam     # 출석 (하루 1회, 포인트 보상)
│   │   ├── points.gleam         # 포인트 조회/순위 + PointsChange 핸들
│   │   ├── minigame.gleam       # 주사위 + 가위바위보
│   │   ├── filter.gleam         # 채팅 필터 (DB 금칙어 + 모더레이터 관리)
│   │   ├── custom_command.gleam # 커스텀 명령 (DB 저장)
│   │   ├── uptime.gleam         # 봇 가동 시간
│   │   ├── vote.gleam           # 투표 (DB 저장, 중복 방지)
│   │   ├── roulette.gleam       # 룰렛 (확률 가중치)
│   │   ├── quiz.gleam           # 퀴즈 (DB 우선, 내장 폴백)
│   │   ├── timer.gleam          # 타이머 (비동기 알림)
│   │   └── song_request.gleam   # 신청곡 (YouTube 대기열, OBS 플레이어)
│   ├── platform/                # 플랫폼 어댑터 (외부 의존성 경계)
│   │   ├── adapter.gleam        # 어댑터 인터페이스 (레코드 + 함수 필드)
│   │   ├── mock_adapter.gleam   # Mock 어댑터 (개발용)
│   │   ├── cime_adapter.gleam   # 씨미 어댑터 (API 공개 후 구현)
│   │   └── ws.gleam             # WebSocket 상태 머신
│   ├── storage/                 # 데이터 영속화
│   │   ├── repository.gleam     # Repository 인터페이스 + mock_repo
│   │   └── sqlight_repo.gleam   # SQLite 구현체 (마이그레이션 v1~v5)
│   ├── admin/                   # 관리 대시보드 (wisp + mist)
│   │   ├── router.gleam         # REST API + HTML 프론트엔드
│   │   └── server.gleam         # HTTP 서버 시작
│   ├── util/
│   │   ├── time.gleam           # now_ms() 시간 유틸
│   │   └── youtube.gleam        # YouTube URL 파서 + Data API v3 클라이언트
│   ├── config_loader.gleam      # 환경변수 → Config 로더
│   ├── event_bus.gleam          # OTP actor 이벤트 버스 (쿨다운, 플러그인 ON/OFF 내장)
│   ├── logger.gleam             # OTP logger 래퍼 (info/warn/error)
│   ├── plugin_registry.gleam    # 플러그인 팩토리 레지스트리
│   └── supervisor.gleam         # OTP static supervisor (OneForOne)
└── kira_caster_ffi.erl          # Erlang FFI (now_ms, get_env, log_*)
```

## Stack

- **Runtime**: BEAM/OTP (Erlang 타겟), Gleam 1.15.2 / OTP 28
- **JSON**: gleam_json
- **Concurrency**: gleam_otp (actors, supervisors)
- **DB**: sqlight (SQLite)
- **Web**: wisp + mist (관리 대시보드)
- **HTTP**: gleam_http
- **HTTP client**: gleam_httpc (YouTube API 호출)
- **미사용 (씨미 API 공개 후)**: stratus (WS), glow_auth (OAuth)

## Key Patterns

### 어댑터 패턴

모든 플랫폼 통신은 adapter 인터페이스를 통해 추상화. 씨미 API가 미공개 상태이므로 mock_adapter로 개발하고, API 공개 시 cime_adapter만 추가하면 됨.

```gleam
pub type Adapter {
  Adapter(
    send_message: fn(String) -> Result(Nil, AdapterError),
    connect: fn() -> Result(Nil, AdapterError),
    disconnect: fn() -> Result(Nil, AdapterError),
  )
}
```

### OTP Actor 이벤트 버스

플러그인 간 통신은 이벤트 버스(gleam_otp actor)를 통해 처리. 쿨다운 내장, 플러그인 ON/OFF 지원.

```gleam
// 이벤트 흐름: Platform → EventBus → Plugin(s) → EventBus → Platform
pub type Event {
  ChatMessage(user: String, content: String, channel: String)
  Command(user: String, name: String, args: List(String), role: permission.Role)
  PluginResponse(plugin: String, message: String)
  SystemEvent(kind: String, data: String)
  PointsChange(user: String, amount: Int, reason: String)
}
```

### 플러그인 구조

플러그인은 독립적 모듈. 이벤트를 받아 처리하고 응답 이벤트를 발행. PluginRegistry로 팩토리 관리, Supervisor 재시작 시 자동 재구독.

```gleam
pub type Plugin {
  Plugin(
    name: String,
    handle_event: fn(Event) -> List(Event),
  )
}
```

### 설정 외부화

모든 설정은 `core/config.gleam`에 타입 정의, `config_loader.gleam`에서 환경변수로 오버라이드. 환경변수 없으면 기본값 사용.

### DB 마이그레이션

`sqlight_repo.gleam`의 `run_migrations`에서 `schema_version` 테이블로 버전 관리. v1(기본 테이블), v2(plugin_settings) 순차 실행.

## Rules

### DO

- core/ 모듈은 순수 함수로 작성. 외부 의존성(IO, DB, 네트워크) 없이 테스트 가능해야 함
- 새 기능은 plugin/ 모듈로 구현. 기존 core를 수정하기 전에 플러그인으로 분리 가능한지 먼저 검토
- Result 타입으로 에러 처리. panic/assert는 테스트에서만 사용
- 새 플러그인 추가 시 반드시 해당 테스트 모듈도 함께 작성
- 패턴 매칭 적극 활용, case 표현식 선호
- 웹 UI(대시보드 등) 스타일링 시 [references/COLOR_PALETTE.md](./references/COLOR_PALETTE.md)의 컬러 팔레트를 따를 것

### DO NOT

- core/ 모듈에서 gleam_otp, stratus, sqlight 등 외부 패키지를 직접 import하지 않음
- 플러그인 간 직접 함수 호출 금지. 반드시 이벤트 버스를 통해 통신
- gleam_erlang의 process.sleep이나 무한 루프를 직접 사용하지 않음. gleam_otp의 actor를 사용
- adapter 인터페이스를 특정 플랫폼에 종속적으로 변경하지 않음
- let assert는 프로덕션 코드에서 사용하지 않음 (테스트에서만 허용)
- SQL 쿼리를 repository 인터페이스 밖에 작성하지 않음

## Current State

- **기능 구현 완료**: 플러그인 11개, 관리 대시보드 (REST API + HTML), OTP Supervisor, 플러그인 ON/OFF, 신청곡 OBS 플레이어
- **씨미 API 미공개**: 4~5월 공개 예정. mock_adapter로 개발
- **Gleam 1.15.2 / OTP 28** 타겟
- CI: GitHub Actions (`gleam test` + `gleam format --check`)
- Docker: Dockerfile 포함 (multi-stage build)
- 테스트: 249개 전체 통과

## Gleam Specifics

Gleam 문법 상세 레퍼런스는 [./references/gleam_language_tour.md](./references/gleam_language_tour.md) 참고.

- `use` 표현식은 콜백 체이닝에 활용 (`result.try`, `result.map` 등)
- `echo` 키워드로 타입 무관 디버그 출력 (`echo value` — 개발 중 자유롭게 사용, 커밋 전 제거)
- `assert expr` 는 테스트 전용 boolean 단언 (`assert add(1, 2) == 3`)
- 문자열 연결은 `<>` 연산자
- 리스트는 `[first, ..rest]` 패턴 매칭
- pipe 연산자 `|>` 적극 사용
- 타입은 `pub type`으로 정의, 생성자는 대문자로 시작
- 모듈은 파일 경로가 곧 모듈 경로 (`src/core/message.gleam` → `core/message`)
- 외부 Erlang/JavaScript 함수 호출 시 `@external(erlang, ...)` 또는 `@external(javascript, ...)` 어트리뷰트 사용
