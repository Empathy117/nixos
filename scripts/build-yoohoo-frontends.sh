#!/usr/bin/env bash
set -euo pipefail

# 后端代码所在目录
BASE="/srv/yoohoo/main"
# Nginx 静态文件根目录
WWW="/srv/www"

echo "[build] using BASE=${BASE}, WWW=${WWW}"

build_bsc() {
local src="${BASE}/bsc-frontend"
local out_name="febsc"
local dst="${WWW}/yoohoo"

if [[ ! -d "${src}" ]]; then
    echo "[build:bsc] skip, ${src} not found"
    return
fi

echo "[build:bsc] building bsc-frontend..."
cd "${src}"
pnpm install --frozen-lockfile || pnpm install
pnpm build:production-no-ts

echo "[build:bsc] copying to ${dst}/${out_name}/"
sudo mkdir -p "${dst}"
sudo rm -rf "${dst}/${out_name}"
sudo cp -r "${src}/${out_name}" "${dst}/"
}

build_mdm() {
local src="${BASE}/mdm-frontend"
local out_name="femdm"
local dst="${WWW}/yoohoo"

if [[ ! -d "${src}" ]]; then
    echo "[build:mdm] skip, ${src} not found"
    return
fi

echo "[build:mdm] building mdm-frontend..."
cd "${src}"
pnpm install --frozen-lockfile || pnpm install
pnpm build:production-no-ts

echo "[build:mdm] copying to ${dst}/${out_name}/"
sudo mkdir -p "${dst}"
sudo rm -rf "${dst}/${out_name}"
sudo cp -r "${src}/${out_name}" "${dst}/"
}

build_bms() {
local src="${BASE}/bms-frontend"
local out_name="dist"
local dst="${WWW}"
local dst_name="febms"

if [[ ! -d "${src}" ]]; then
    echo "[build:bms] skip, ${src} not found"
    return
fi

echo "[build:bms] building bms-frontend..."
cd "${src}"
pnpm install --frozen-lockfile || pnpm install
pnpm build:production-no-ts

echo "[build:bms] copying to ${dst}/${dst_name}/"
sudo mkdir -p "${dst}"
sudo rm -rf "${dst}/${dst_name}"
sudo cp -r "${src}/${out_name}" "${dst}/${dst_name}"
}

build_portal() {
local src="${BASE}/portal-frontend"
local out_name="portal"
local dst="${WWW}"

if [[ ! -d "${src}" ]]; then
    echo "[build:portal] skip, ${src} not found"
    return
fi

echo "[build:portal] building portal-frontend..."
cd "${src}"
pnpm install --frozen-lockfile || pnpm install
pnpm build:production-no-ts

echo "[build:portal] copying to ${dst}/${out_name}/"
sudo mkdir -p "${dst}"
sudo rm -rf "${dst}/${out_name}"
sudo cp -r "${src}/${out_name}" "${dst}/"
}

build_bsc
build_mdm
build_bms
build_portal

echo "[build] done."