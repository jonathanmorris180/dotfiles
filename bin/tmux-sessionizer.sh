#!/usr/bin/env bash

dirs=("$HOME/Documents/vs-code" "$HOME/Documents/intellij" "$HOME/Documents/big_repos" "$HOME")

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(printf "%s\n" "${dirs[@]}" | xargs -I {} find {} -mindepth 1 -maxdepth 1 -type d 2> /dev/null | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
