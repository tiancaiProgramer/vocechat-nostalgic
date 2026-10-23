#!/bin/sh
set -eu
cd "$(dirname "$0")"
if ! command -v docker >/dev/null 2>&1; then
  echo '找不到 docker，请在飞牛SSH终端内运行。' >&2
  exit 1
fi
if ! docker inspect vocechat-1 >/dev/null 2>&1 || ! docker inspect nginx-proxy-manager >/dev/null 2>&1; then
  echo '请确认容器名称是 vocechat-1 和 nginx-proxy-manager，并确认当前用户有Docker权限。' >&2
  exit 1
fi
if [ ! -f .env ]; then
  vc_url=${1:-}
  case "$vc_url" in
    https://*|http://*) ;;
    *) echo "首次运行请带上VC地址：sh prepare.sh 'https://你的VC域名'" >&2; exit 1 ;;
  esac
  case "$vc_url" in
    *[!a-zA-Z0-9:/._~-]*|*/api|*/api/) echo '请填写正常VC地址，不含/api、密码、查询参数。' >&2; exit 1 ;;
  esac
  umask 077
  owner_uid=${SUDO_UID:-$(id -u)}
  owner_gid=${SUDO_GID:-$(id -g)}
  printf 'VC_PUBLIC_URL=%s\nPUID=%s\nPGID=%s\n' "$vc_url" "$owner_uid" "$owner_gid" > .env
  mkdir -p data
  if [ "$(id -u)" = 0 ]; then
    chown "$owner_uid:$owner_gid" .env data
  fi
fi
mkdir -p data
if [ -L data ] || [ ! -d data ]; then
  echo 'data必须是当前部署目录内的真实目录。' >&2
  exit 1
fi
sticker_uid=$(awk -F= '$1=="PUID" {gsub(/\r/,"",$2); value=$2} END {print value}' .env)
sticker_gid=$(awk -F= '$1=="PGID" {gsub(/\r/,"",$2); value=$2} END {print value}' .env)
case "$sticker_uid" in ''|*[!0-9]*) echo '.env中的PUID须为纯数字。' >&2; exit 1 ;; esac
case "$sticker_gid" in ''|*[!0-9]*) echo '.env中的PGID须为纯数字。' >&2; exit 1 ;; esac
if [ "$(id -u)" = 0 ]; then
  # Normalize existing data too: an earlier extraction/preparation may have
  # created a root-owned 0700 directory for a different container UID.
  chown -hR "$sticker_uid:$sticker_gid" data
  find data -type d -exec chmod 700 {} +
  find data -type f -exec chmod 600 {} +
elif [ "$(stat -c %u data)" != "$sticker_uid" ] || [ ! -w data ]; then
  echo 'data目录权限与容器PUID不匹配，请使用sudo重新运行本脚本。' >&2
  exit 1
else
  find data -type d -exec chmod 700 {} +
  find data -type f -exec chmod 600 {} +
fi
if ! docker network inspect vocechat-sticker-net >/dev/null 2>&1; then
  docker network create vocechat-sticker-net >/dev/null
fi
for container in vocechat-1 nginx-proxy-manager; do
  connected=$(docker inspect --format '{{if index .NetworkSettings.Networks "vocechat-sticker-net"}}yes{{end}}' "$container")
  if [ "$connected" != yes ]; then
    docker network connect vocechat-sticker-net "$container"
  fi
done
echo '准备完成：现有VC/NPM已连接共享网络。'
echo '下一步在当前目录执行 docker compose up -d --build，再按README配置NPM。'
