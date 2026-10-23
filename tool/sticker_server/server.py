"""Private VoceChat sticker sidecar. Python standard library only."""
import hashlib
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import sqlite3
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler, ProxyHandler

SERVICE = 'vocechat-stickers'
MAX_BYTES = 10 * 1024 * 1024
ID = re.compile(r'^[a-f0-9]{64}$')
MIMES = {'png': 'image/png', 'jpg': 'image/jpeg', 'gif': 'image/gif', 'webp': 'image/webp'}


class Failure(Exception):
    def __init__(self, status, code):
        self.status, self.code = status, code


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def extension(data):
    if data.startswith(b'\x89PNG\r\n\x1a\n'):
        return 'png'
    if data.startswith(b'\xff\xd8\xff'):
        return 'jpg'
    if data[:6] in (b'GIF87a', b'GIF89a'):
        return 'gif'
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        return 'webp'
    raise Failure(415, 'unsupported_image')


class App:
    def __init__(self, directory, upstream, public_url, max_items=512,
                 quota_bytes=256 * 1024 * 1024):
        self.directory = Path(directory)
        self.directory.mkdir(parents=True, exist_ok=True)
        self.db_path = self.directory / 'stickers.sqlite3'
        self.upstream = upstream.rstrip('/')
        self.public_url = public_url.rstrip('/') + '/'
        for value in (self.upstream, self.public_url):
            u = urlsplit(value)
            if u.scheme not in ('http', 'https') or not u.hostname or u.username or u.password or u.query or u.fragment:
                raise ValueError('Invalid upstream/public URL')
        self.opener = build_opener(ProxyHandler({}), NoRedirect())
        self.max_items, self.quota_bytes = max_items, quota_bytes
        self.lock = threading.Lock()
        with self.connect() as db:
            db.execute('PRAGMA journal_mode=WAL')
            db.execute('''CREATE TABLE IF NOT EXISTS stickers (
                uid INTEGER NOT NULL, id TEXT NOT NULL, extension TEXT NOT NULL,
                width INTEGER NOT NULL, height INTEGER NOT NULL, size INTEGER NOT NULL,
                created INTEGER NOT NULL, content BLOB NOT NULL,
                PRIMARY KEY(uid,id))''')
            db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
            # UID namespaces are specific to one VC instance. Do not silently
            # reuse an existing library when pointed at a different upstream.
            previous = db.execute("SELECT value FROM settings WHERE key='vc_identity'").fetchone()
            if previous and previous[0] != self.public_url:
                raise ValueError('VC_PUBLIC_URL changed: use a separate data directory for another VC instance')
            db.execute("INSERT OR IGNORE INTO settings VALUES ('vc_identity',?)", (self.public_url,))

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.db_path, timeout=10)
        db.row_factory = sqlite3.Row
        try:
            with db:
                yield db
        finally:
            db.close()

    def authenticate(self, token):
        if not token or len(token) > 8192 or '\r' in token or '\n' in token:
            raise Failure(401, 'unauthorized')
        req = Request(self.upstream + '/api/user/me', headers={
            'X-API-Key': token, 'Referer': self.public_url,
            'Origin': self.public_url.rstrip('/'), 'Accept': 'application/json'})
        try:
            with self.opener.open(req, timeout=6) as response:
                data = response.read(65537)
                if len(data) > 65536:
                    raise Failure(502, 'invalid_vc_response')
            uid = json.loads(data)['uid']
            if type(uid) is not int or uid < 0:
                raise ValueError()
            return uid
        except HTTPError as e:
            raise Failure(401 if e.code in (401, 403) else 502,
                          'unauthorized' if e.code in (401, 403) else 'vc_unavailable') from None
        except (URLError, TimeoutError, OSError, ValueError, KeyError, TypeError):
            raise Failure(502, 'vc_unavailable') from None

    @staticmethod
    def metadata(row):
        return {key: row[key] for key in ('id', 'extension', 'width', 'height', 'size')}

    def list(self, uid):
        with self.connect() as db:
            rows = db.execute('SELECT id,extension,width,height,size FROM stickers WHERE uid=? ORDER BY created DESC,id', (uid,)).fetchall()
        return [self.metadata(row) for row in rows]

    def put(self, uid, key, content, width, height):
        if not content or len(content) > MAX_BYTES:
            raise Failure(413, 'image_too_large')
        if hashlib.sha256(content).hexdigest() != key:
            raise Failure(422, 'hash_mismatch')
        ext = extension(content)
        if not 0 < width <= 32768 or not 0 < height <= 32768:
            raise Failure(422, 'invalid_dimensions')
        with self.lock, self.connect() as db:
            existing = db.execute('SELECT 1 FROM stickers WHERE uid=? AND id=?', (uid, key)).fetchone()
            if not existing:
                count, total = db.execute('SELECT count(*),coalesce(sum(size),0) FROM stickers WHERE uid=?', (uid,)).fetchone()
                if count >= self.max_items or total + len(content) > self.quota_bytes:
                    raise Failure(409, 'sticker_quota_exceeded')
                db.execute('INSERT INTO stickers VALUES (?,?,?,?,?,?,?,?)',
                           (uid, key, ext, width, height, len(content), time.time_ns(), content))
        return {'id': key, 'extension': ext, 'width': width, 'height': height, 'size': len(content)}

    def get(self, uid, key):
        with self.connect() as db:
            row = db.execute('SELECT extension,content FROM stickers WHERE uid=? AND id=?', (uid, key)).fetchone()
        if row is None:
            raise Failure(404, 'not_found')
        return MIMES[row['extension']], row['content']

    def delete(self, uid, key):
        with self.lock, self.connect() as db:
            db.execute('DELETE FROM stickers WHERE uid=? AND id=?', (uid, key))


