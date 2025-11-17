#!/usr/bin/env bash
################################################################################
# Portal 认证脚本 - 纯 Bash + curl + openssl
# 依赖：curl、openssl、xxd、python3（解析验证码 JSON）
################################################################################

PORTAL_URL="https://10.10.10.3:8002/portal.cgi"
BASE_URL="https://10.10.10.3:8002"

AES_KEY="Z3UBo1trRTUXkMNn"
AES_IV="M1WiJOK02TrWEX47"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success(){ echo -e "${GREEN}✓${NC} $1"; }
error(){ echo -e "${RED}✗${NC} $1"; }
info(){ echo -e "${YELLOW}➜${NC} $1"; }

usage(){
    echo "用法: $0 <用户名> <密码> [login|check|logout]"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

USERNAME="$1"
PASSWORD="$2"
ACTION="${3:-login}"

command -v curl >/dev/null || { error "需要 curl"; exit 1; }
command -v openssl >/dev/null || { error "需要 openssl"; exit 1; }
command -v xxd >/dev/null || { error "需要 xxd"; exit 1; }
command -v python3 >/dev/null || { error "需要 python3"; exit 1; }

COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT
DEBUG="${DEBUG:-0}"

debug(){
    if [ "$DEBUG" = "1" ]; then
        echo "$@" >&2
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUB_KEY="${SCRIPT_DIR}/portal_pub.pem"

rsa_encrypt() {
    if [ ! -f "$PUB_KEY" ]; then
        error "找不到公钥文件: $PUB_KEY"
        return 1
    fi
    printf '%s' "$1" | openssl pkeyutl -encrypt -pubin -inkey "$PUB_KEY" -pkeyopt rsa_padding_mode:pkcs1 | base64 -w0
}
TOKEN_HEADER="Token: $(rsa_encrypt 'JXU1M0QxJXU2NDkyJ!XU1NzMwJXU2NUI')"

to_hex(){ printf '%s' "$1" | xxd -p | tr -d '\n'; }
zero_pad_hex(){
    local hex="$1"
    local len=$(( ${#hex} / 2 ))
    local pad=$(( (16 - (len % 16)) % 16 ))
    printf '%s' "$hex"
    [ $pad -gt 0 ] && printf '%0.s00' $(seq 1 $pad)
}
aes_encrypt(){
    local hex=$(to_hex "$1")
    local padded=$(zero_pad_hex "$hex")
    printf '%s' "$padded" | xxd -r -p | \
        openssl enc -aes-128-cbc -K "$(to_hex "$AES_KEY")" -iv "$(to_hex "$AES_IV")" -nopad | base64 -w0
}

fetch_code(){
    local resp code
    resp=$(curl -s -k -X POST "${BASE_URL}/user_auth_verify.cgi" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "HTTP_X_REQUESTED_WITH: xmlhttprequest" \
        -H "Referer: ${BASE_URL}/portal/local/index.html" \
        -H "$TOKEN_HEADER" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" --data "submit=submit")
    code=$(python3 -c 'import json,sys
try:
    raw=sys.stdin.read()
    data=json.loads(raw)
    verify=data.get("verify")
    if verify in (1, "1", True):
        print(data.get("code",""))
    else:
        print("")
except Exception:
    print("", end="")
' <<<"$resp")
    debug "验证码响应: $resp"
    debug "解析到验证码: $code"
    printf '%s' "$code"
}

check_status(){
    info "检查认证状态..."
    curl -s -k "${BASE_URL}/user_info.cgi" \
        -H "X-Requested-With: XMLHttpRequest" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR"
}

do_login(){
    info "正在认证用户: $USERNAME..."
    local enc_user enc_pass code response

    enc_user=$(aes_encrypt "$USERNAME")
    enc_pass=$(aes_encrypt "$PASSWORD")
    code=$(fetch_code)
    debug "获取验证码: ${code:-<empty>}"

    send_login(){
        curl -s -k -X POST "${PORTAL_URL}" \
            -H "Accept: */*" \
            -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
            -H "X-Requested-With: XMLHttpRequest" \
            -H "HTTP_X_REQUESTED_WITH: xmlhttprequest" \
            -H "Referer: ${BASE_URL}/portal/local/index.html" \
            -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
            --data-urlencode "username=${enc_user}" \
            --data-urlencode "password=${enc_pass}" \
            --data "uplcyid=null" \
            --data "language=0" \
            --data-urlencode "code=${1}" \
            --data "submit=submit" \
            --max-time 30
        debug "提交验证码 ${1}"
    }

    response=$(send_login "$code")
    if echo "$response" | grep -q "验证码错误或已失效"; then
        info "验证码失效，重新获取..."
        code=$(fetch_code)
        response=$(send_login "$code")
    fi

    echo "服务器响应: $response"
}

do_logout(){
    info "正在注销..."
    response=$(curl -s -k -X POST "${BASE_URL}/user_logout.cgi" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "X-Requested-With: XMLHttpRequest" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        --data "submit=submit")
    echo "服务器响应: $response"
}

case "$ACTION" in
    check)  check_status ;;
    logout) do_logout ;;
    *)      do_login ;;
esac
