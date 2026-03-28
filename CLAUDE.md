# kira_caster

씨미(ci.me) 스트리밍 챗봇. Gleam 1.15.2 + BEAM/OTP 28, SQLite, wisp+mist 대시보드.

## Commands

```sh
gleam build                       # 빌드
gleam test                        # 테스트 (249개)
gleam format src test             # 포맷
gleam format --check src test     # CI 포맷 검사
gleam run                         # 실행
```

## Structure

```
core/           # 순수 함수 (외부 의존 금지)
plugin/         # 플러그인 11개 (이벤트 핸들러, 서브모듈 분리)
platform/       # 어댑터 (mock_adapter로 개발, 씨미 API 공개 후 cime_adapter 구현)
storage/        # repository.gleam(인터페이스) + sqlight_repo.gleam(facade) + repos/
admin/          # router.gleam(디스패치) + handlers/ + views/
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

- **어댑터 패턴**: platform/adapter.gleam이 인터페이스. 씨미 API 미공개 → mock_adapter로 개발
- **이벤트 흐름**: Platform → EventBus → Plugin(s) → EventBus → Platform
- **Repository 패턴**: repository.gleam이 함수 필드 레코드로 인터페이스 정의, sqlight_repo.gleam이 facade로 repos/ 위임
- **설정**: core/config.gleam 타입 정의 → config_loader.gleam 환경변수 오버라이드

## References

- Gleam 문법: [references/gleam_language_tour.md](./references/gleam_language_tour.md)
- 컬러 팔레트: [references/COLOR_PALETTE.md](./references/COLOR_PALETTE.md)
