import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parent
DOCKER = """#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['DOCKER_CALLS'], 'a') as stream:
    stream.write(json.dumps(args) + '\\n')
networks = json.loads(os.environ['DOCKER_NETWORKS'])
if args and args[0] == 'inspect' and args[-1] in networks:
    if '--format' in args:
        print('\\n'.join(networks[args[-1]]))
    sys.exit(0)
print('Unexpected Docker mutation or request', file=sys.stderr)
sys.exit(99)
"""
STAT = """#!/usr/bin/env python3
import os, sys
assert sys.argv[1:3] == ['-c', '%u']
print(os.stat(sys.argv[3]).st_uid)
"""


class PrepareTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        shutil.copy2(SOURCE / 'prepare.sh', self.directory / 'prepare.sh')
        self.bin = self.directory / 'bin'
        self.bin.mkdir()
        for name, source in [('docker', DOCKER), ('stat', STAT)]:
            path = self.bin / name
            path.write_text(source)
            path.chmod(0o755)
        self.calls = self.directory / 'calls.jsonl'
        self.environment = dict(os.environ)
        self.environment.update(
            PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
            DOCKER_CALLS=str(self.calls),
            DOCKER_NETWORKS=json.dumps({
                'vocechat-1': ['nas-services'],
                'nginx-proxy-manager': ['nas-services', 'old-sticker-net'],
            }),
        )
        self.environment.pop('SUDO_UID', None)
        self.environment.pop('SUDO_GID', None)

    def run_prepare(self, *args):
        return subprocess.run(
            ['sh', 'prepare.sh', *args], cwd=self.directory,
            env=self.environment, capture_output=True, text=True, timeout=10)

    def network(self, vc, npm):
        self.environment['DOCKER_NETWORKS'] = json.dumps({
            'vocechat-1': vc, 'nginx-proxy-manager': npm})

    def test_first_deploy_reuses_network_without_mutating_other_containers(self):
        result = self.run_prepare('https://chat.example.com:36')
        self.assertEqual(result.returncode, 0, result.stderr)
        env = (self.directory / '.env').read_text()
        self.assertIn('VC_DOCKER_NETWORK=nas-services', env)
        self.assertIn('VC_PUBLIC_URL=https://chat.example.com:36', env)
        calls = [json.loads(row) for row in self.calls.read_text().splitlines()]
        self.assertTrue(all(row[0] == 'inspect' for row in calls))

    def test_repeat_preserves_existing_url_identity_and_stickers(self):
        first = self.run_prepare('https://chat.example.com:36')
        self.assertEqual(first.returncode, 0, first.stderr)
        payload = self.directory / 'data' / 'existing.gif'
        payload.write_bytes(b'unchanged collection')
        before = (self.directory / '.env').read_bytes()
        result = self.run_prepare('https://other.example.com')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.directory / '.env').read_bytes(), before)
        self.assertEqual(payload.read_bytes(), b'unchanged collection')

    def test_legacy_env_gains_persistent_network(self):
        env = self.directory / '.env'
        env.write_text(
            'VC_PUBLIC_URL=https://chat.example.com\n'
            f'PUID={os.getuid()}\nPGID={os.getgid()}\n'
            'VC_UPSTREAM=http://custom-vc:3100\n')
        result = self.run_prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('VC_DOCKER_NETWORK=nas-services', env.read_text())
        self.assertIn('VC_UPSTREAM=http://custom-vc:3100', env.read_text())

    def test_prefers_existing_nas_network_over_other_common_networks(self):
        self.network(['other-network', 'nas-services'],
                     ['other-network', 'nas-services'])
        result = self.run_prepare('https://chat.example.com')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('VC_DOCKER_NETWORK=nas-services',
                      (self.directory / '.env').read_text())

    def test_detects_another_common_custom_network(self):
        self.network(['shared-vc'], ['shared-vc'])
        result = self.run_prepare('https://chat.example.com')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('VC_DOCKER_NETWORK=shared-vc',
                      (self.directory / '.env').read_text())

    def test_rejects_disjoint_networks_without_connecting_containers(self):
        self.network(['vc-only'], ['npm-only'])
        result = self.run_prepare('https://chat.example.com')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('VC_DOCKER_NETWORK=',
                         (self.directory / '.env').read_text())

    def test_rejects_default_bridge_without_container_dns(self):
        self.network(['bridge'], ['bridge'])
        result = self.run_prepare('https://chat.example.com')
        self.assertNotEqual(result.returncode, 0)

    def test_explicit_network_must_be_shared(self):
        result = self.run_prepare('https://chat.example.com', 'npm-only')
        self.assertNotEqual(result.returncode, 0)

    def test_multiple_runs_follow_persisted_network_after_recreation(self):
        first = self.run_prepare('https://chat.example.com')
        self.assertEqual(first.returncode, 0, first.stderr)
        self.network(['nas-services'], ['nas-services'])
        result = self.run_prepare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.directory / '.env').read_text().count(
            'VC_DOCKER_NETWORK='), 1)

    def test_rejects_symlinked_data_directory(self):
        real = self.directory / 'real-data'
        real.mkdir()
        (self.directory / 'data').symlink_to(real)
        result = self.run_prepare('https://chat.example.com')
        self.assertNotEqual(result.returncode, 0)

    def test_rejects_api_url(self):
        result = self.run_prepare('https://chat.example.com/api')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.directory / '.env').exists())


if __name__ == '__main__':
    unittest.main()
