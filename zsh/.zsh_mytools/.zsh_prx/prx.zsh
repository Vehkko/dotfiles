# ~/.zsh_mytools/.zsh_prx/prx.zsh
# ------------------------------------------------------------
# prx: 代理开关工具
#
# 用法：
#   prx on
#   prx off
#   prx status
#
# 配置：
#   通过环境变量 PRX_PROXY_URL 指定代理地址（建议在 ~/.zshrc 设置）
#   例如：
#     export PRX_PROXY_URL="http://127.0.0.1:7890"
# ------------------------------------------------------------

prx() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local cmd="${1:-status}"
  local proxy_url="${PRX_PROXY_URL:-http://127.0.0.1:7890}"

  _prx_say() {
    [[ -o interactive && -t 1 ]] && print -- "$@"
  }

  case "$cmd" in
    on)
      export all_proxy="$proxy_url"
      export http_proxy="$proxy_url"
      export https_proxy="$proxy_url"
      export ALL_PROXY="$all_proxy"
      export HTTP_PROXY="$http_proxy"
      export HTTPS_PROXY="$https_proxy"
      export no_proxy="localhost,127.0.0.1,::1"
      export NO_PROXY="$no_proxy"
      _prx_say "proxy: ON -> $proxy_url"
      ;;
    off)
      unset all_proxy http_proxy https_proxy no_proxy
      unset ALL_PROXY HTTP_PROXY HTTPS_PROXY NO_PROXY
      _prx_say "proxy: OFF"
      ;;
    status|st)
      if [[ -n "${all_proxy:-}" || -n "${http_proxy:-}" || -n "${https_proxy:-}" ]]; then
        print "proxy: ON"
        print "  all_proxy=$all_proxy"
        print "  http_proxy=$http_proxy"
        print "  https_proxy=$https_proxy"
        [[ -n "${no_proxy:-}" ]] && print "  no_proxy=$no_proxy"
      else
        print "proxy: OFF"
      fi
      ;;
    *)
      print -u2 "usage: prx on|off|status"
      return 1
      ;;
  esac
}
