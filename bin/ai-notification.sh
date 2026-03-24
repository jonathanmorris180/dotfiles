#!/bin/bash
set -euo pipefail

DEBUG=false # logs to ~/.local/share/nvim/tmux/debug.log when enabled
DATA_DIR="${HOME}/.local/share/nvim/tmux"
LOCK_FILE="${DATA_DIR}/prompt.lock"
PENDING_FILE="${DATA_DIR}/pending-sessions.txt"
LOG_FILE="${DATA_DIR}/debug.log"

log() {
  $DEBUG || return 0
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" # $* = all positional args
}

is_terminal_focused() {
  local frontmost
  frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null) || return 1
  [[ "$frontmost" == "wezterm-gui" ]]
}

# ---------- Mode 2: Popup UI (self-invoked inside tmux display-popup -E - see below) ----
if [ "${1:-}" = "--popup" ]; then
  shift # Move args to the left
  SESSION="$1" WINDOW="$2" WINDOW_NAME="$3" ACTIVE_CLIENT="$4"

  log "popup: SESSION=$SESSION WINDOW=$WINDOW WINDOW_NAME=$WINDOW_NAME ACTIVE_CLIENT=$ACTIVE_CLIENT"

  CHOICE=$(printf 'Yes\nNo' | fzf --prompt="AI agent needs attention. Return to ${SESSION}:${WINDOW}? " --no-info --reverse) || true
  log "popup: user chose '${CHOICE:-}'"

  if [ "${CHOICE:-}" = "Yes" ]; then
    log "popup: running tmux switch-client -c '$ACTIVE_CLIENT' -t '${SESSION}:${WINDOW}'"
    tmux switch-client -c "$ACTIVE_CLIENT" -t "${SESSION}:${WINDOW}" 2>&1 | while read -r line; do log "popup: switch-client output: $line"; done
    log "popup: switch-client exit code: ${PIPESTATUS[0]}"
  elif [ "${CHOICE:-}" = "No" ]; then
    log "popup: writing to pending file"
    printf '%s:%s (%s)\n' "$SESSION" "$WINDOW" "$WINDOW_NAME" >> "$PENDING_FILE"
  fi
  exit 0
fi

# ---------- Mode 1: Hook mode (default — called by AI) -------------

# Consume stdin (hook event JSON) so the pipe doesn't break
cat > /dev/null

# Must be inside tmux
if [ -z "${TMUX:-}" ] || [ -z "${TMUX_PANE:-}" ]; then
  log "hook: not in tmux (TMUX=${TMUX:-unset} TMUX_PANE=${TMUX_PANE:-unset}), exiting"
  exit 0
fi

mkdir -p "$DATA_DIR"

# Resolve tmux location of the AI session using -t $TMUX_PANE 
#
# The hook subprocess inherits $TMUX_PANE from the environment that Claude is running in (since Claude invokes the hook)
AI_SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}')
AI_WINDOW=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}')
AI_WINDOW_NAME=$(tmux display-message -t "$TMUX_PANE" -p '#{window_name}')
log "hook: AI_SESSION=$AI_SESSION AI_WINDOW=$AI_WINDOW AI_WINDOW_NAME=$AI_WINDOW_NAME"
log "hook: TMUX=$TMUX TMUX_PANE=$TMUX_PANE"

# Find the most recently active tmux client
ALL_CLIENTS=$(tmux list-clients -F '#{client_activity} #{client_name}' 2>&1) || true
log "hook: all clients: $(echo "$ALL_CLIENTS" | tr '\n' ' ')" # Prints the timestamp and the name for each client
ACTIVE_CLIENT=$(echo "$ALL_CLIENTS" | sort -rn | head -1 | awk '{print $2}') || true # Gets the active client ID based on the most recent timestamp
log "hook: ACTIVE_CLIENT=$ACTIVE_CLIENT"
if [ -z "${ACTIVE_CLIENT:-}" ]; then
  log "hook: no active client, exiting"
  exit 0
fi

# ---------- Lock check: is a popup already open? ----------------------------
is_popup_active() {
  [ -f "$LOCK_FILE" ] || return 1
  local pid
  pid=$(cat "$LOCK_FILE" 2>/dev/null) || return 1
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null # signal 0 is special: it doesn't actually send a signal, it just checks whether the process exists
  # Returns 0 (success) if the process is alive, non-zero if it's dead or doesn't exist
}

if is_popup_active; then
  log "hook: popup active (pid=$(cat "$LOCK_FILE")), writing to pending file"
  # Popup already showing — append to pending file and send macOS notification
  printf '%s:%s (%s)\n' \
    "$AI_SESSION" "$AI_WINDOW" "$AI_WINDOW_NAME" \
    >> "$PENDING_FILE"
  osascript -e 'display alert "AI Agent" message "Session written to pending list"' 2>/dev/null || true
  exit 0
fi

# ---------- Show popup in background ----------------------------------------
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")" # Get path to call this script (self-invoked with --popup)
POPUP_CMD="$SCRIPT_PATH --popup '$AI_SESSION' '$AI_WINDOW' '$AI_WINDOW_NAME' '$ACTIVE_CLIENT'"
log "hook: launching popup: tmux display-popup -c '$ACTIVE_CLIENT' -w 60 -h 10 -E $POPUP_CMD"

(
  trap 'rm -f "$LOCK_FILE"' EXIT # Deletes the lock file if this subshell exits for any reason
  tmux display-popup -c "$ACTIVE_CLIENT" -w 60 -h 10 -E "$POPUP_CMD" || true
) & # Run in background

echo $! > "$LOCK_FILE" # Writes the lock file to be deleted when the subprocess above exits
log "hook: background pid=$!, lock written"

if ! is_terminal_focused; then
  log "hook: terminal not focused, sending macOS alert"
  osascript -e "display alert \"AI Agent\" message \"${AI_SESSION}:${AI_WINDOW} needs attention\"" 2>/dev/null || true
fi

exit 0
