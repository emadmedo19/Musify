#!/usr/bin/env python3
"""Privately sign a built APK and enforce the fork's fixed signing identity."""
import base64
import glob
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


def run(command, binary=False):
    result = subprocess.run(command, capture_output=True, text=not binary)
    if result.returncode:
        raise RuntimeError(f'{Path(command[0]).name} failed with code {result.returncode}; no secret values were logged')
    return result.stdout


def main():
    if len(sys.argv) != 3:
        raise RuntimeError('Expected input APK and output directory')
    source = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()
    if not source.is_file():
        raise RuntimeError('Input APK is missing')
    key_data = os.environ.get('KEYSTORE_BASE64', '')
    if not key_data or not os.environ.get('KEYSTORE_PASSWORD'):
        raise RuntimeError('Private signing secrets are missing')
    expected = Path('android/fork-signing-certificate.sha256').read_text().strip().lower()
    if not re.fullmatch(r'[a-f0-9]{64}', expected):
        raise RuntimeError('Invalid public signing fingerprint')
    tools = glob.glob(str(Path(os.environ.get('ANDROID_HOME', '/workspace/android-sdk')) / 'build-tools/*/apksigner'))
    signer = os.environ.get('APKSIGNER') or shutil.which('apksigner')
    if not signer and tools:
        signer = max(tools, key=lambda p: tuple(map(int, re.findall(r'\d+', Path(p).parent.name))))
    if not signer:
        raise RuntimeError('Android apksigner is unavailable')
    output.mkdir(parents=True, exist_ok=True)
    apk = output / 'Musify-Arabic.apk'
    if source == apk:
        raise RuntimeError('Input and output APK paths must differ')
    with tempfile.TemporaryDirectory(prefix='musify-private-signing-') as temp:
        key = Path(temp) / 'release.p12'
        key.write_bytes(base64.b64decode(''.join(key_data.split()), validate=True))
        key.chmod(0o600)
        public_der = run(['keytool', '-exportcert', '-alias', 'musify-fork', '-keystore', str(key), '-storepass:env', 'KEYSTORE_PASSWORD'], binary=True)
        if hashlib.sha256(public_der).hexdigest() != expected:
            raise RuntimeError('The supplied key does not match the permanent fork certificate')
        run([signer, 'sign', '--ks', str(key), '--ks-key-alias', 'musify-fork', '--ks-pass', 'env:KEYSTORE_PASSWORD', '--v4-signing-enabled', 'false', '--out', str(apk), str(source)])
    verification = run([signer, 'verify', '--print-certs', str(apk)])
    print(verification)  # Public certificate diagnostics; contains no private key.
    match = re.search(r'certificate SHA-256 digest:\s*([a-fA-F0-9]{64})', verification)
    if not match or match.group(1).lower() != expected:
        raise RuntimeError('Final APK signing identity verification failed')
    badging = run([str(Path(signer).with_name('aapt')), 'dump', 'badging', str(apk)])
    version = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+', Path('pubspec.yaml').read_text(), re.M).group(1)
    if "package: name='com.emadmedo19.musify'" not in badging or f"versionName='{version}'" not in badging:
        raise RuntimeError('APK identity/version does not match the signed fork')
    digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
    (output / 'SHA256SUMS.txt').write_text(f'{digest}  Musify-Arabic.apk\n')
    print(json.dumps({'version': version, 'package': 'com.emadmedo19.musify', 'certificate': expected, 'sha256': digest, 'bytes': apk.stat().st_size}))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'Release signing failed: {error}', file=sys.stderr)
        sys.exit(1)
