cd "$(dirname "$0")"
DOTFILES=$(pwd -P)

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

prompt () {
  printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit
}

link_file () {
  local src=$1 dest=$2

  local overwrite backup skip action

  if [ -f "$dest" ] || [ -d "$dest" ] || [ -L "$dest" ] # check for existence of destination file, dir, or symlink
  then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then

      # ignoring exit 1 from readlink in case where file already exists
      # shellcheck disable=SC2155
      local currentSrc="$(readlink "$dest")" # check if there is already a symlink 

      if [ "$currentSrc" == "$src" ]
      then

        skip=true;

      else

        prompt "File already exists: $dest ($(basename "$src")). What do you want to do?
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -rn 1 action  < /dev/tty

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;; # true for subsequent iterations of this function because of global scope
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]; then
      rm -rf "$dest"
      success "Removed $dest"
    fi

    if [ "$backup" == "true" ]; then
      mv "$dest" "${dest}.backup"
      success "Moved $dest to ${dest}.backup"
    fi

    if [ "$skip" == "true" ]; then
      success "Skipped $src"
    fi
  fi

  if [ "$skip" != "true" ] # "false" or empty
  then
    ln -s "$1" "$2"
    success "Linked $1 to $2"
  fi
}


prop () {
   prop_key=$1
   prop_file=$2
   prop_value=$(grep "$prop_key" < "$prop_file" | cut -d '=' -f 2)
   echo "$prop_value"
}

install_dotfiles () {
  info 'Installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  find -H "$DOTFILES" -maxdepth 2 -name 'links.prop' -not -path '*.git*' | while read -r linkfile
  do
    while read -r line
    do
        local src dest dir
        src=$(eval echo "$line" | cut -d '=' -f 1) # eval to populate the variables
        dest=$(eval echo "$line" | cut -d '=' -f 2)
        dir=$(dirname "$dest")

        mkdir -p "$dir"
        link_file "$src" "$dest"
    done < "$linkfile"
  done
}

create_env_file () {
    if test -f "$HOME/.env.sh"; then
        success "$HOME/.env.sh file already exists, skipping"
    else
        echo "export DOTFILES=$DOTFILES" > "$HOME"/.env.sh
        success 'created ~/.env.sh'
    fi
}

install_dotfiles
create_env_file

echo ''
echo ''
success 'Install successful!'
