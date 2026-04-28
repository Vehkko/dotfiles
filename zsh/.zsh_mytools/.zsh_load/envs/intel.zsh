# ~/.zsh_load/envs/intel.zsh

_load_intel() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local oneapi_root="/opt/intel/oneapi"
  local arch="intel64"

  # helper: prefer latest vars.sh
  _intel_vars() {
    local comp="$1"
    local f="$oneapi_root/$comp/latest/env/vars.sh"
    [[ -r "$f" ]] && { print -r -- "$f"; return 0; }
    return 1
  }

  if [[ ! -d "$oneapi_root" ]]; then
    print -u2 "load intel: $oneapi_root not found"
    return 1
  fi

  local compiler_vars="$(_intel_vars compiler)" || {
    print -u2 "load intel: compiler vars.sh not found under $oneapi_root/compiler/latest/"
    return 1
  }

  local mkl_vars="$(_intel_vars mkl)" || {
    print -u2 "load intel: mkl vars.sh not found under $oneapi_root/mkl/latest/"
    return 1
  }

  # default: all
  local comps=("$@")
  (( ${#comps} == 0 )) && comps=(all)

  for c in "${comps[@]}"; do
    case "$c" in
      compiler|icx|icpx)
        source "$compiler_vars" "$arch"
        ;;

      openmp)
        # OpenMP runtime comes with compiler env
        source "$compiler_vars" "$arch"
        ;;

      mkl)
        # MKL 推荐同时加载 compiler
        source "$compiler_vars" "$arch"
        source "$mkl_vars" "$arch"
        ;;

      all)
        source "$compiler_vars" "$arch"
        source "$mkl_vars" "$arch"
        # openmp already included
        ;;

      *)
        print -u2 "load intel: unknown component '$c' (compiler|mkl|openmp|all)"
        return 1
        ;;
    esac
  done
}
