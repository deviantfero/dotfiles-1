# ensure_options_file: ensure options_file exists {{{

ensure_options_file() {
  if [[ ! -d ~/.options ]]; then
    mkdir ~/.options
  fi

  local options_file="$(readlink -f ~/.options/shell-options.conf)"

  if [[ ! -e $options_file ]]; then
    cp misc/options/shell-options.conf ~/.options
  fi
}

# }}}
# ensure_dotpath: ensure $DOTPATH is set on $options_file {{{

ensure_dotpath() {
  ensure_options_file

  local options_file="$(readlink -f ~/.options/shell-options.conf)"
  local temp_file="$(readlink -f ~/.options/temp.conf)"

  # remove DOTPATH, if it exists
  awk '!/^DOTPATH/' $options_file > $temp_file && mv $temp_file $options_file

  # append $DOTPATH to $options_file
  echo "DOTPATH=${GIT_ROOT/$HOME/~}" >> $options_file
}

# }}}
# verifylink: ensure no regular user file will be overwritten {{{

verifylink() {
  local symlink=${1:a}

  if [[ -e $symlink ]] && [[ ! -h $symlink ]]; then
    echo -e "${Yellow}$symlink${Rst} is a ${Red}regular${Rst} file on your system."
    echo -e "rename/backup the file ${Yellow}$symlink${Rst}, and run the script again."
    exit 1
  fi
}

# }}}
# updatelinks: help with symlinkage {{{

updatelinks() {
  local symlink=${1:a}
  local symlink_old_target=${1:A}
  local symlink_new_target=${2:A}

  if [[ ! -h $symlink ]]; then
    echo -e "$symlink ${Green}->${Rst} $symlink_new_target"
  elif [[ $symlink_old_target != $symlink_new_target ]]; then
    rm $symlink
    echo -e "$1 ${Red}-${Black}X${Rst}->${Rst} $symlink ${Green}->${Rst} $symlink_new_target"
  else
    echo -e "$1 ${Green}ok.${Rst}"
    return 0
  fi

  ln -s $symlink_new_target $symlink
}

# }}}
# ensure_vim_plugins: ensure vim plugins are installed {{{

ensure_vim_plugins() {
  local plug_dir=$(readlink -m ~/.vim/plugged)
  if [[ ! -d $plug_dir ]]; then
    echo -e "installing ${Yellow}vim${Rst} plugins..."
    vim +PlugInstall +qall
  fi
}

# }}}
# apply_git_info: apply git information  {{{

# if available through environment variables
apply_git_info() {
  if [[ -n ${GIT_USER_NAME+x} ]]; then
    git config --global user.name "$GIT_USER_NAME"
  fi
  if [[ -n ${GIT_USER_EMAIL+x} ]]; then
    git config --global user.email "$GIT_USER_EMAIL"
  fi
}

# }}}
# clonedep: smarter clones {{{

clonedep() {
  local name="$1"
  local url="$2"
  local ref="$3"
  echo ""
  echo -e "-------------------"
  if [[ ! -d $name ]]; then
    echo -e "[${Red}${name}${Rst}] not cloned. cloning now."
    if [[ -n ${3+x} ]]; then
      local clone_depth=${4:-400}
      if [[ -n ${4+x} ]]; then
        echo -e "a clone depth ${Blue}${4}${Rst} was passed. cloning deeper"
        git clone --depth $clone_depth $url $name
      else
        echo -e "No depth arg passed. Performing ${Blue}full${Rst} clone."
        git clone $url $name
      fi
      local cwd=$(readlink -f .)
      cd $name
      git checkout --quiet $ref
      git branch --no-color --quiet --column=dense
      cd $cwd
    else
      echo -e "no ref to checkout. ${Yellow}shallow${Rst} cloning."
      git clone --depth 1 $url $name
    fi
    echo -e "[${Green}${name}${Rst}] sucessfully cloned."
  else
    echo -e "[${Green}${name}${Rst}] already cloned."
  fi
  echo -e "-------------------"
}

# }}}
