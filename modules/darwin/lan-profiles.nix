# modules/darwin/lan-profiles.nix
#
# 有线网卡策略路由 + 多套有线 IP 配置切换（nix-darwin）。
#
# 目标：内网网段（默认 10.0.0.0/8）稳定走有线，其余流量稳定走 Wi-Fi，
#       并且不影响 Clash 的 TUN / 系统代理。
#
# 原理：
#   1. 激活时把 Wi-Fi 排到网络服务顺序最前 → 默认路由稳定走 Wi-Fi。
#   2. 内网网段的静态路由用 `networksetup -setadditionalroutes` 写进有线服务的配置，
#      由 configd 持久保存：拔插网线、重启都会自动恢复；
#      它比 Clash TUN 装的 /1 ~ /8 大段路由前缀更长，所以内网流量不会进 utun。
#   3. profile（每套有线 IP 配置：手动 / DHCP、DNS、附加路由）不写在 nix 里，
#      而是放在仓库之外的 YAML 文件（默认 ~/.config/lan/profiles.yaml），
#      由 `lan` 命令在运行时读取：
#        lan edit        编辑 profile 文件（不存在时先生成带说明的模板）
#        lan list        列出 profile
#        lan status      查看有线网卡当前配置、匹配的 profile 与内核实际路由
#        lan <name>      切换到某个 profile（只改有差异的项）
#        lan dhcp        回到纯 DHCP，并清掉 DNS 与附加路由
#        lan order       把 Wi-Fi 排到最前（激活时自动执行）
#        lan sync        当前 IP 匹配某个 profile 时重新应用它（激活时自动执行）
#   4. Clash 侧的内网域名规则只在网线真正插上时才叠加，拔掉就自动撤掉：
#        lan clash-status  查看期望状态与内核实际状态
#        lan clash-sync    按当前网线状态对齐内核（launchd agent 每 20s 自动执行）
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.lan;

  networkType = lib.types.submodule {
    options = {
      destination = lib.mkOption {
        type = lib.types.str;
        example = "10.0.0.0";
        description = "目标网络地址";
      };
      netmask = lib.mkOption {
        type = lib.types.str;
        example = "255.0.0.0";
        description = "点分十进制子网掩码";
      };
    };
  };

  primaryUser = config.system.primaryUser or null;
  defaultProfilesFile =
    if primaryUser != null then
      "${config.users.users.${primaryUser}.home or "/Users/${primaryUser}"}/.config/lan/profiles.yaml"
    else
      "/etc/lan/profiles.yaml";

  intranetText = lib.concatMapStringsSep ", " (n: "${n.destination}/${n.netmask}") cfg.intranet;

  # `lan edit` 在文件不存在时写入的模板
  profilesTemplate = ''
    # 有线网卡 IP 配置 profile（放在仓库之外）。用 `lan <name>` 切换，`lan list` 查看。
    # 每个顶层键是一个 profile 名（字母、数字、_ . -）。字段：
    #   mode:        manual（默认）或 dhcp
    #   address:     手动 IP，manual 模式必填
    #   netmask:     子网掩码，默认 255.255.255.0
    #   router:      网关。manual 模式必填；dhcp 模式下只用于生成内网静态路由，可省略
    #   dns:         DNS 列表，可省略
    #   service:     覆盖默认有线服务名，可省略
    #   extraRoutes: 额外静态路由列表，每项 {destination, netmask, gateway}，可省略
    # 内网网段指向该 profile 网关的静态路由会自动生成，不用写在 profile 里；
    # 网段默认为 ${intranetText}，可用顶层键 intranet 覆盖（CIDR 或 ip/掩码）：
    #
    # intranet: [10.0.0.0/8, 11.0.0.0/8]
    #
    # office:
    #   address: 10.0.0.2
    #   router: 10.0.0.1
    #   dns: [223.6.6.6]
    #
    # lab:
    #   mode: dhcp
  '';

  lanCli = pkgs.writeShellApplication {
    name = "lan";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
      pkgs.gawk
      pkgs.yq-go
      pkgs.jq
      pkgs.curl
    ];
    text = ''
      NS=/usr/sbin/networksetup
      ROUTE=/sbin/route
      # 有线服务候选，按优先级排列；WIRED 由 resolve_wired 在运行时选定
      WIRED_CANDIDATES=(${lib.concatMapStringsSep " " lib.escapeShellArg (lib.toList cfg.wiredService)})
      # 两块网卡同时插着时可以用 LAN_WIRED 指定用哪个服务
      WIRED=''${LAN_WIRED:-}
      WIFI=${lib.escapeShellArg cfg.wifiService}
      # "dest mask dest mask ..."
      INTRANET=${
        lib.escapeShellArg (lib.concatMapStringsSep " " (n: "${n.destination} ${n.netmask}") cfg.intranet)
      }
      PROFILES_FILE=''${LAN_PROFILES:-${lib.escapeShellArg cfg.profilesFile}}
      RESERVED='help list status order sync dhcp edit intranet clash clash-sync clash-status'

      die() {
        printf 'lan: %s\n' "$*" >&2
        exit 1
      }

      service_exists() { "$NS" -getinfo "$1" >/dev/null 2>&1; }

      # 选用哪个有线服务：先看谁的网卡链路是通的，再看谁的网卡在位，最后退回第一个存在的服务
      resolve_wired() {
        local s dev
        if [ -n "$WIRED" ]; then
          service_exists "$WIRED" || die "LAN_WIRED: network service not found: $WIRED"
          return 0
        fi
        for s in "''${WIRED_CANDIDATES[@]}"; do
          service_exists "$s" || continue
          dev=$(service_device "$s")
          if [ -n "$dev" ] && link_up "$dev"; then
            WIRED=$s
            return 0
          fi
        done
        for s in "''${WIRED_CANDIDATES[@]}"; do
          service_exists "$s" || continue
          dev=$(service_device "$s")
          if [ -n "$dev" ] && ifconfig "$dev" >/dev/null 2>&1; then
            WIRED=$s
            return 0
          fi
        done
        for s in "''${WIRED_CANDIDATES[@]}"; do
          if service_exists "$s"; then
            WIRED=$s
            return 0
          fi
        done
        die "none of the configured wired services exist: ''${WIRED_CANDIDATES[*]}"
      }

      run() {
        printf '+ %s\n' "$*"
        "$@"
      }

      usage() {
        cat <<USAGE
      lan - 有线网卡 IP 配置切换 / 策略路由

      用法:
        lan edit          编辑 profile 文件（不存在时先生成带说明的模板）
        lan list          列出可用 profile
        lan status        查看有线网卡当前配置、匹配的 profile 与内核实际路由
        lan <profile>     切换到指定 profile（只修改有差异的项）
        lan dhcp          回到纯 DHCP，并清空 DNS 与附加路由
        lan order         把 Wi-Fi 排到网络服务顺序最前（激活时自动执行）
        lan sync          当前 IP 匹配某个 profile 时重新应用它（激活时自动执行）
        lan clash-status  查看 Clash 内网域名规则的期望状态与实际状态
        lan clash-sync    按网线状态叠加/撤掉 Clash 内网域名规则（后台每 20s 自动执行）

      profile 文件: $PROFILES_FILE   （可用环境变量 LAN_PROFILES 覆盖）
      有线服务候选: ''${WIRED_CANDIDATES[*]}   （可用环境变量 LAN_WIRED 指定其中一个）
      USAGE
      }

      is_ipv4() { [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }

      is_name() {
        [[ $1 =~ ^[A-Za-z0-9_.-]+$ ]] || return 1
        case " $RESERVED " in
          *" $1 "*) return 1 ;;
        esac
      }

      have_profiles() { [ -r "$PROFILES_FILE" ]; }

      # 10.0.0.0/8 或 10.0.0.0/255.0.0.0 -> "10.0.0.0 255.0.0.0"
      cidr_to_pair() {
        local ip=''${1%/*} len=''${1#*/} m
        is_ipv4 "$ip" || die "bad intranet entry '$1'"
        if is_ipv4 "$len"; then
          printf '%s %s' "$ip" "$len"
          return 0
        fi
        [[ $len =~ ^[0-9]{1,2}$ ]] && [ "$len" -le 32 ] || die "bad intranet entry '$1' (want ip/prefix or ip/mask)"
        if [ "$len" -eq 0 ]; then
          m=0
        else
          m=$((0xffffffff & ~((1 << (32 - len)) - 1)))
        fi
        printf '%s %d.%d.%d.%d' "$ip" $((m >> 24 & 255)) $((m >> 16 & 255)) $((m >> 8 & 255)) $((m & 255))
      }

      # 内网网段 "dest mask dest mask ..."：profiles.yaml 顶层 intranet 优先，否则用 nix 默认
      intranet_pairs() {
        local -a items
        local it pair out=""
        if have_profiles && [ "$(yq -r '.intranet | type' "$PROFILES_FILE")" = '!!seq' ]; then
          mapfile -t items < <(yq -r '.intranet[]' "$PROFILES_FILE")
          for it in "''${items[@]}"; do
            pair=$(cidr_to_pair "$it") || return 1
            out+="$pair "
          done
          printf '%s' "''${out% }"
        else
          printf '%s' "$INTRANET"
        fi
      }

      check_profiles_file() {
        have_profiles || die "profiles file not found: $PROFILES_FILE (run: lan edit)"
        [ "$(yq -r '(. // {}) | type' "$PROFILES_FILE")" = '!!map' ] ||
          die "profiles file must be a YAML mapping of <name>: {...}: $PROFILES_FILE"
      }

      # 取某个 profile 的标量字段；缺省输出空
      pget() { NAME="$1" yq -r ".[strenv(NAME)]$2 // \"\"" "$PROFILES_FILE"; }

      profile_names() {
        have_profiles || return 0
        yq -r '(. // {}) | keys | .[] | select(. != "intranet" and . != "clash")' "$PROFILES_FILE"
      }

      # 把 profile 的参数装进 P_* 变量并校验；未知名字返回 1
      profile_load() {
        local n=$1
        local dns_type routes="" i w pairs
        local -a net words
        check_profiles_file
        is_name "$n" || die "bad profile name '$n' (letters, digits, _ . - and not a subcommand)"
        [ "$(NAME="$n" yq -r '.[strenv(NAME)] | type' "$PROFILES_FILE")" = '!!map' ] || return 1

        P_MODE=$(pget "$n" .mode)
        P_MODE=''${P_MODE:-manual}
        P_SVC=$(pget "$n" .service)
        P_SVC=''${P_SVC:-$WIRED}
        P_IP=$(pget "$n" .address)
        P_MASK=$(pget "$n" .netmask)
        P_MASK=''${P_MASK:-255.255.255.0}
        P_ROUTER=$(pget "$n" .router)

        dns_type=$(NAME="$n" yq -r '.[strenv(NAME)].dns | type' "$PROFILES_FILE")
        case "$dns_type" in
          '!!null') P_DNS="" ;;
          '!!seq') P_DNS=$(NAME="$n" yq -r '.[strenv(NAME)].dns[]' "$PROFILES_FILE" | tr '\n' ' ' | sed 's/ *$//') ;;
          *) die "profile '$n': dns must be a list, e.g. dns: [223.6.6.6]" ;;
        esac

        # 内网网段 -> 该 profile 的网关，再加 extraRoutes
        pairs=$(intranet_pairs) || die "invalid intranet list in $PROFILES_FILE"
        read -ra net <<<"$pairs"
        if [ -n "$P_ROUTER" ]; then
          for ((i = 0; i + 1 < ''${#net[@]}; i += 2)); do
            routes+="''${net[i]} ''${net[i + 1]} $P_ROUTER "
          done
        fi
        routes+=$(NAME="$n" yq -r '.[strenv(NAME)].extraRoutes // [] | .[] | .destination + " " + .netmask + " " + .gateway' "$PROFILES_FILE" | tr '\n' ' ')
        routes=$(tr -s ' ' <<<"$routes")
        P_ROUTES=''${routes% }

        case "$P_MODE" in
          manual | dhcp) ;;
          *) die "profile '$n': mode must be manual or dhcp" ;;
        esac
        if [ "$P_MODE" = manual ]; then
          is_ipv4 "$P_IP" || die "profile '$n': address must be an IPv4 address (manual mode)"
          is_ipv4 "$P_ROUTER" || die "profile '$n': router must be an IPv4 address (manual mode)"
          is_ipv4 "$P_MASK" || die "profile '$n': netmask must be dotted, e.g. 255.255.255.0"
        elif [ -n "$P_ROUTER" ]; then
          is_ipv4 "$P_ROUTER" || die "profile '$n': router must be an IPv4 address"
        fi
        read -ra words <<<"$P_DNS"
        for w in "''${words[@]}"; do
          [[ $w =~ ^[0-9A-Fa-f.:]+$ ]] || die "profile '$n': bad dns entry '$w'"
        done
        read -ra words <<<"$P_ROUTES"
        for w in "''${words[@]}"; do
          is_ipv4 "$w" || die "profile '$n': bad route entry '$w' (extraRoutes need destination, netmask, gateway)"
        done
      }

      getinfo() { "$NS" -getinfo "$1"; }
      cur_mode() { getinfo "$1" | awk 'NR == 1'; }
      cur_field() { getinfo "$1" | awk -F': ' -v k="$2" '!done && $1 == k { print $2; done = 1 }'; }
      cur_dns() {
        "$NS" -getdnsservers "$1" | { grep -E '^[0-9A-Fa-f.:]+$' || true; } | tr '\n' ' ' | sed 's/ *$//'
      }
      cur_routes() {
        "$NS" -getadditionalroutes "$1" | { grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' || true; } | tr '\n' ' ' | sed 's/ *$//'
      }
      require_service() {
        "$NS" -getinfo "$1" >/dev/null 2>&1 || die "network service not found: $1"
      }

      # 当前有线 IP 与哪个 manual profile 一致
      detect_profile() {
        local -a names
        local n
        mapfile -t names < <(profile_names)
        for n in "''${names[@]}"; do
          profile_load "$n" || continue
          [ "$P_MODE" = manual ] || continue
          [ "$(cur_mode "$P_SVC")" = "Manual Configuration" ] || continue
          [ "$(cur_field "$P_SVC" 'IP address')" = "$P_IP" ] || continue
          echo "$n"
          return 0
        done
        return 1
      }

      edit_profiles() {
        if ! [ -e "$PROFILES_FILE" ]; then
          mkdir -p "$(dirname "$PROFILES_FILE")"
          cat >"$PROFILES_FILE" <<'TEMPLATE'
      ${profilesTemplate}
      TEMPLATE
          echo "created template: $PROFILES_FILE"
        fi
        "''${EDITOR:-vi}" "$PROFILES_FILE"
      }

      list_profiles() {
        local -a names
        local n pairs
        check_profiles_file
        pairs=$(intranet_pairs) || die "invalid intranet list in $PROFILES_FILE"
        mapfile -t names < <(profile_names)
        echo "profiles from $PROFILES_FILE  (intranet: $pairs)"
        [ "''${#names[@]}" -gt 0 ] || die "no profiles defined yet (run: lan edit)"
        for n in "''${names[@]}"; do
          profile_load "$n" || die "profile '$n' must be a mapping"
          if [ "$P_MODE" = manual ]; then
            printf '  %-12s manual  %s/%s  gw %s' "$n" "$P_IP" "$P_MASK" "$P_ROUTER"
          else
            printf '  %-12s dhcp' "$n"
          fi
          printf '  dns[%s]  routes[%s]' "$P_DNS" "$P_ROUTES"
          [ "$P_SVC" = "$WIRED" ] || printf '  (service: %s)' "$P_SVC"
          printf '\n'
        done
      }

      apply_profile() {
        profile_load "$1" || die "unknown profile: $1 (see: lan list)"
        local svc=$P_SVC
        local changed=0
        local -a dns routes
        require_service "$svc"
        echo "==> profile '$1' -> service '$svc'"
        if [ "$P_MODE" = manual ]; then
          if [ "$(cur_mode "$svc")" != "Manual Configuration" ] ||
            [ "$(cur_field "$svc" 'IP address')" != "$P_IP" ] ||
            [ "$(cur_field "$svc" 'Subnet mask')" != "$P_MASK" ] ||
            [ "$(cur_field "$svc" 'Router')" != "$P_ROUTER" ]; then
            run "$NS" -setmanual "$svc" "$P_IP" "$P_MASK" "$P_ROUTER"
            changed=1
          fi
        elif [ "$(cur_mode "$svc")" != "DHCP Configuration" ]; then
          run "$NS" -setdhcp "$svc"
          changed=1
        fi
        if [ "$(cur_dns "$svc")" != "$P_DNS" ]; then
          if [ -z "$P_DNS" ]; then
            run "$NS" -setdnsservers "$svc" empty
          else
            read -ra dns <<<"$P_DNS"
            run "$NS" -setdnsservers "$svc" "''${dns[@]}"
          fi
          changed=1
        fi
        if [ "$(cur_routes "$svc")" != "$P_ROUTES" ]; then
          read -ra routes <<<"$P_ROUTES"
          run "$NS" -setadditionalroutes "$svc" "''${routes[@]}"
          changed=1
        fi
        if [ "$changed" = 1 ]; then
          echo "done."
        else
          echo "already up to date."
        fi
        clash_sync --quiet || true
      }

      apply_dhcp() {
        local svc=$WIRED
        require_service "$svc"
        echo "==> plain DHCP -> service '$svc'"
        [ "$(cur_mode "$svc")" = "DHCP Configuration" ] || run "$NS" -setdhcp "$svc"
        [ -z "$(cur_dns "$svc")" ] || run "$NS" -setdnsservers "$svc" empty
        [ -z "$(cur_routes "$svc")" ] || run "$NS" -setadditionalroutes "$svc"
        echo "done."
      }

      # Wi-Fi 排第一，其余服务保持原有相对顺序
      ensure_order() {
        local -a order new
        local s
        mapfile -t order < <("$NS" -listnetworkserviceorder | sed -nE 's/^\([0-9*]+\) //p')
        [ "''${#order[@]}" -gt 0 ] || die "cannot read network service order"
        printf '%s\n' "''${order[@]}" | grep -qxF -- "$WIFI" || die "service not found: $WIFI"
        if [ "''${order[0]}" = "$WIFI" ]; then
          echo "service order OK: '$WIFI' is first"
          return 0
        fi
        new=("$WIFI")
        for s in "''${order[@]}"; do
          [ "$s" = "$WIFI" ] || new+=("$s")
        done
        run "$NS" -ordernetworkservices "''${new[@]}"
      }

      sync_profile() {
        local n
        if ! have_profiles; then
          echo "no profiles file ($PROFILES_FILE); nothing to sync"
          return 0
        fi
        if n=$(detect_profile); then
          echo "current wired IP matches profile '$n'"
          apply_profile "$n"
        else
          echo "no profile matches the current wired IP; nothing changed"
        fi
      }

      status() {
        local -a intranet
        local first d i pairs s
        require_service "$WIRED"
        pairs=$(intranet_pairs) || die "invalid intranet list in $PROFILES_FILE"
        first=$("$NS" -listnetworkserviceorder | sed -nE 's/^\([0-9*]+\) //p' | awk 'NR == 1')
        echo "wired service  : $WIRED"
        for s in "''${WIRED_CANDIDATES[@]}"; do
          if service_exists "$s"; then
            d=$(service_device "$s")
            printf '  candidate    : %-24s %-6s %s%s\n' "$s" "''${d:-?}" \
              "$(link_up "$d" && echo up || echo down)" \
              "$([ "$s" = "$WIRED" ] && echo '  <- in use' || true)"
          else
            printf '  candidate    : %-24s (service not present)\n' "$s"
          fi
        done
        echo "wifi service   : $WIFI"
        echo "first in order : $first"
        echo "intranet       : $pairs"
        if have_profiles; then
          echo "profiles file  : $PROFILES_FILE"
          echo "profile        : $(detect_profile || echo '(none)')"
        else
          echo "profiles file  : $PROFILES_FILE (missing, run: lan edit)"
        fi
        echo
        getinfo "$WIRED" | sed 's/^/  /'
        echo "  DNS servers: $(cur_dns "$WIRED")"
        echo "  Additional routes: $(cur_routes "$WIRED")"
        echo
        echo "kernel route for intranet destinations:"
        read -ra intranet <<<"$pairs"
        for ((i = 0; i + 1 < ''${#intranet[@]}; i += 2)); do
          d=''${intranet[i]}
          printf '  %-16s %s\n' "$d" \
            "$("$ROUTE" -n get "$d" 2>&1 | awk '/^ *(gateway|interface):/ { gsub(/^ +/, ""); printf "%s  ", $0 }')"
        done
      }

      # ---------- Clash 侧：按网线状态叠加/撤掉内网域名规则 ----------
      #
      # Clash Verge 的全局 Merge 不会展开 prepend-proxies / prepend-rules，
      # 所以这些内容不写在 Merge 里，而是在运行时用 mihomo 的 API 叠加到内核上。
      # 网线在 -> 叠加；网线不在 -> 撤掉，避免域名被指向一个到不了的出站而彻底解析失败。

      CLASH_CONF=''${LAN_CLASH_CONFIG:-$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml}

      mask_to_prefix() {
        local o n=0
        local IFS=.
        for o in $1; do
          case "$o" in
            255) n=$((n + 8)) ;;
            254) n=$((n + 7)) ;;
            252) n=$((n + 6)) ;;
            248) n=$((n + 5)) ;;
            240) n=$((n + 4)) ;;
            224) n=$((n + 3)) ;;
            192) n=$((n + 2)) ;;
            128) n=$((n + 1)) ;;
            0) ;;
            *) die "bad netmask octet '$o'" ;;
          esac
        done
        printf '%d' "$n"
      }

      # 网络服务名 -> BSD 设备名（en10 之类）
      service_device() {
        "$NS" -listnetworkserviceorder | awk -v svc="$1" '
          { line = $0; sub(/^\([0-9*]+\) /, "", line) }
          line == svc { want = 1; next }
          want && index(line, "Device: ") {
            sub(/.*Device: /, "", line); sub(/\).*/, "", line); print line; exit
          }
        '
      }

      link_up() {
        local dev=$1
        [ -n "$dev" ] || return 1
        ifconfig "$dev" 2>/dev/null | grep -q 'status: active' || return 1
        ifconfig "$dev" 2>/dev/null | grep -qE '^[[:space:]]*inet [0-9]' || return 1
      }

      clash_socket() {
        local s
        for s in /var/run/clash-verge-service/users/*/verge-mihomo.sock /tmp/verge/verge-mihomo.sock; do
          [ -S "$s" ] || continue
          if curl -s --max-time 3 --unix-socket "$s" http://localhost/version >/dev/null 2>&1; then
            printf '%s' "$s"
            return 0
          fi
        done
        return 1
      }

      clash_get() { have_profiles && yq -r "(.clash.$1) // \"\"" "$PROFILES_FILE" || printf ""; }
      clash_domain_count() {
        have_profiles || { printf '0'; return; }
        yq -r '(.clash.domains // []) | length' "$PROFILES_FILE"
      }

      # 期望状态：profiles.yaml 里配了 clash 段，且网线和 Wi-Fi 都在线 -> on
      clash_desired() {
        [ -n "$(clash_get dns)" ] || { echo off; return; }
        [ "$(clash_domain_count)" -gt 0 ] || { echo off; return; }
        link_up "$(service_device "$WIRED")" || { echo off; return; }
        link_up "$(service_device "$WIFI")" || { echo off; return; }
        echo on
      }

      # 实际状态：内核里有没有 LAN-Direct 这个出站
      clash_actual() {
        local sock code
        sock=$(clash_socket) || { echo unknown; return; }
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
          --unix-socket "$sock" http://localhost/proxies/LAN-Direct || true)
        if [ "$code" = 200 ]; then echo on; else echo off; fi
      }

      clash_build() {
        local want=$1 dev i cidr arr="" pairs
        local -a net
        if [ "$want" = off ]; then
          yq 'del(.["prepend-proxies","prepend-rules","append-proxies","append-rules"])
            | del(.["rule-providers"]["lan-domains"])
            | del(.dns["nameserver-policy"]["rule-set:lan-domains"])' "$CLASH_CONF"
          return
        fi
        dev=$(service_device "$WIRED")
        pairs=$(intranet_pairs) || die "invalid intranet list in $PROFILES_FILE"
        read -ra net <<<"$pairs"
        for ((i = 0; i + 1 < ''${#net[@]}; i += 2)); do
          cidr="''${net[i]}/$(mask_to_prefix "''${net[i + 1]}")"
          arr+="\"IP-CIDR,$cidr,LAN-Direct,no-resolve\","
        done
        DOMAINS=$(yq -o=json -I=0 '(.clash.domains // [])' "$PROFILES_FILE") \
          IPRULES="[''${arr%,}]" \
          IFACE="$dev" \
          DNSSRV="$(clash_get dns)" \
          yq 'del(.["prepend-proxies","prepend-rules","append-proxies","append-rules"])
            | .["rule-providers"]["lan-domains"] =
                {"type": "inline", "behavior": "classical", "payload": env(DOMAINS)}
            | .proxies =
                [{"name": "LAN-Direct", "type": "direct", "udp": true, "interface-name": strenv(IFACE)}]
                + .proxies
            | .rules = ["RULE-SET,lan-domains,LAN-Direct"] + env(IPRULES) + .rules
            | .dns["nameserver-policy"]["rule-set:lan-domains"] = strenv(DNSSRV) + "#LAN-Direct"' \
            "$CLASH_CONF"
      }

      clash_sync() {
        local quiet=0 want actual sock tmp code rc=0
        [ "''${1:-}" = --quiet ] && quiet=1
        say() { [ "$quiet" = 1 ] || echo "$@"; }
        want=$(clash_desired)
        actual=$(clash_actual)
        if [ "$actual" = unknown ]; then
          say "clash: core not reachable; nothing to do"
          return 0
        fi
        if [ "$want" = "$actual" ]; then
          say "clash: already $want"
          return 0
        fi
        if ! [ -r "$CLASH_CONF" ]; then
          say "clash: generated config not readable: $CLASH_CONF"
          return 0
        fi
        sock=$(clash_socket) || return 0
        tmp=$(mktemp -t lan-clash-XXXXXX)
        if clash_build "$want" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          jq -Rs '{payload: .}' <"$tmp" >"$tmp.json"
          code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 --unix-socket "$sock" \
            -X PUT -H 'Content-Type: application/json' \
            --data-binary @"$tmp.json" 'http://localhost/configs?force=false' || true)
          if [ "$code" = 204 ]; then
            echo "clash: $actual -> $want"
          else
            echo "lan: clash-sync failed (HTTP $code)" >&2
            rc=1
          fi
        else
          echo "lan: could not build clash payload" >&2
          rc=1
        fi
        rm -f "$tmp" "$tmp.json"
        return "$rc"
      }

      clash_status() {
        local wdev fdev
        wdev=$(service_device "$WIRED")
        fdev=$(service_device "$WIFI")
        echo "clash config   : $CLASH_CONF"
        echo "core socket    : $(clash_socket || echo '(not reachable)')"
        printf 'wired link     : %s (%s)\n' "$wdev" "$(link_up "$wdev" && echo up || echo down)"
        printf 'wifi link      : %s (%s)\n' "$fdev" "$(link_up "$fdev" && echo up || echo down)"
        echo "intranet dns   : $(clash_get dns)"
        echo "lan domains    : $(clash_domain_count)"
        echo "desired        : $(clash_desired)"
        echo "actual in core : $(clash_actual)"
      }

      cmd=''${1:-help}
      [ "$cmd" = help ] || [ "$cmd" = -h ] || [ "$cmd" = --help ] || resolve_wired
      case "$cmd" in
        help | -h | --help) usage ;;
        edit) edit_profiles ;;
        list) list_profiles ;;
        status) status ;;
        order) ensure_order ;;
        sync) sync_profile ;;
        dhcp) apply_dhcp ;;
        clash-sync) clash_sync "''${2:-}" ;;
        clash-status) clash_status ;;
        *) apply_profile "$cmd" ;;
      esac
    '';
  };
in
{
  options.my.lan = {
    enable = lib.mkEnableOption "有线走内网、Wi-Fi 走公网的策略路由与有线 IP profile 切换";

    wiredService = lib.mkOption {
      type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
      example = [
        "USB 10/100/1000 LAN"
        "USB 10/100 LAN"
      ];
      description = ''
        有线网卡的网络服务名（networksetup -listnetworkserviceorder 里的名字）。
        换转接器就多一个服务名，这里可以给一个候选列表：`lan` 每次运行时挑当前真正接上的那块，
        都没接上时退回列表里第一个存在的服务。
      '';
    };

    wifiService = lib.mkOption {
      type = lib.types.str;
      default = "Wi-Fi";
      description = "Wi-Fi 的网络服务名";
    };

    preferWifi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "激活时把 Wi-Fi 排到网络服务顺序最前，让默认路由稳定走 Wi-Fi";
    };

    intranet = lib.mkOption {
      type = lib.types.listOf networkType;
      default = [
        {
          destination = "10.0.0.0";
          netmask = "255.0.0.0";
        }
      ];
      description = "要走有线的内网网段；每个 profile 会为它们生成指向该 profile 网关的静态路由";
    };

    profilesFile = lib.mkOption {
      type = lib.types.str;
      default = defaultProfilesFile;
      defaultText = lib.literalExpression ''"''${primaryUser home}/.config/lan/profiles.yaml"'';
      description = "profile 数据文件（YAML，放在仓库之外，`lan edit` 可生成模板）";
    };

    clashSync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "后台按网线状态自动叠加/撤掉 Clash 内网域名规则（需要 profiles.yaml 里的 clash 段）";
    };

    clashSyncInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 20;
      description = "自动对齐 Clash 规则的间隔秒数";
    };

    syncOnActivation = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "激活时若有线网卡当前 IP 匹配某个 profile，则重新应用它，保证静态路由等一直在位";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ lanCli ];

    # 网线插拔没有系统级事件钩子，这里用固定间隔对齐；
    # 状态没变化时只有两次 curl，不会重载内核。
    launchd.user.agents.lan-clash-sync = lib.mkIf cfg.clashSync {
      serviceConfig = {
        ProgramArguments = [
          "${lanCli}/bin/lan"
          "clash-sync"
          "--quiet"
        ];
        RunAtLoad = true;
        StartInterval = cfg.clashSyncInterval;
        StandardErrorPath = "/tmp/lan-clash-sync.err";
      };
    };

    system.activationScripts.postActivation.text = ''
      # my.lan: Wi-Fi 优先 + 重新应用当前匹配的有线 profile
      ${lib.optionalString cfg.preferWifi ''
        ${lanCli}/bin/lan order || echo "warning: [my.lan] failed to set network service order" >&2
      ''}
      ${lib.optionalString cfg.syncOnActivation ''
        ${lanCli}/bin/lan sync || echo "warning: [my.lan] failed to sync wired profile" >&2
      ''}
    '';
  };
}
