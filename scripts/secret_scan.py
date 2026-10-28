#!/usr/bin/env python3
"""Fail if tracked files contain credentials or private network details.

This repository is public. Findings report the file, line and kind only, never the
matched text. A line that is a deliberate false positive can carry the marker
`secret-scan: allow`.
"""
import re
from pathlib import Path
import subprocess
import sys

ALLOW_MARKER = 'secret-scan: allow'

CONTENT_PATTERNS = {
    'private key': re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'GitHub token': re.compile(r'\b(ghp|gho|ghu|ghs|ghr|github_pat)_[A-Za-z0-9_]{20,}'),
    'API secret key': re.compile(r'\bsk-[A-Za-z0-9_-]{20,}'),
    'AWS access key': re.compile(r'\b(AKIA|ASIA)[0-9A-Z]{16}\b'),
    'Google API key': re.compile(r'\bAIza[0-9A-Za-z_-]{35}\b'),
    'Slack token': re.compile(r'\bxox[abprs]-[A-Za-z0-9-]{10,}'),
    'assigned secret': re.compile(
        r'(?i)\b(api[_-]?key|secret|token|password|passwd|client[_-]?secret)\b["\']?\s*[:=]\s*'
        r'["\']?[A-Za-z0-9_\-+/=.]{12,}'),
    'URL with credentials': re.compile(r'\b[a-z][a-z0-9+.-]*://[^/\s:@]+:[^/\s@]+@'),
    'private IPv4 address': re.compile(
        r'\b(10\.\d{1,3}|192\.168|172\.(1[6-9]|2\d|3[01]))\.\d{1,3}\.\d{1,3}\b'),
    'Tailscale hostname': re.compile(r'\b[a-z0-9-]+\.[a-z0-9-]+\.ts\.net\b', re.I),
}

FILENAME_PATTERNS = {
    'environment file': re.compile(r'(^|/)\.env(\.[^/]+)?$'),
    'credential store': re.compile(r'(^|/)(\.git-credentials|\.netrc|\.pgpass)$'),
    'SSH private key': re.compile(r'(^|/)id_(rsa|dsa|ecdsa|ed25519)$'),
    'key or certificate bundle': re.compile(r'\.(pem|key|p12|pfx)$'),
}


def scan_text(name, text):
    findings = []
    for kind, pattern in FILENAME_PATTERNS.items():
        if pattern.search(name):
            findings.append((name, 0, kind))
    for number, line in enumerate(text.splitlines(), 1):
        if ALLOW_MARKER in line:
            continue
        for kind, pattern in CONTENT_PATTERNS.items():
            if pattern.search(line):
                findings.append((name, number, kind))
    return findings


def scan_repository(repo):
    names = subprocess.run(['git', 'ls-files', '-z'], cwd=repo, check=True,
                           capture_output=True).stdout.decode().split('\0')
    findings = []
    for name in filter(None, names):
        path = Path(repo) / name
        if path.is_symlink() or not path.is_file():
            continue
        data = path.read_bytes()
        if b'\0' in data:
            continue
        findings.extend(scan_text(name, data.decode(errors='replace')))
    return findings


if __name__ == '__main__':
    results = scan_repository(sys.argv[1] if len(sys.argv) > 1 else '.')
    for name, number, kind in results:
        location = name if number == 0 else f'{name}:{number}'
        print(f'Possible {kind}: {location}', file=sys.stderr)
    if results:
        print('Secret scan failed: remove the value, or mark a deliberate false positive '
              f'with "{ALLOW_MARKER}".', file=sys.stderr)
        sys.exit(1)
    print('Secret scan passed: no credentials or private network details in tracked files.')
