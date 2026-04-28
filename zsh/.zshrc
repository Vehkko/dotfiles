# ============================================================
# 0. Powerlevel10k Instant Prompt（必须放在最前面附近）
#    注意：任何可能需要交互输入（密码、y/n确认）的初始化必须放在此块之前。
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# 1. Oh My Zsh 基本配置
# ============================================================

# Oh My Zsh 安装路径
ZSH=/usr/share/oh-my-zsh/

# 主题：Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# 插件列表（保持与你原来一致）
plugins=(
  sudo
  git
  autojump
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# 关闭 compfix 交互提示（避免偶尔出现“是否修复补全权限”的 y/n 提示）
# 若你确定不会出现该提示，可删除此行。
ZSH_DISABLE_COMPFIX=true

# Oh My Zsh 缓存目录（保持原有逻辑）
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR"

# ============================================================
# 2. 补全系统 fpath 扩展（必须在加载 oh-my-zsh.sh 之前）
#    说明：这里只处理“以 _xxx 文件形式存在的补全脚本目录”。
#    你的 archive 补全写在 archive.zsh 内部，不依赖此处。
# ============================================================

# 将 ~/.zsh_mytools/.zsh_*/completions 加入 fpath（存在才加入）
for d in "$HOME/.zsh_mytools"/.zsh_*/completions(/N); do
  fpath+=("$d")
done

# ============================================================
# 3. 加载 Oh My Zsh（此步骤会初始化补全系统 compinit）
# ============================================================
source "$ZSH/oh-my-zsh.sh"

# ============================================================
# 4. Powerlevel10k 个人配置
# ============================================================
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ============================================================
# 5. 自定义小工具/别名（与原来保持一致）
# ============================================================

# neovide 快捷命令（保持原行为：后台启动、不占用终端）
nvide() { neovide "$@" &! }

# 常用别名
alias :q=exit
alias c=clear

# ============================================================
# 6. 你的 ~/.zsh_mytools 工具加载区
#    规则：全部在 oh-my-zsh 之后 source，以确保 compdef 等可用。
# ============================================================

# 6.1 load 工具（你现有的 loader）
[[ -r "$HOME/.zsh_mytools/.zsh_load/load.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_load/load.zsh"

# 6.2 archive 工具（补全写在 archive.zsh 内部，不需要 completions/ 目录）
[[ -r "$HOME/.zsh_mytools/.zsh_archive/archive.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_archive/archive.zsh"

# 6.3 newcpp 工具（入口函数在 newcpp.zsh；补全通常在 completions/_newcpp）
[[ -r "$HOME/.zsh_mytools/.zsh_newcpp/newcpp.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_newcpp/newcpp.zsh"

# 6.4 prx 工具（已迁移到 tools）
[[ -r "$HOME/.zsh_mytools/.zsh_prx/prx.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_prx/prx.zsh"

# 6.5 translate 工具
[[ -r "$HOME/.zsh_mytools/.zsh_trans/trans.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_trans/trans.zsh"

# 6.6 hotspot 工具
[[ -r "$HOME/.zsh_mytools/.zsh_trans/trans.zsh" ]] && source "$HOME/.zsh_mytools/.zsh_hotspot/hotspot.zsh"

# ============================================================
# 7. 代理策略（与原来一致：交互式 shell 自动静默开启）
# ============================================================

# 代理地址：保持你原来默认值
export PRX_PROXY_URL="http://127.0.0.1:7890"
# 如需 socks5，改成：
# export PRX_PROXY_URL="socks5://127.0.0.1:7890"

# 登录/新 shell 自动开启（静默）
[[ -o interactive ]] && prx on >/dev/null 2>&1

# ============================================================
# 8. 语言/工具链环境变量（与原来一致）
# ============================================================

# haskell ghc
export PATH="$HOME/.ghcup/bin:$PATH"

# matlab
matlab() { 
  local base=(env _JAVA_AWT_WM_NONREPARENTING=1 AWT_TOOLKIT=MToolkit QT_QPA_PLATFORM=xcb /home/vehkko/applications/Matlab/R2024a/bin/matlab -sd "/home/vehkko/code/matlab"); (( $# )) && "${base[@]}" "$@" || "${base[@]}" -nodisplay
}

# mathematica
alias wolfram=$HOME/applications/Mathematica/bin/wolfram
alias wolframnb=$HOME/applications/Mathematica/bin/wolframnb

# lsd
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -la'
alias tree='lsd --tree'
