# 收藏表情云同步部署

适用于飞牛 Docker 与 Nginx Proxy Manager（NPM）。VC 容器名为 `vocechat-1`，NPM 容器名为 `nginx-proxy-manager`。

表情服务复用 VC 和 NPM 已有的共享网络。准备脚本会优先选择 `nas-services`，并将选择保存到 `.env`。Compose 会在表情容器更新、重建时自动接入该网络。

## 1. 准备并启动

下载发布页中的 `vocechat-stickers-docker.zip`，把文件解压到长期保存的部署目录。进入包含 `compose.yaml` 的目录，在飞牛终端执行以下命令，将示例地址替换成手机添加的完整 VC 地址，包含实际的 HTTPS 和端口。

```sh
sh prepare.sh 'https://chat.example.com'
docker compose up -d --build
sh check.sh
```

首次构建需要下载 Python 基础镜像。数据、收藏原图和待同步状态保存在部署目录的 `data/` 中。

`check.sh` 检查表情服务及其到 VC 账号验证接口的连通性。检查完成后，还需在手机上点云朵确认账号同步。

可在 `.env` 调整以下配置。

| 配置 | 用途 |
| --- | --- |
| `VC_PUBLIC_URL` | 手机添加的完整 VC 地址 |
| `VC_DOCKER_NETWORK` | VC、NPM 已有的共同网络，由脚本自动识别 |
| `VC_UPSTREAM` | VC 容器内部地址，默认 `http://vocechat-1:3000` |
| `PUID`、`PGID` | 表情数据目录的用户和组，由脚本填写 |

宿主机映射端口与容器内部端口分别使用。比如 `3009:3000`，上游地址使用 `vocechat-1:3000`。

## 2. 配置 NPM 路径

编辑现有 VC 域名的 Proxy Host，在 **Custom Locations** 中新增一项。

| 字段 | 值 |
| --- | --- |
| Location | `/stickers/` |
| Scheme | `http` |
| Forward Hostname / IP | `vocechat-stickers` |
| Forward Port | `8080` |

点击这一项旁边的小齿轮，填入以下两行并保存。

```nginx
client_max_body_size 11m;
rewrite ^/stickers/(.*)$ /$1 break;
```

配置文件 `nginx-proxy-manager.conf` 也包含这两行。齿轮位置是新增的 `/stickers/` 路径项旁。

打开 `https://你的VC地址/stickers/healthz`，应返回以下内容。

```json
{"service":"vocechat-stickers","version":1}
```

## 3. 手机验证

在怀旧版打开 **聊天 → 表情 → 收藏表情**，点击云朵，等待打勾。另一台设备登录同一服务器的同一账号后，打开收藏面板验证同步。

同步在打开面板、导入或删除收藏以及点击云朵时进行。默认每账号最多 512 张、256 MiB，单张上限 10 MiB，支持 PNG、JPEG、GIF 和 WebP 原文件。表情发送使用 VC 图片消息接口。

## 更新已有部署

将新版部署文件放进原部署目录，执行以下命令。

```sh
sh prepare.sh
docker compose up -d --build
sh check.sh
```

脚本沿用已有 `VC_PUBLIC_URL` 和数据目录，为旧版 `.env` 补充已有共享网络。旧包用户也通过这一流程切换到持久网络配置。

## 故障检查

| 现象 | 操作 |
| --- | --- |
| 云朵感叹号 | 执行 `sh check.sh` |
| 表情服务无法访问 VC、`502 / vc_unavailable` | 核对共享网络及 `VC_UPSTREAM` |
| 数据目录权限错误、SQLite 无法打开 | 用管理员身份运行 `sh prepare.sh`，按 `.env` 修复 `data/` 所有者 |
| 首次镜像拉取失败 | 检查 NAS 能否访问 Dockerfile 中的镜像仓库 |

健康检查成功代表表情服务存活，云朵打勾才表示该账号完成同步。

## 备份

停止表情服务后，备份整个 `data/` 目录和 `.env`，再启动。

```sh
docker compose stop
# 使用飞牛文件管理器备份 data/ 和 .env
docker compose start
```

一个数据目录对应一个 VC 实例。更换服务器实例时使用独立目录，避免不同服务器的 UID 混用。
