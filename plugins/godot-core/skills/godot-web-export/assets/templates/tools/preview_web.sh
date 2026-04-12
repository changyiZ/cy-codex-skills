#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/web}"
PORT="${PORT:-8000}"
STATE_DIR="$ROOT_DIR/.godot/dev"
PID_FILE="$STATE_DIR/web_preview_${PORT}.pid"
LOG_FILE="$STATE_DIR/web_preview_${PORT}.log"

mkdir -p "$STATE_DIR"

action="${1:-restart}"

is_pid_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

get_pid_command() {
  local pid="$1"
  ps -o command= -p "$pid" 2>/dev/null || true
}

get_pid_cwd() {
  local pid="$1"
  lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1
}

is_project_preview_pid() {
  local pid="$1"
  local cmd cwd
  cmd="$(get_pid_command "$pid")"
  cwd="$(get_pid_cwd "$pid")"
  [[ -n "$cmd" ]] || return 1
  [[ "$cmd" == *"-m http.server ${PORT}"* ]] || return 1
  [[ "$cwd" == "$BUILD_DIR" || "$cmd" == *"--directory ${BUILD_DIR}"* ]]
}

find_listener_on_port() {
  lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1 || true
}

stop_project_preview() {
  local pid=""

  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE")"
  fi

  if [[ -n "$pid" ]] && is_pid_running "$pid" && is_project_preview_pid "$pid"; then
    kill "$pid"
    for _ in $(seq 1 20); do
      if ! is_pid_running "$pid"; then
        break
      fi
      sleep 0.1
    done
  fi

  rm -f "$PID_FILE"

  pid="$(find_listener_on_port)"
  if [[ -z "$pid" ]]; then
    return 0
  fi

  if is_project_preview_pid "$pid"; then
    kill "$pid"
    for _ in $(seq 1 20); do
      if ! is_pid_running "$pid"; then
        break
      fi
      sleep 0.1
    done
    return 0
  fi

  echo "Port $PORT is already in use by PID $pid and was not started by this project preview script." >&2
  echo "Refusing to kill an unknown process. Inspect with: lsof -iTCP:$PORT -sTCP:LISTEN" >&2
  exit 1
}

start_preview() {
  if [[ ! -d "$BUILD_DIR" ]]; then
    echo "Build directory not found: $BUILD_DIR" >&2
    exit 1
  fi

  local pid
  nohup python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$BUILD_DIR" </dev/null >"$LOG_FILE" 2>&1 &
  pid="$!"
  disown "$pid" 2>/dev/null || true
  echo "$pid" >"$PID_FILE"

  pid="$(cat "$PID_FILE")"
  for _ in $(seq 1 20); do
    if curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
      echo "Web preview ready: http://127.0.0.1:${PORT}/"
      echo "PID: $pid"
      echo "Log: $LOG_FILE"
      return 0
    fi
    sleep 0.2
  done

  echo "Preview server did not become ready in time." >&2
  exit 1
}

case "$action" in
  start)
    stop_project_preview
    start_preview
    ;;
  stop)
    stop_project_preview
    echo "Web preview stopped on port $PORT."
    ;;
  restart)
    stop_project_preview
    start_preview
    ;;
  *)
    echo "Usage: bash tools/preview_web.sh [start|stop|restart]" >&2
    exit 1
    ;;
esac
