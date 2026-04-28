# ~/.zsh_load/envs/conda.zsh
# usage:
#   load conda            -> activate base (default)
#   load conda <envname>  -> activate env
#   load conda off        -> conda deactivate
#   load conda enable     -> only enable conda command (no activate)

_load_conda() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local conda_root="/opt/miniconda3"
  local conda_sh="$conda_root/etc/profile.d/conda.sh"

  if [[ ! -r "$conda_sh" ]]; then
    print -u2 "load conda: conda.sh not found at $conda_sh"
    return 1
  fi

  # 强制 env/缓存到 home（覆盖系统只读前缀）
  export CONDA_ENVS_PATH="$HOME/.conda/envs"
  export CONDA_PKGS_DIRS="$HOME/.conda/pkgs"

  # init conda into current shell
  source "$conda_sh"

  local sub="$1"

  # default: base
  if [[ -z "$sub" ]]; then
    conda activate base
    return 0
  fi

  case "$sub" in
    enable)
      return 0
      ;;
    off|deactivate)
      conda deactivate
      ;;
    *)
      conda activate "$sub"
      ;;
  esac
}
