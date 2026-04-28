# ===== Wi-Fi hotspot helper =====
source ~/.zsh_mytools/.zsh_hotspot/hotspot.env.zsh

_hotspot_wifi_ifaces() {
  emulate -L zsh
  nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1}'
}

_hotspot_usage() {
  emulate -L zsh
  cat <<EOF
用法:
  hotspot [-i IFACE|--iface IFACE] on [SSID] [PASSWORD]
  hotspot [-i IFACE|--iface IFACE] off
  hotspot [-i IFACE|--iface IFACE] status
  hotspot [-i IFACE|--iface IFACE] resume

说明:
  -i, --iface   指定热点网卡；默认使用 \$HOTSPOT_IFACE（当前默认: ${HOTSPOT_IFACE:-wlan1}）

示例:
  hotspot on
  hotspot on vehkko 12345687
  hotspot -i wlan1 on vehkko 12345687
  hotspot --iface wlan1 off
  hotspot status
  hotspot resume
EOF
}

hotspot() {
  emulate -L zsh

  local default_iface="${HOTSPOT_IFACE:-wlan1}"
  local con="${HOTSPOT_CON:-campus-hotspot}"
  local upstream="${HOTSPOT_UPSTREAM:-eduroam}"
  local upstream_iface="${HOTSPOT_UPSTREAM_IFACE:-wlan0}"

  local iface="$default_iface"
  local cmd=""
  local ssid=""
  local pass=""

  local -a wifi_ifaces
  wifi_ifaces=("${(@f)$(_hotspot_wifi_ifaces)}")

  if ! command -v nmcli >/dev/null 2>&1; then
    echo "未找到 nmcli"
    return 1
  fi

  while (( $# > 0 )); do
    case "$1" in
      -i|--iface)
        if [[ -z "$2" ]]; then
          echo "缺少网卡名: $1"
          return 1
        fi
        iface="$2"
        shift 2
        ;;
      on|start|off|stop|status|resume|help)
        cmd="$1"
        shift
        break
        ;;
      -h|--help)
        _hotspot_usage
        return 0
        ;;
      *)
        echo "未知参数: $1"
        echo
        _hotspot_usage
        return 1
        ;;
    esac
  done

  [[ -z "$cmd" ]] && cmd="status"

  if (( ${wifi_ifaces[(Ie)$iface]} == 0 )); then
    echo "未找到可用的 Wi-Fi 设备: $iface"
    echo "当前可用 Wi-Fi 设备: ${wifi_ifaces[*]:-(无)}"
    return 1
  fi

  case "$cmd" in
    on|start)
      ssid="${1:-${HOTSPOT_SSID:-MyLAN}}"
      pass="${2:-${HOTSPOT_PASS:-12345678}}"

      if (( ${#pass} < 8 )); then
        echo "密码至少 8 位"
        return 1
      fi

      if ! nmcli -t -f NAME connection show | grep -Fxq "$con"; then
        echo "创建热点配置: $con"
        nmcli connection add type wifi ifname "$iface" con-name "$con" autoconnect no ssid "$ssid" || return 1
      fi

      nmcli connection modify "$con" \
        connection.interface-name "$iface" \
        802-11-wireless.mode ap \
        802-11-wireless.ssid "$ssid" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$pass" \
        ipv4.method shared \
        ipv6.method disabled || return 1

      echo "启动热点: SSID=$ssid IFACE=$iface"
      nmcli connection up "$con" ifname "$iface" || return 1

      echo
      echo "当前设备状态:"
      nmcli device status
      ;;

    off|stop)
      echo "关闭热点: $con (IFACE=$iface)"
      nmcli connection down "$con"
      ;;

    resume)
      echo "关闭热点并重连上游网络: $upstream (IFACE=$upstream_iface)"
      nmcli connection down "$con" >/dev/null 2>&1
      nmcli connection up "$upstream" ifname "$upstream_iface"
      ;;

    status)
      echo "==== nmcli device status ===="
      nmcli device status
      echo
      echo "==== active connections ===="
      nmcli connection show --active
      echo
      echo "==== iw dev ===="
      iw dev
      ;;

    help)
      _hotspot_usage
      ;;
  esac
}

# ===== hotspot tab completion =====
_hotspot() {
  emulate -L zsh
  setopt localoptions noshwordsplit noksh_arrays

  local -a wifi_devs cmd_names cmd_desc
  wifi_devs=("${(@f)$(_hotspot_wifi_ifaces)}")

  cmd_names=(on start off stop status resume help)
  cmd_desc=(
    'on       开启热点'
    'start    开启热点（别名）'
    'off      关闭热点'
    'stop     关闭热点（别名）'
    'status   查看当前状态'
    'resume   关闭热点并重连上游网络'
    'help     显示帮助'
  )

  local cmd_pos=2
  local cmd=""

  # hotspot <TAB>
  if (( CURRENT == 2 )); then
    compadd -Q -- -i --iface
    compadd -Q -d cmd_desc -- "${cmd_names[@]}"
    return 0
  fi

  # hotspot -i <TAB> / hotspot --iface <TAB>
  if [[ "${words[2]}" == "-i" || "${words[2]}" == "--iface" ]]; then
    if (( CURRENT == 3 )); then
      compadd -Q -- "${wifi_devs[@]}"
      return 0
    fi

    # hotspot -i wlan1 <TAB>
    if (( CURRENT == 4 )); then
      compadd -Q -d cmd_desc -- "${cmd_names[@]}"
      return 0
    fi

    cmd_pos=4
  fi

  cmd="${words[$cmd_pos]}"

  case "$cmd" in
    on|start)
      if (( CURRENT == cmd_pos + 1 )); then
        _message 'SSID'
        return 0
      elif (( CURRENT == cmd_pos + 2 )); then
        _message 'PASSWORD'
        return 0
      else
        # 已经补完 password，后面不再给无意义补全
        return 0
      fi
      ;;
    off|stop|status|resume|help)
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}

# 确保 compdef 可用
autoload -Uz compdef
compdef _hotspot hotspot
