# ~/.zsh_mytools/.zsh_archive/archive.zsh
# Unified archive tool for zsh: archive extract|compress|list|help
# Dependencies (recommended):
#   libarchive (bsdtar), zstd, xz, gzip, bzip2, unzip, zip, p7zip
# Arch install:
#   sudo pacman -S --needed libarchive zstd xz gzip bzip2 unzip zip p7zip

archive() {
  emulate -L zsh
  # NOTE:
  # Do NOT use `errexit` here: external tools (bsdtar/unzip/7z/...) may fail and
  # in interactive shells this can sometimes terminate the whole shell session.
  # We handle errors explicitly via `_die` / `|| return 1`.
  setopt nounset pipefail

  local sub="${1:-help}"
  (( $# > 0 )) && shift

  local -r prog="archive"

  _die() { print -u2 -- "${prog}: $*"; return 1; }
  _have() { command -v "$1" >/dev/null 2>&1; }

  _usage() {
    cat <<'EOF'
archive — unified archiver (zsh)

Usage:
  archive extract  <archive> [dest_dir]
  archive compress <output>  <input...>
  archive list     <archive>
  archive help

Examples:
  archive extract  a.tar.zst
  archive extract  a.zip /tmp/out
  archive compress site.tar.zst dist/
  archive compress pack.zip dir1 file2
  archive list     a.7z

Notes:
  - If dest_dir is omitted for extract:
      * archives (zip/tar/7z/...) -> extract into ./<archive_basename>/
      * single-file compression (.zst/.gz/.xz/.bz2 but not tar.*) -> extract to current dir
EOF
  }

  # ---------- helpers ----------
  _is_single_file_comp() {
    local f="$1"
    [[ "$f" == *.gz  && "$f" != *.tar.gz  ]] && return 0
    [[ "$f" == *.xz  && "$f" != *.tar.xz  ]] && return 0
    [[ "$f" == *.bz2 && "$f" != *.tar.bz2 && "$f" != *.tbz2 ]] && return 0
    [[ "$f" == *.zst && "$f" != *.tar.zst && "$f" != *.tzst ]] && return 0
    return 1
  }

  _strip_archive_ext() {
    # Strip multi-extensions nicely: .tar.gz/.tar.xz/.tar.zst/.tgz/.tbz2/.txz/.tzst/.zip/.7z/.rar/.tar
    local base="${1:t}"
    base="${base%.tar.gz}"
    base="${base%.tar.xz}"
    base="${base%.tar.bz2}"
    base="${base%.tar.zst}"
    base="${base%.tgz}"
    base="${base%.tbz2}"
    base="${base%.txz}"
    base="${base%.tzst}"
    base="${base%.zip}"
    base="${base%.7z}"
    base="${base%.rar}"
    base="${base%.tar}"
    # single-file compression
    base="${base%.gz}"
    base="${base%.xz}"
    base="${base%.bz2}"
    base="${base%.zst}"
    print -r -- "$base"
  }

  _trim_ws() {
    # trim leading/trailing whitespace
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    print -r -- "$s"
  }

  _auto_suffix_dir() {
    # Given a base path, return base_1/base_2/... that does not exist
    local base="$1"
    local i=1
    local cand
    while :; do
      cand="${base}_${i}"
      [[ -e "$cand" ]] || { print -r -- "$cand"; return 0; }
      (( i++ ))
    done
  }

  _resolve_dest_dir_conflict() {
    # Ensure dest dir does not exist.
    # If it exists, prompt repeatedly for rename.
    # Empty input => auto suffix _1/_2...
    local dest="$1"
    local base="$dest"
    local reply trimmed

    while [[ -e "$dest" ]]; do
      print -u2 -- "${prog}: destination exists: $dest"
      print -u2 -- "${prog}: enter a new directory name (empty = auto suffix like _1): "
      # Read from tty to avoid issues with piped stdin
      if ! IFS= read -r reply </dev/tty; then
        _die "failed to read rename input"
      fi
      trimmed="$(_trim_ws "$reply")"

      if [[ -z "$trimmed" ]]; then
        dest="$(_auto_suffix_dir "$base")"
        # If even that collides (shouldn't), loop will continue
      else
        dest="$trimmed"
        # Update base too? No: base stays original so empty input always suffixes original base.
      fi
    done

    print -r -- "$dest"
  }

  _extract_single_file() {
    local a="$1"
    local dest="${2:-}"
    local out

    if [[ -z "$dest" ]]; then
      out="$(_strip_archive_ext "$a")"
    else
      if [[ -d "$dest" ]]; then
        out="$dest/${a:t}"
        out="$(_strip_archive_ext "$out")"
      else
        out="$dest"
      fi
    fi

    case "$a" in
      (*.gz)  _have gzip  || _die "need gzip";  gzip  -dc -- "$a" > "$out" || return 1 ;;
      (*.xz)  _have xz    || _die "need xz";    xz    -dc -- "$a" > "$out" || return 1 ;;
      (*.bz2) _have bzip2 || _die "need bzip2"; bzip2 -dc -- "$a" > "$out" || return 1 ;;
      (*.zst) _have zstd  || _die "need zstd";  zstd  -dqdc -- "$a" > "$out" || return 1 ;;
      (*) _die "unknown compression: $a" ;;
    esac
    print -- "-> $out"
  }

  _extract_archive() {
    local a="$1"
    local dest="${2:-}"

    [[ -f "$a" ]] || _die "not found: $a"

    if _is_single_file_comp "$a"; then
      _extract_single_file "$a" "${dest:-}"
      return $?
    fi

    # default dest: ./<basename>/
    if [[ -z "$dest" ]]; then
      dest="./$(_strip_archive_ext "$a")"
    fi

    # If destination exists, interactively resolve conflict
    dest="$(_resolve_dest_dir_conflict "$dest")" || return 1

    mkdir -p -- "$dest" || return 1

    if _have bsdtar; then
      bsdtar -xf "$a" -C "$dest" || return 1
      print -- "-> $dest/"
      return 0
    fi

    case "$a" in
      (*.zip) _have unzip || _die "need unzip"; unzip -q "$a" -d "$dest" || return 1 ;;
      (*.7z)  _have 7z    || _die "need p7zip (7z)"; 7z x -y "-o$dest" "$a" >/dev/null || return 1 ;;
      (*.rar) _have unrar || _die "need unrar"; unrar x -o+ "$a" "$dest/" >/dev/null || return 1 ;;
      (*)     _have tar   || _die "need tar"; tar -xf "$a" -C "$dest" || return 1 ;;
    esac
    print -- "-> $dest/"
  }

  _list_archive() {
    local a="$1"
    [[ -f "$a" ]] || _die "not found: $a"

    # 单文件压缩：用对应工具展示信息（不是 bsdtar -t）
    if _is_single_file_comp "$a"; then
      case "$a" in
        (*.zst) _have zstd  || _die "need zstd";  zstd -l -- "$a" || return 1 ;;
        (*.gz)  _have gzip  || _die "need gzip";  gzip -l -- "$a" || return 1 ;;
        (*.xz)  _have xz    || _die "need xz";    xz -l -- "$a" || return 1 ;;
        (*.bz2) _have bzip2 || _die "need bzip2"; bzip2 -tv -- "$a" || return 1 ;;
        (*) _die "unknown compression: $a" ;;
      esac
      return 0
    fi

    # 归档：tar/zip/7z/...
    if _have bsdtar; then
      bsdtar -tf "$a" || return 1
      return 0
    fi

    case "$a" in
      (*.zip) _have unzip || _die "need unzip"; unzip -l "$a" || return 1 ;;
      (*.7z)  _have 7z    || _die "need p7zip (7z)"; 7z l "$a" || return 1 ;;
      (*)     _have tar   || _die "need tar"; tar -tf "$a" || return 1 ;;
    esac
  }

  _compress_single_file() {
    local out="$1"
    local in="$2"
    [[ -f "$in" ]] || _die "input must be a file for single-file compression: $in"

    case "$out" in
      (*.gz)  _have gzip  || _die "need gzip";  gzip  -c -- "$in" > "$out" || return 1 ;;
      (*.xz)  _have xz    || _die "need xz";    xz    -c -- "$in" > "$out" || return 1 ;;
      (*.bz2) _have bzip2 || _die "need bzip2"; bzip2 -c -- "$in" > "$out" || return 1 ;;
      (*.zst) _have zstd  || _die "need zstd";  zstd  -q -c -- "$in" > "$out" || return 1 ;;
      (*) _die "unknown compression: $out" ;;
    esac
    print -- "-> $out"
  }

  _compress() {
    local out="$1"; shift
    [[ $# -ge 1 ]] || _die "need input(s)"

    # output must be a file path, not a directory
    if [[ "$out" == */ || -d "$out" ]]; then
      _die "output must be a file, got directory: $out"
    fi

    # single-file compression if output is .zst/.gz/.xz/.bz2 (but not tar.*) and only one file input
    if _is_single_file_comp "$out" && [[ $# -eq 1 ]] && [[ -f "$1" ]]; then
      _compress_single_file "$out" "$1"
      return $?
    fi

    # creating .7z: prefer 7z
    if [[ "$out" == *.7z ]]; then
      _have 7z || _die "need p7zip (7z)"
      7z a -y "$out" "$@" >/dev/null || return 1
      print -- "-> $out"
      return 0
    fi

    # prefer bsdtar for most archive creation (auto by extension)
    if _have bsdtar; then
      bsdtar -a -cf "$out" "$@" || return 1
      print -- "-> $out"
      return 0
    fi

    # fallbacks
    case "$out" in
      (*.zip)
        _have zip || _die "need zip"
        zip -qr "$out" "$@" || return 1
        ;;
      (*.tar)
        _have tar || _die "need tar"
        tar -cf "$out" "$@" || return 1
        ;;
      (*.tar.*|*.tgz|*.tbz2|*.txz|*.tzst)
        _die "no bsdtar: cannot reliably create compressed tar by filename ($out); install libarchive for bsdtar"
        ;;
      (*)
        _die "no tool to create: $out (install libarchive for bsdtar)"
        ;;
    esac
    print -- "-> $out"
  }

  case "$sub" in
    (extract)
      [[ $# -ge 1 ]] || { _usage; return 1; }
      _extract_archive "$1" "${2:-}"
      ;;
    (compress)
      [[ $# -ge 2 ]] || { _usage; return 1; }
      local out="$1"; shift
      _compress "$out" "$@"
      ;;
    (list)
      [[ $# -ge 1 ]] || { _usage; return 1; }
      _list_archive "$1"
      ;;
    (help|--help)
      _usage
      ;;
    (*)
      _die "unknown subcommand: $sub (use: archive help)"
      ;;
  esac
}

# ----------------------------
# zsh completion (Tab hints)
# ----------------------------
_archive() {
  local -a subcmds
  subcmds=(
    'extract:解压（默认解到同名目录；重名会提示/自动加后缀）'
    'compress:压缩（根据输出后缀自动选择格式）'
    'list:列出压缩包内容'
    'help:显示帮助'
  )

  local state
  _arguments -C \
    '1:subcommand:->subcmd' \
    '2:archive file:->archive' \
    '3:dest dir:->dest' \
    '*:files:->files' && return 0

  case "$state" in
    (subcmd)
      _describe -t subcmds 'archive subcommand' subcmds
      ;;
    (archive)
      # 常见压缩格式提示
      _files -g '*.(tar|tgz|tbz2|txz|tzst|zip|7z|rar|gz|xz|bz2|zst|tar.gz|tar.xz|tar.bz2|tar.zst)'
      ;;
    (dest)
      _directories
      ;;
    (files)
      # compress 的输入：文件/目录都允许
      _files
      ;;
  esac
}

compdef _archive archive
