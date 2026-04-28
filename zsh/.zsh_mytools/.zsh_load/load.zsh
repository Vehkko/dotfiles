# ~/.zsh_load/load.zsh
# main dispatcher: load <env> [components...]

load() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local env="$1"; shift || true
  local root="$HOME/.zsh_mytools/.zsh_load/envs"

  if [[ -z "$env" ]]; then
    print -u2 "usage: load <env> [components...]"
    return 1
  fi

  local env_file="$root/${env}.zsh"
  if [[ ! -r "$env_file" ]]; then
    print -u2 "load: unknown env '$env' (no $env_file)"
    return 1
  fi

  # call env-specific loader: _load_<env>
  source "$env_file"
  local fn="_load_${env}"

  if ! (( $+functions[$fn] )); then
    print -u2 "load: '$env_file' does not define $fn"
    return 1
  fi

  "$fn" "$@"
}
