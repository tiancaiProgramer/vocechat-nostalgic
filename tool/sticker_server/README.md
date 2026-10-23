# 飞牛 Docker + Nginx Proxy Manager 表情同步

此部署包对应 vocechat 怀旧版 3109 及后续接入版。3108/原版客户端没有此同步功能。
VC 容器：`vocechat-1`；NPM 容器：`nginx-proxy-manager`。

表情服务不会替换 VC，不需要修改 VC 数据库。它是本项目新增的独立服务，并非 VoceChat 官方功能。

## 1. 上传部署包

在飞牛文件管理器中建立一个长期保存的目录，例如你自己的 Docker 目录下的 `vocechat-stickers`。
将部署包解压进去，确保该目录直接包含 `compose.yaml`、`Dockerfile`、`server.py` 和 `prepare.sh`。
不要解压到每次重启就清理的临时目录。

在飞牛中启用 SSH，以平时管理飞牛的用户登录，然后进入上述目录。路径请从飞牛复制，下面用示意路径：

```sh
cd '/你的实际路径/vocechat-stickers'
```

## 2. 准备账号验证地址和容器网络

以下命令中的地址替换成手机目前添加的 VC 完整地址，不含 `/api`。优先使用已有 HTTPS 域名。
不要填写后台管理地址、密码或 Token。

```sh
sh prepare.sh 'https://你的VC域名'
```

脚本会：

- 生成 `.env`，自动填入你的 UID/GID 和 VC 对外地址。
- 创建 `data` 目录，由你的飞牛用户持有，保存 SQLite 数据库和表情原文件。
- 创建共享网络 `vocechat-sticker-net`，将上述两个现有容器连接进去。
- 使用 `vocechat-1:3000` 作为默认 VC 内部地址。脚本不会改变 VC 原有端口、数据卷或反代；请按下文核对内部监听端口。

如果脚本报告没有 Docker 权限，用同一飞牛用户执行：

```sh
sudo sh prepare.sh 'https://你的VC域名'
```

脚本会使用 sudo 前的用户 UID/GID，并设置新建 data 目录的所有者。后面的 Docker Compose 命令如仍提示权限不足，也在命令前加 `sudo`。如果你直接以 root 登录，生成的 UID/GID 将是 root；希望让普通用户管理数据时，可在部署前把 `.env` 的 PUID/PGID 和 data 目录所有者一并调整。

默认 VC 容器内部端口为 `3000`，这和飞牛宿主机映射的端口是两回事。如果你的 VC 修改了内部监听端口，请同步修改 `compose.yaml` 中的 `VC_UPSTREAM`。

## 3. 构建和启动

在同一目录运行：

```sh
docker compose up -d --build
docker compose ps
```

若飞牛终端仅支持 `docker-compose`，将命令中的 `docker compose` 换成 `docker-compose`。
也可以在飞牛 Docker → Compose 中导入该目录的 `compose.yaml`；使用同一个目录，确保 `.env`、源文件和 data 都在旁边。
首次启动需要下载 Python 基础镜像。部署包使用 AWS 公共仓库中的 Docker 官方 Python 镜像，以绕过部分飞牛 Docker Hub 加速源返回 401 的情况。

如果使用较早的部署包，报错中出现 `docker.fnnas.com` 和 `401 Unauthorized`，在当前部署目录执行：

```sh
sed -i 's|^FROM python:3.13-alpine$|FROM public.ecr.aws/docker/library/python:3.13-alpine|' Dockerfile
docker compose up -d --build
```

