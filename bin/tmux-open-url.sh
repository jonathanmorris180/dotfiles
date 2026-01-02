#!/usr/bin/env bash
set -euo pipefail

tmux capture-pane -J -p \
| perl -nE '
  while (m{
    https?://
    (?:www\.)?
    [-\w@:%.+~#=]{1,256}
    \.[A-Za-z0-9()]{1,6}
    \b
    [-A-Za-z0-9()@:%_+.~#?&/=]*
  }gx) {
    say $&
  }
' \
| sort -u \
| fzf --multi \
       --bind alt-a:select-all,alt-d:deselect-all \
| xargs -n1 open

