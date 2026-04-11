#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env if exists
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

PORT="${KIRA_ADMIN_PORT:-9693}"

# Check dependencies
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "오류: $1 이(가) 설치되어 있지 않습니다."
    echo ""
    echo "설치 방법:"
    echo "  $2"
    echo ""
    echo "설치 후 이 스크립트를 다시 실행해주세요."
    exit 1
  fi
}

# Check port availability
check_port() {
  if command -v ss &>/dev/null; then
    if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
      echo "오류: 포트 $PORT이(가) 이미 사용 중입니다."
      echo ""
      echo "해결 방법:"
      echo "  1. 다른 프로그램이 같은 포트를 사용하고 있는지 확인하세요"
      echo "  2. 포트 번호를 변경하려면 프로그램 폴더의 .env 파일을 열고"
      echo "     KIRA_ADMIN_PORT=8081 로 수정한 뒤 저장하세요"
      echo "     (.env 파일이 없으면 .env.example을 .env로 복사한 후 수정하세요)"
      exit 1
    fi
  elif command -v lsof &>/dev/null; then
    if lsof -iTCP:"$PORT" -sTCP:LISTEN &>/dev/null; then
      echo "오류: 포트 $PORT이(가) 이미 사용 중입니다."
      echo ""
      echo "해결 방법:"
      echo "  1. 다른 프로그램이 같은 포트를 사용하고 있는지 확인하세요"
      echo "  2. 포트 번호를 변경하려면 프로그램 폴더의 .env 파일을 열고"
      echo "     KIRA_ADMIN_PORT=8081 로 수정한 뒤 저장하세요"
      echo "     (.env 파일이 없으면 .env.example을 .env로 복사한 후 수정하세요)"
      exit 1
    fi
  fi
}

# If pre-built release (erlang/ directory exists), use it directly
if [ -d "erlang" ]; then
  check_command "erl" "https://www.erlang.org/downloads 에서 Erlang을 설치해주세요"
  check_port
  echo "kira_caster 시작 중... http://localhost:$PORT"

  # Auto-open browser
  if command -v xdg-open &>/dev/null; then
    (sleep 2 && xdg-open "http://localhost:$PORT") &
  elif command -v open &>/dev/null; then
    (sleep 2 && open "http://localhost:$PORT") &
  fi

  exec erl -pa erlang/*/ebin -noshell -eval "gleam@@main:run(kira_caster)"
fi

# Development mode: build and run with gleam
check_command "gleam" "https://gleam.run/getting-started/installing/ 에서 Gleam을 설치해주세요"

# Build if needed
if [ ! -d "build/dev/erlang" ]; then
  echo "처음 실행: 빌드 중..."
  gleam deps download
  gleam build
fi

check_port
echo "kira_caster 시작 중... http://localhost:$PORT"

# Auto-open browser
if command -v xdg-open &>/dev/null; then
  (sleep 2 && xdg-open "http://localhost:$PORT") &
elif command -v open &>/dev/null; then
  (sleep 2 && open "http://localhost:$PORT") &
fi

exec gleam run
