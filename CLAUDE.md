# kira_caster

씨미(ci.me) 스트리밍 플랫폼용 챗봇. Gleam + BEAM/OTP 타겟.

## Quick Start

```sh
gleam build          # 빌드
gleam run            # 실행
gleam test           # 테스트 (gleeunit)
gleam format src test  # 포매팅
gleam format --check src test  # CI 포맷 검사
gleam deps download  # 의존성 다운로드
```

## Architecture

플랫폼 어댑터 패턴 + OTP actor 기반 이벤트 버스 + 플러그인 시스템.

```
src/
├── kira_caster.gleam        # 엔트리포인트
├── core/                    # 도메인 로직 (순수 함수 중심)
│   ├── message.gleam        # 메시지 타입 정의
│   ├── command.gleam        # 명령어 파서
│   ├── cooldown.gleam       # 쿨다운 관리
│   └── permission.gleam     # 권한 체계
├── platform/                # 플랫폼 어댑터 (외부 의존성 경계)
│   ├── adapter.gleam        # 어댑터 인터페이스 (레코드 + 함수 필드)
│   ├── mock_adapter.gleam   # Mock 어댑터 (API 없이 개발용)
│   ├── cime_adapter.gleam   # 씨미 어댑터 (API 공개 후 구현)
│   └── ws.gleam             # WebSocket 연결 관리
├── storage/                 # 데이터 영속화
│   ├── repository.gleam     # Repository 인터페이스
│   └── sqlight_repo.gleam   # SQLite 구현체
├── plugin/                  # 플러그인 모듈
│   ├── plugin.gleam         # 플러그인 인터페이스
│   ├── attendance.gleam     # 출석
│   ├── points.gleam         # 포인트
│   ├── minigame.gleam       # 미니게임
│   └── filter.gleam         # 채팅 필터
└── event_bus.gleam          # OTP actor 기반 이벤트 버스
```

## Stack

- **Runtime**: BEAM/OTP (Erlang 타겟)
- **WS**: stratus
- **HTTP**: gleam_httpc
- **JSON**: gleam_json
- **Auth**: glow_auth (OAuth)
- **Concurrency**: gleam_otp (actors, supervisors)
- **DB**: sqlight (SQLite)
- **Web**: wisp + mist (관리 대시보드용)

## Key Patterns

### 어댑터 패턴

모든 플랫폼 통신은 adapter 인터페이스를 통해 추상화. 씨미 API가 미공개 상태이므로 mock_adapter로 개발하고, API 공개 시 cime_adapter만 추가하면 됨.

```gleam
// adapter.gleam - 인터페이스 정의
pub type Adapter {
  Adapter(
    send_message: fn(String) -> Result(Nil, AdapterError),
    connect: fn() -> Result(Nil, AdapterError),
    disconnect: fn() -> Result(Nil, AdapterError),
  )
}
```

### OTP Actor 이벤트 버스

플러그인 간 통신은 이벤트 버스(gleam_otp actor)를 통해 처리. 플러그인이 직접 서로를 호출하지 않음.

```gleam
// 이벤트 흐름: Platform → EventBus → Plugin(s) → EventBus → Platform
pub type Event {
  ChatMessage(user: String, content: String)
  Command(user: String, name: String, args: List(String))
  PluginResponse(plugin: String, message: String)
}
```

### 플러그인 구조

플러그인은 독립적 모듈. 이벤트를 받아 처리하고 응답 이벤트를 발행.

```gleam
pub type Plugin {
  Plugin(
    name: String,
    handle_event: fn(Event) -> List(Event),
  )
}
```

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

- **초기 개발 단계**: 스캐폴딩만 완료, 아키텍처 구현 진행 중
- **씨미 API 미공개**: 4~5월 공개 예정. mock_adapter로 개발
- **Gleam 1.15.2 / OTP 28** 타겟
- CI: GitHub Actions (`gleam test` + `gleam format --check`)

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
