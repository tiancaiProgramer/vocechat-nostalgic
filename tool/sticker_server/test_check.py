from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest

SOURCE = Path(__file__).resolve().parent


class CheckTests(unittest.TestCase):
    def run_check(self, status=401, health=True, unreachable=False):
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path == '/healthz':
                    raw = json.dumps(
                        {'service': 'vocechat-stickers', 'version': 1}
                        if health else {'service': 'wrong'}).encode()
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(raw)
                    return
                if self.path != '/api/user/me':
                    self.send_error(404)
                    return
                if self.headers.get('X-API-Key'):
                    self.send_error(400)
                    return
                self.send_response(status)
                if status == 302:
                    self.send_header('Location', '/login')
                self.end_headers()
                self.wfile.write(json.dumps({'uid': 7}).encode())

            def log_message(self, *_):
                pass

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        worker = threading.Thread(target=server.serve_forever, daemon=True)
        worker.start()
        try:
            with tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                check = (SOURCE / 'check.sh').read_text().replace(
                    'http://127.0.0.1:8080/healthz',
                    f'http://127.0.0.1:{server.server_port}/healthz')
                (root / 'check.sh').write_text(check)
                fake = root / 'docker'
                fake.write_text(
                    '#!' + sys.executable + '\n'
                    'import subprocess,sys\n'
                    'assert sys.argv[1:]==["exec","-i","vocechat-stickers","python","-"]\n'
                    'result=subprocess.run([sys.executable,"-"],input=sys.stdin.buffer.read())\n'
                    'raise SystemExit(result.returncode)\n')
                fake.chmod(0o755)
                environment = dict(os.environ)
                environment.update(
                    PATH=str(root) + os.pathsep + os.environ['PATH'],
                    PYTHONPATH=str(SOURCE),
                    PYTHONDONTWRITEBYTECODE='1',
                    VC_UPSTREAM=f'http://127.0.0.1:{1 if unreachable else server.server_port}',
                    VC_PUBLIC_URL='https://chat.example.com:36',
                )
                return subprocess.run(
                    ['sh', 'check.sh'], cwd=root, env=environment,
                    capture_output=True, text=True, timeout=12)
        finally:
            server.shutdown()
            server.server_close()
            worker.join(timeout=2)

    def test_expected_unauthenticated_response_is_reachable(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('VC校验接口可达', result.stdout)

    def test_forbidden_response_is_reachable(self):
        self.assertEqual(self.run_check(status=403).returncode, 0)

    def test_valid_public_me_response_is_reachable(self):
        self.assertEqual(self.run_check(status=200).returncode, 0)

    def test_upstream_server_error_fails(self):
        result = self.run_check(status=502)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('HTTP 502', result.stdout)

    def test_redirect_cannot_be_mistaken_for_the_me_endpoint(self):
        result = self.run_check(status=302)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('HTTP 302', result.stdout)

    def test_unreachable_upstream_fails_even_with_healthy_sticker_service(self):
        result = self.run_check(unreachable=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('表情服务无法访问VC', result.stdout)

    def test_wrong_health_response_fails(self):
        result = self.run_check(health=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('健康检查失败', result.stdout)


if __name__ == '__main__':
    unittest.main()
