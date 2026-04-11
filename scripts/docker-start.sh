#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# .env 파일이 없으면 자동 생성
if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env 파일이 생성되었습니다."
fi

# 포트 읽기
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi
PORT="${KIRA_ADMIN_PORT:-8080}"

echo ""
echo "====================================="
echo "  kira_caster 시작 중..."
echo "====================================="
echo ""
echo "  아래 주소를 브라우저에서 열어주세요:"
echo ""
echo "  >>> http://localhost:$PORT <<<"
echo ""
echo "====================================="
echo ""

# 브라우저 자동 열기 시도
(sleep 5 && {
  if command -v xdg-open &>/dev/null; then
    xdg-open "http://localhost:$PORT" 2>/dev/null
  elif command -v open &>/dev/null; then
    open "http://localhost:$PORT"
  fi
}) &

docker compose up