def handler_for(app):
    class Handler(BaseHTTPRequestHandler):
        # Close every connection, including rejected oversized uploads, so an
        # unread body can never be interpreted as another authenticated request.
        protocol_version = 'HTTP/1.0'
        server_version = SERVICE
        sys_version = ''

        def setup(self):
            super().setup()
            self.connection.settimeout(20)

        def log_message(self, *_):
            # Tokens, query parameters and private sticker IDs never enter logs.
            pass

        def reply(self, status, body, mime='application/json'):
            if not isinstance(body, bytes):
                body = json.dumps(body, separators=(',', ':')).encode()
            self.send_response(status)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'private, no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('X-Vocechat-Stickers', '1')
            if mime.startswith('image/'):
                self.send_header('Content-Disposition', 'attachment')
            self.end_headers()
            self.wfile.write(body)

        def run_request(self):
            self.connection.settimeout(20)
            try:
                parsed = urlsplit(self.path)
                path = parsed.path.rstrip('/')
                if parsed.query:
                    raise Failure(400, 'query_not_supported')
                if self.command == 'GET' and path == '/healthz':
                    self.reply(200, {'service': SERVICE, 'version': 1})
                    return
                parts = path.split('/')
                if path != '/v1/stickers' and not (len(parts) == 4 and parts[:3] == ['', 'v1', 'stickers'] and ID.fullmatch(parts[3])):
                    raise Failure(404, 'not_found')
                uid = app.authenticate(self.headers.get('X-API-Key'))
                if path == '/v1/stickers':
                    if self.command != 'GET':
                        raise Failure(405, 'method_not_allowed')
                    self.reply(200, {'service': SERVICE, 'version': 1, 'uid': uid, 'items': app.list(uid)})
                    return
                key = parts[3]
                if self.command == 'GET':
                    mime, content = app.get(uid, key)
                    self.reply(200, content, mime)
                elif self.command == 'DELETE':
                    app.delete(uid, key)
                    self.reply(200, {'deleted': True})
                elif self.command == 'PUT':
                    if self.headers.get('Transfer-Encoding') or len(self.headers.get_all('Content-Length', [])) != 1:
                        raise Failure(411, 'content_length_required')
                    try:
                        length = int(self.headers['Content-Length'])
                        width = int(self.headers.get('X-Sticker-Width', '0'))
                        height = int(self.headers.get('X-Sticker-Height', '0'))
                    except ValueError:
                        raise Failure(400, 'invalid_headers') from None
                    if not 0 < length <= MAX_BYTES:
                        raise Failure(413, 'image_too_large')
                    body = self.rfile.read(length)
                    if len(body) != length:
                        raise Failure(400, 'incomplete_body')
                    self.reply(200, app.put(uid, key, body, width, height))
                else:
                    raise Failure(405, 'method_not_allowed')
            except Failure as e:
                self.reply(e.status, {'error': e.code})
            except (BrokenPipeError, ConnectionResetError, TimeoutError):
                pass
            except Exception:
                self.reply(500, {'error': 'internal_error'})

        do_GET = do_PUT = do_DELETE = do_POST = do_PATCH = do_OPTIONS = run_request

    return Handler


class Server(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 32

    def __init__(self, address, handler):
        self.slots = threading.BoundedSemaphore(4)
        super().__init__(address, handler)

    def process_request(self, request, client_address):
        self.slots.acquire()
        try:
            super().process_request(request, client_address)
        except Exception:
            self.slots.release()
            raise

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self.slots.release()


def main():
    app = App(os.environ.get('DATA_DIR', '/data'),
              os.environ['VC_UPSTREAM'], os.environ['VC_PUBLIC_URL'],
              int(os.environ.get('MAX_ITEMS', '512')),
              int(os.environ.get('QUOTA_MIB', '256')) * 1024 * 1024)
    server = Server(('0.0.0.0', int(os.environ.get('PORT', '8080'))), handler_for(app))
    print('VoceChat sticker service v1 listening', flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()
