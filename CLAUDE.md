# kira_caster

씨미(ci.me) 스트리밍 챗봇. Gleam 1.15.2 + BEAM/OTP 28, SQLite, wisp+mist 대시보드.

## Commands

```sh
gleam build                       # 빌드
gleam test                        # 테스트 (265개)
gleam format src test             # 포맷
gleam format --check src test     # CI 포맷 검사
gleam run                         # 실행
```

## Structure

```
core/           # 순수 함수 (외부 의존 금지)
plugin/         # 플러그인 17개 (이벤트 핸들러, 서브모듈 분리)
platform/       # adapter.gleam(인터페이스) + cime_adapter + mock_adapter + ws.gleam(상태머신)
platform/cime/  # 씨미 API 연동 (http_client, types, decoders, api, token_manager, ws_manager, emoji, role_resolver)
storage/        # repository.gleam(인터페이스) + sqlight_repo.gleam(facade) + repos/
admin/          # router.gleam(디스패치) + handlers/11개 + views/(dashboard, player)
util/           # time, youtube(facade + url_parser/api/duration)
```

## Rules

### MUST

- core/ 모듈은 순수 함수만. IO/DB/네트워크 의존성 MUST NOT import
- 새 기능은 plugin/로 구현. core 수정 전 플러그인 분리 가능한지 먼저 검토
- 에러 처리는 Result 타입. panic/let assert는 테스트에서만 허용
- 새 플러그인 추가 시 해당 테스트 모듈 반드시 함께 작성
- SQL 쿼리는 storage/repos/ 안에서만 작성
- 플러그인 간 통신은 반드시 이벤트 버스 경유 (직접 함수 호출 금지)
- adapter 인터페이스는 플랫폼 중립 유지
- 비동기 작업은 gleam_otp actor 사용 (process.sleep/무한 루프 금지)
- 대시보드 스타일링 시 [references/COLOR_PALETTE.md](./references/COLOR_PALETTE.md) 팔레트 준수
- DB 마이그레이션은 storage/migrations.gleam에서 schema_version 순차 관리

### Architecture Decisions

- **어댑터 패턴**: platform/adapter.gleam이 인터페이스 (send_message, connect, disconnect). cime_adapter가 씨미 API 연동 구현체, mock_adapter는 테스트/개발용
- **이벤트 흐름**: Platform → EventBus → Plugin(s) → EventBus → Platform
- **Repository 패턴**: repository.gleam이 함수 필드 레코드로 인터페이스 정의, sqlight_repo.gleam이 facade로 repos/ 위임
- **설정**: core/config.gleam 타입 정의 → config_loader.gleam 환경변수(KIRA_*) 오버라이드
- **WebSocket 상태**: platform/ws.gleam이 Disconnected→Connected→Reconnecting 상태 머신 관리

### 씨미 API 연동 가이드

씨미 OpenAPI가 공개되어 cime_adapter 구현이 가능하다. 상세 명세는 [references/cime_api/](./references/cime_api/) 참조.

**인증**
- Client ID/Secret: 공개 정보 조회 (채널, 라이브 목록)
- OAuth 2.0 Authorization Code Flow: 사용자 권한 API (채팅 전송, 이벤트 구독)
- Access Token 1시간 만료 → Refresh Token으로 자동 갱신 필요

**채팅 봇 핵심 API**
- 채팅 메시지 전송: `POST /api/openapi/open/v1/chats/send` (100자 제한, Scope: WRITE:LIVE_CHAT)
- 채팅 이벤트 수신: WebSocket 세션 기반 (Scope: READ:LIVE_CHAT)
- 사용자 추방/해제: `POST|DELETE /api/openapi/open/v1/restrict-channels` (Scope: WRITE:USER_BLOCK)

**WebSocket 이벤트 흐름**
```
세션 생성 (GET /sessions/auth) → WS 연결 (wss://) → 이벤트 구독 (POST /sessions/events/subscribe/{event})
```
- 지원 이벤트: CHAT, DONATION, SUBSCRIPTION
- 1분 간격 PING 필수 ({"type":"PING"}), 10분 유휴 타임아웃
- WS 최대 2시간 유지, 세션 12시간 유효
- 끊김 시: 토큰 갱신 → 세션 재생성 → WS 재연결 → 이벤트 재구독

**cime_adapter 구현 시 필요 환경변수** (config.gleam, config_loader.gleam에 추가)
- `CIME_CLIENT_ID` / `CIME_CLIENT_SECRET`: 앱 인증
- `CIME_REDIRECT_URI`: OAuth 콜백 URL
- `CIME_CHANNEL_ID`: 봇이 연결할 채널 ID

## References

- Gleam 문법: [references/gleam_language_tour.md](./references/gleam_language_tour.md)
- 컬러 팔레트: [references/COLOR_PALETTE.md](./references/COLOR_PALETTE.md)
- 씨미 API: [references/cime_api/](./references/cime_api/) (overview, authentication, api/, events_sessions/)
