#!/bin/sh
set -eu
cd "$(dirname "$0")"
docker exec -i vocechat-stickers python - <<'PYTHON'
import json
import os
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import ProxyHandler, Request, build_opener

from server import NoRedirect

opener = build_opener(ProxyHandler({}), NoRedirect())
for attempt in range(5):
    try:
        with opener.open('http://127.0.0.1:8080/healthz', timeout=3) as response:
            health = json.load(response)
        if health.get('service') != 'vocechat-stickers' or health.get('version') != 1:
            raise ValueError('unexpected health response')
        print('表情服务正常')
        break
    except (OSError, ValueError):
        if attempt == 4:
            print('表情服务健康检查失败')
            sys.exit(1)
        time.sleep(1)

upstream = os.environ['VC_UPSTREAM'].rstrip('/')
public_url = os.environ['VC_PUBLIC_URL'].rstrip('/')
request = Request(upstream + '/api/user/me', headers={
    'Referer': public_url + '/', 'Origin': public_url, 'Accept': 'application/json'})
try:
    with opener.open(request, timeout=6) as response:
        data = json.load(response)
        if not isinstance(data, dict) or not isinstance(data.get('uid'), int):
            raise ValueError('unexpected VC response')
except HTTPError as error:
    if error.code not in (401, 403):
        print('VC校验接口返回HTTP', error.code)
        sys.exit(1)
except (URLError, OSError, ValueError):
    print('表情服务无法访问VC，请检查共享网络和.env中的VC_UPSTREAM')
    sys.exit(1)
print('VC校验接口可达，下一步在手机点云朵验证账号同步')
PYTHON
