#!/bin/sh
set -eu

worktree_name="$1"

session_id="$(tmux display-message -p '#{session_id}')"
socket="$(tmux show-options -qv -t "$session_id" @nvim_socket || true)"

[ -n "$socket" ] || exit 0
[ -S "$socket" ] || exit 0

nvim --server "$socket" --remote-expr \
  "luaeval('require(\"git-worktree\").switch_worktree(_A)', '$worktree_name')" \
  >/dev/null
