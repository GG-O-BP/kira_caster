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

PORT="${KIRA_ADMIN_PORT:-8080}"

# Check dependencies
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "오류: $1 이(가) 설치되어 있지 않습니다."
    echo ""
    echo "$2"
    exit 1
  fi
}

# If pre-built release (erlang/ directory exists), use it directly
if [ -d "erlang" ]; then
  check_command "erl" "Erlang을 설치해주세요: https://www.erlang.org/downloads"
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
check_command "gleam" "Gleam을 설치해주세요: https://gleam.run/getting-started/installing/"

# Build if needed
if [ ! -d "build/dev/erlang" ]; then
  echo "처음 실행: 빌드 중..."
  gleam deps download
  gleam build
fi

echo "kira_caster 시작 중... http://localhost:$PORT"

# Auto-open browser
if command -v xdg-open &>/dev/null; then
  (sleep 2 && xdg-open "http://localhost:$PORT") &
elif command -v open &>/dev/null; then
  (sleep 2 && open "http://localhost:$PORT") &
fi

exec gleam run