备用来源：[AWS 公共镜像仓库 Python 页面](https://gallery.ecr.aws/docker/library/python)。仓库无需 AWS 账号即可进行公共镜像拉取；NAS 本身仍需能够访问该仓库。若报网络超时，先检查网络连通性。

容器名是 `vocechat-stickers`，内部端口 `8080`，无需向飞牛宿主机映射端口。

## 4. 在 NPM 接入原 VC 域名

采用 NPM 自带 Custom Locations 生成路径配置。旧版部署说明曾要求在主机级高级配置中添加整个 location；用户环境中该配置触发了域名规则下线，因此改用下列界面方式。不要同时保留两种方式。

先在飞牛宿主机终端只读确认 NPM 容器能访问表情服务：

```sh
docker exec nginx-proxy-manager curl -fsS --max-time 5 http://vocechat-stickers:8080/healthz
```

看到 `{"service":"vocechat-stickers","version":1}` 后再配置。若不能访问，先检查共享网络和容器运行状态，不修改正常的 VC 反代。

1. 打开 NPM → Hosts → Proxy Hosts，编辑原 VC 域名的规则。
2. Details 和 SSL 保留现有 VC 配置；顶部主机级齿轮保留原有内容，移除旧说明所加 `/stickers/` location 整段。
3. 打开 Custom Locations，点击 Add Location。
4. 对这一项填写：

| 字段 | 值 |
| --- | --- |
| Location / 路径 | `/stickers/` |
| Scheme | `http` |
| Forward Hostname / IP | `vocechat-stickers` |
| Forward Port | `8080` |

5. 点击**刚新增这一项旁边的小齿轮**，仅粘贴 `nginx-proxy-manager.conf` 内容，即以下两条指令；不添加 `location {}` 或 `proxy_pass`，这些由 NPM 生成：

```nginx
client_max_body_size 11m;
rewrite ^/stickers/(.*)$ /$1 break;
```

6. 点击 Save，确认 VC 域名规则为 Online 且 VC 首页仍可访问，然后进行健康检查。

该配置将外部 `/stickers/v1/stickers` 的前缀移除，再转发到 `http://vocechat-stickers:8080/v1/stickers`。
VC 登录会话的 `X-API-Key` 由 Nginx 默认请求头转发机制传递，表情服务用它访问固定的 `http://vocechat-1:3000/api/user/me` 核验身份。
域名的原 VC 主转发保持原配置；表情路径不使用 CDN 缓存。
如果保存后出现 Offline，先复制该状态的具体错误信息，移除新建的这一项并保存恢复 VC，再根据错误修正，避免重复试填。

## 5. 检查路径

在浏览器打开：

```text
https://你的VC域名/stickers/healthz
```

应看到：

```json
{"service":"vocechat-stickers","version":1}
```

再打开 `/stickers/v1/stickers`，未携带登录身份时应返回 `unauthorized`，这是正常的。
健康检查成功只代表 NPM 到表情容器畅通；VC 账号验证还需使用 APK 实际测试。
不需要把真实登录 Token 复制到终端或发给其他人。

## 6. 安装 APK，验证同步

1. 安装怀旧版 3109 接入版，保留现有账号、消息和收藏。
2. 用上述同一 VC 域名登录，打开聊天 → 表情 → 收藏表情。
3. 等待状态变为“已与服务器同步”；旧版已有本地收藏将自动上传。
4. 在另一台手机上安装接入版，登录**同一服务器的同一账号**，打开收藏表情。
5. 导入一个图片和一个 GIF，确认两边能看到；删除其中一个，再打开另一台手机的收藏或点云朵图标，确认同步删除。

同步发生在打开收藏面板，以及新增/删除收藏后；不是后台常驻实时连接。失败时保留本机文件和待处理操作，下次打开或点云朵重试。
离线时不同手机对同一表情做相反操作，以服务端最后成功处理的操作为准。
超过默认每账号 512 张或 256 MiB 时，上传会保留待同步；单张上限 10 MiB。PNG/JPEG/GIF/WebP 原文件保存，不转码 GIF。
表情发送仍经过原 VC 图片消息接口，对方可以使用原版客户端接收。

服务尚未配置时显示“本机收藏”，不影响导入、收藏和发送。不支持将同一账号的收藏自动同步到另一个独立 VC 服务器。

## 7. 备份、容器更新与退出

**备份：**在本目录停止表情服务，再备份整个 data 文件夹和 `.env`，完成后启动：

```sh
docker compose stop
# 此时用飞牛文件管理器备份整个 data 文件夹和 .env。
docker compose start
```

不要只复制运行中的 `stickers.sqlite3`，SQLite 可能还有 `-wal` 和 `-shm` 文件。
一个 data 目录仅用于一个 VC 实例；更换 VC 实例时新建 data。单纯变更域名时需在确认仍为原 VC 实例后单独迁移身份标记，避免混用 UID。

**更新：**保留 data 和 `.env`，替换部署文件，再执行 `docker compose up -d --build`。

**VC/NPM 被 Compose 重新创建后：**手工添加的共享网络可能丢失。再次运行 `sh prepare.sh` 恢复连接（已有 `.env` 不会被覆盖）。
长期使用可在原 VC、NPM 的 Compose 中各追加：

```yaml
services:
  # 在各自原有服务下追加网络，保留它原来已有的网络列表。
  your_existing_service:
    networks:
      - default
      - vocechat-sticker-net
networks:
  vocechat-sticker-net:
    external: true
```

这里的 `your_existing_service` 是原 Compose 的服务键，不是让你新增同名服务；不熟悉 Compose 时先使用脚本连接即可。

**停用同步：**删除 NPM 中新增的 /stickers/ Custom Location 并保存，然后在表情目录执行 `docker compose down`。data 会保留，手机已缓存的收藏仍可使用。

## 常见故障

- `/stickers/healthz` 404 或返回 VC 页面：规则未放在当前使用的域名，或被其他 location 覆盖。
- 502：先确认 `docker compose ps`，以及 VC、NPM、表情三个容器都连接 `vocechat-sticker-net`。
- 健康检查正常但 APK 提示同步不可用：核对 `.env` 的 VC_PUBLIC_URL、VC 内部端口、登录状态；VC 会话失效时先正常进入聊天刷新会话，再点云朵。
- 容器日志显示 Permission denied：检查 data 文件夹所有者与 `.env` 的 PUID/PGID，调整目录所有权，不需要开放全盘或特权模式。
- 如果出现 `sqlite3.OperationalError: unable to open database file`，先检查 data 目录的写入权限。新版 prepare.sh 会按 `.env` 的 PUID/PGID 修复既有目录；旧包可在部署目录的宿主机管理员终端执行以下命令，仅调整表情数据：

  ```sh
  docker compose stop
  STICKER_UID_GID=$(docker inspect --format '{{.Config.User}}' vocechat-stickers)
  chown -hR "$STICKER_UID_GID" ./data
  find ./data -type d -exec chmod 700 {} +
  find ./data -type f -exec chmod 600 {} +
  docker compose up -d
  ```

  如仍失败，查看 `docker inspect vocechat-stickers` 中 `/data` 的挂载来源及 `RW`，确认数据所在磁盘有可用空间且可写。
- 如果日志明确为 `python: can't open file '/app/server.py': [Errno 13] Permission denied`，这是镜像内程序文件的读取权限，不是 data 目录权限。新版 Dockerfile 使用 `COPY --chmod=0644` 明确指定权限。旧部署目录内可执行以下命令修复并重建：

  ```sh
  sed -i 's|^COPY server.py /app/server.py$|COPY --chmod=0644 server.py /app/server.py|' Dockerfile
  docker compose up -d --build --force-recreate
  ```

- 相同账号另一台手机没有实时出现：打开收藏面板或点云朵刷新，两台都需安装接入版。

## 验证范围

本包包含服务端 HTTP 测试和客户端同步测试。正式使用前仍需在你的飞牛上完成镜像构建、NPM 保存检查和两台手机实测；本地构建环境没有连接你的 NAS。

网络配置依据：[NPM 官方共享网络说明](https://nginxproxymanager.com/advanced-config/#best-practice-use-a-docker-network)、[Docker 自定义网络](https://docs.docker.com/engine/network/)。
