# ~/.zsh_mytools/.zsh_newcpp/newcpp.zsh
newcpp() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local script="$HOME/.zsh_mytools/.zsh_newcpp/newcpp.py"
  if [[ ! -f "$script" ]]; then
    print -u2 "newcpp: script not found: $script"
    return 127
  fi

  command python3 "$script" "$@"
}
