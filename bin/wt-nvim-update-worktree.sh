#!/bin/bash
set -euo pipefail

# printf 'Updating worktree...\n' >&2

worktree_path="${1:?missing worktree path}" # Use $1, but fail immediately with this message if it is unset or empty.
worktree_display="${worktree_path##*/}"  # basename without calling external `basename` (more lightweight)

session_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
# printf 'session_id: %s\n' "$session_id" >&2
[ -n "$session_id" ] || exit 0

vim_single_quote() {
  printf "%s" "$1" | sed "s/'/''/g"
}

build_candidates() {
  local sep option_key socket label window_index window_name pane_command
  local seen_windows

  sep="$(printf '\t')"  # Real tab delimiter, but generated at runtime so there is no literal tab character in the source.
  seen_windows=" "

  # for list-panes, -s makes the target a session; without it, tmux treats
  # the target as a window, so you do not see all panes in the session.
  tmux list-panes -s -t "$session_id" -F "#{window_index}${sep}#{b:pane_current_path}${sep}#{pane_current_command}" |
    while IFS="$sep" read -r window_index window_name pane_command; do
      [ "$pane_command" = "nvim" ] || continue  # Only consider panes whose current foreground command is actually nvim.

      case "$seen_windows" in
        *" $window_index "*) continue ;;  # We store one socket per tmux window, so skip duplicate panes from the same window.
      esac
      seen_windows="${seen_windows}${window_index} "

      option_key="@nvim_session_window_${window_index}"
      # -q to suppress errors for unknown options, -v to only show the value
      socket="$(tmux show-options -qv -t "$session_id" "$option_key" || true)"

      [ -n "${socket:-}" ] || continue  # ${socket:-} is safe under `set -u` even if socket is unset; plain "$socket" can error in that mode.
      [ -S "$socket" ] || continue

      if command nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; then
        # if Neovim is listening on this socket, add to the list of candidates
        label="${window_index}:${window_name}"
        printf '%s%s%s\n' "$label" "$sep" "$socket"
      else
        # otherwise, remove the stale option (-u is to unset)
        tmux set-option -q -u -t "$session_id" "$option_key" || true
      fi
    done
}

candidates="$(build_candidates)"
[ -n "$candidates" ] || exit 0

# printf 'candidates raw:\n%s\n' "$candidates" >&2

sep="$(printf '\t')"
candidate_count="$(printf '%s\n' "$candidates" | awk 'NF { count++ } END { print count + 0 }')"

# printf 'candidate_count: %s\n' "$candidate_count" >&2

if [ "$candidate_count" -eq 1 ]; then
  selected="$candidates"  # Skip fzf and auto-select when there is only one matching Neovim window.
else
  selected="$(
  printf '%s\n' "$candidates" |
    fzf \
      --multi \
      --delimiter="$sep" \
      --with-nth=1 \
      --prompt="Update Neovim worktrees (${worktree_display})> " \
      --header='TAB select • ENTER confirm' \
      --bind='tab:toggle+down,btab:toggle+up'
  )"
  [ -n "$selected" ] || exit 0
fi

# printf 'worktree_path: %s\n' "$worktree_path" >&2
quoted_worktree="$(vim_single_quote "$worktree_path")"

# printf 'selected:\n%s\n' "$selected" >&2

# Return "" explicitly so --remote-expr is silent; otherwise luaeval(...) can print vim.NIL
# when switch_worktree returns nil.
expr="luaeval('(function(arg) require(\"git-worktree\").switch_worktree(arg); return \"\" end)(_A)', '$quoted_worktree')"

# printf '%s\n' "${selected[@]}"

while IFS="$sep" read -r label socket; do
  [ -n "${socket:-}" ] || continue  

  if ! command nvim --server "$socket" --remote-expr "$expr" >/dev/null 2>&1; then
    printf 'failed to update %s\n' "$label" >&2
  fi
done <<< "$selected"

# Tell tmux to refresh
tmux refresh-client -S
