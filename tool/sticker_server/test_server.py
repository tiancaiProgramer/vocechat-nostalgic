import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from server import App, Server, handler_for


class FakeVC(BaseHTTPRequestHandler):
    seen = []
    def do_GET(self):
        token = self.headers.get('X-API-Key')
        self.seen.append((self.path, self.headers.get('Referer')))
        if self.path != '/api/user/me':
            self.send_error(404)
            return
        if token == 'redirect':
            self.send_response(302)
            self.send_header('Location', '/must-not-follow')
            self.end_headers()
            return
        if token not in ('account-a', 'account-b'):
            self.send_error(401)
            return
        raw = json.dumps({'uid': 7 if token == 'account-a' else 8}).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)
    def log_message(self, *_): pass


def start(server):
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return thread


class ServiceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vc = ThreadingHTTPServer(('127.0.0.1', 0), FakeVC)
        cls.vc_thread = start(cls.vc)
        cls.upstream = f'http://127.0.0.1:{cls.vc.server_port}'
        fixtures = Path(__file__).resolve().parents[2] / 'test/fixtures/stickers'
        cls.png = (fixtures / 'red.png').read_bytes()
        cls.gif = (fixtures / 'animated.gif').read_bytes()
        cls.blue = (fixtures / 'blue.png').read_bytes()
    @classmethod
    def tearDownClass(cls):
        cls.vc.shutdown()
        cls.vc.server_close()
        cls.vc_thread.join()
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.app = App(self.temp.name, self.upstream, 'https://chat.example.test', max_items=2)
        self.server = Server(('127.0.0.1', 0), handler_for(self.app))
        self.thread = start(self.server)
        self.base = f'http://127.0.0.1:{self.server.server_port}'
    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.temp.cleanup()
    def req(self, path='/v1/stickers', method='GET', data=None, token='account-a', **headers):
        if token is not None: headers['X-API-Key'] = token
        req = Request(self.base + path, method=method, data=data, headers=headers)
        try:
            response = urlopen(req, timeout=3)
        except HTTPError as e:
            response = e
        with response:
            raw = response.read()
            parsed = json.loads(raw) if response.headers.get_content_type() == 'application/json' else raw
            return response.status, parsed, response.headers
    def put(self, data, token='account-a', key=None):
        key = key or hashlib.sha256(data).hexdigest()
        return self.req('/v1/stickers/' + key, 'PUT', data, token,
                        **{'X-Sticker-Width':'24', 'X-Sticker-Height':'18'})
    def test_empty_authenticated_list_and_referer(self):
        status, data, _ = self.req()
        self.assertEqual((status, data['uid'], data['items']), (200, 7, []))
        self.assertEqual(data['service'], 'vocechat-stickers')
        self.assertEqual(FakeVC.seen[-1], ('/api/user/me','https://chat.example.test/'))
    def test_no_token_or_forged_uid_cannot_access(self):
        for token in (None, 'invalid'):
            self.assertEqual(self.req(token=token)[0], 401)
        self.assertEqual(self.req('/v1/stickers?uid=7', token='account-b')[0],400)
    def test_original_gif_round_trip_and_account_isolation(self):
        self.assertEqual(self.put(self.gif)[0], 200)
        key = hashlib.sha256(self.gif).hexdigest()
        status, data, headers = self.req('/v1/stickers/' + key)
        self.assertEqual((status, data), (200, self.gif))
        self.assertEqual(headers.get_content_type(), 'image/gif')
        self.assertEqual(headers['Cache-Control'], 'private, no-store')
        self.assertEqual(headers['X-Content-Type-Options'], 'nosniff')
        self.assertEqual(self.req(token='account-b')[1]['items'], [])
        self.assertEqual(self.req('/v1/stickers/'+key, token='account-b')[0],404)
        self.req('/v1/stickers/'+key, 'DELETE', token='account-b')
        self.assertEqual(len(self.req()[1]['items']),1)
    def test_idempotent_upload_delete_and_reimport(self):
        self.put(self.png); self.put(self.png)
        self.assertEqual(len(self.req()[1]['items']),1)
        key=hashlib.sha256(self.png).hexdigest()
        self.assertEqual(self.req('/v1/stickers/'+key,'DELETE')[0],200)
        self.assertEqual(self.req('/v1/stickers/'+key,'DELETE')[0],200)
        self.assertEqual(self.req()[1]['items'],[])
        self.put(self.png)
        self.assertEqual(len(self.req()[1]['items']),1)
    def test_quota_and_hash_validation(self):
        self.assertEqual(self.put(self.png, key='0'*64)[0],422)
        self.assertEqual(self.put(b'<svg/>')[0],415)
        self.put(self.png); self.put(self.gif)
        self.assertEqual(self.put(self.blue)[0],409)
        self.assertEqual(self.put(self.png)[0],200)
        self.assertEqual(len(self.req()[1]['items']),2)
    def test_oversized_upload_rejected_before_reading(self):
        key='0'*64
        status, body, _ = self.req('/v1/stickers/'+key, 'PUT', b'x',
                                  **{'Content-Length':str(11*1024*1024)})
        self.assertEqual((status,body['error']),(413,'image_too_large'))
    def test_vc_redirect_is_not_followed(self):
        count=len(FakeVC.seen)
        self.assertEqual(self.req(token='redirect')[0],502)
        self.assertEqual(len(FakeVC.seen),count+1)
    def test_restart_keeps_library_and_rejects_different_instance(self):
        self.put(self.gif)
        reopened=App(self.temp.name,self.upstream,'https://chat.example.test')
        self.assertEqual(reopened.get(7,hashlib.sha256(self.gif).hexdigest())[1],self.gif)
        with self.assertRaises(ValueError):
            App(self.temp.name,self.upstream,'https://another.example.test')
    def test_health_and_invalid_paths(self):
        self.assertEqual(self.req('/healthz',token=None)[0],200)
        for path in ('/v1/stickers/../secrets','/v1/stickers/%2e%2e','/data/stickers.sqlite3'):
            self.assertEqual(self.req(path)[0],404)

if __name__ == '__main__': unittest.main()
