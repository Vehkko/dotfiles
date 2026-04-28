# ~/.zsh_mytools/.zsh_trans/trans.zsh
# ------------------------------------------------------------
# trzh / tren: translate-shell 智能包装
# ------------------------------------------------------------

_trans_brief() {
  local target="$1"
  shift

  trans -b ":${target}" \
    -show-original n \
    -show-original-phonetics n \
    -show-translation y \
    -show-translation-phonetics n \
    -show-languages n \
    -show-original-dictionary n \
    -show-dictionary n \
    -show-alternatives n \
    -no-ansi \
    "$*"
}

_trans_full() {
  local target="$1"
  shift

  trans ":${target}" "$@"
}

_trans_is_sentence_like() {
  local s="$1"

  # 含空白：短语/句子
  [[ "$s" == *[[:space:]]* ]] && return 0

  # 单个参数但以常见句末/停顿标点结尾，也判为句子
  case "$s" in
    *'.'|*'!'|*'?'|*','|*';'|*':'|*'。'|*'！'|*'？'|*'，'|*'；'|*'：'|*')'|*']'|*'}'|*'"'|*"'"|*'”'|*'’')
      return 0
      ;;
  esac

  return 1
}

_trans_smart() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local target="$1"
  shift

  local mode="auto"

  case "$1" in
    -w|--word)
      mode="word"
      shift
      ;;
    -s|--sentence)
      mode="sentence"
      shift
      ;;
  esac

  if (( $# == 0 )); then
    print -u2 "usage:"
    print -u2 "  trzh [-w|-s] <text>"
    print -u2 "  tren [-w|-s] <text>"
    return 1
  fi

  if [[ "$mode" == "word" ]]; then
    _trans_full "$target" "$@"
    return
  fi

  if [[ "$mode" == "sentence" ]]; then
    _trans_brief "$target" "$*"
    return
  fi

  if (( $# > 1 )); then
    _trans_brief "$target" "$*"
    return
  fi

  if _trans_is_sentence_like "$1"; then
    _trans_brief "$target" "$1"
  else
    _trans_full "$target" "$1"
  fi
}

trzh() {
  _trans_smart zh "$@"
}

tren() {
  _trans_smart en "$@"
}
