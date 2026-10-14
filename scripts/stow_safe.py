#!/usr/bin/env python3
"""Validate conflicts, back up originals, and invoke GNU Stow."""
import fcntl
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


class DeploymentError(Exception):
    pass


def exists(path):
    return os.path.lexists(path)


def package_files(repo, packages):
    files = {}
    for name in packages:
        if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_-]*', name):
            raise DeploymentError(f'Invalid package name: {name}')
        package = repo / name
        if not package.is_dir() or package.is_symlink():
            raise DeploymentError(f'Missing or linked package directory: {package}')
        for directory, dirs, names in os.walk(package, followlinks=False):
            dirs[:] = sorted(d for d in dirs if d != '.git')
            for child in dirs:
                if (Path(directory) / child).is_symlink():
                    raise DeploymentError(f'Linked source directory: {Path(directory) / child}')
            for child in sorted(names):
                if child in ('.DS_Store', 'README.md'):
                    continue
                source = Path(directory) / child
                if not source.is_file() or not source.resolve().is_relative_to(repo):
                    raise DeploymentError(f'Unsupported source file: {source}')
                relative = source.relative_to(package)
                if relative in files:
                    raise DeploymentError(f'Duplicate target across packages: {relative}')
                files[relative] = source
    return files


def plan(repo, home, packages):
    files = package_files(repo, packages)
    conflicts = []
    for relative, source in files.items():
        # Old Stow directory links into this checkout may be unfolded. Refuse
        # foreign parent links before any original file is moved.
        for parent in reversed(relative.parents):
            if parent == Path('.'):
                continue
            target = home / parent
            if target.is_symlink():
                resolved = target.resolve()
                if not resolved.is_relative_to(repo) or not resolved.is_dir():
                    raise DeploymentError(f'Foreign or broken parent symlink: {target}')
            elif exists(target) and not target.is_dir():
                raise DeploymentError(f'Target parent is not a directory: {target}')
        target = home / relative
        if not exists(target):
            continue
        if target.exists() and target.samefile(source):
            continue
        if target.is_symlink():
            raise DeploymentError(f'Foreign or broken target symlink: {target}')
        if target.resolve().is_relative_to(repo):
            raise DeploymentError(f'Conflicting file in a folded package: {target}')
        if not target.is_file():
            raise DeploymentError(f'Target is not a regular file: {target}')
        conflicts.append(relative)
    return conflicts


def restore(home, backup, moved):
    for relative in reversed(moved):
        target = home / relative
        if exists(target):
            print(f'Restore blocked by existing target: {target}', file=sys.stderr)
            continue
        try:
            shutil.move(str(backup / relative), str(target))
        except OSError as error:
            print(f'Could not restore {target}: {error}', file=sys.stderr)


def deploy(repo, home, packages):
    repo, home = Path(repo).resolve(), Path(home).resolve()
    if not home.is_dir() or home == Path('/') or home.is_relative_to(repo):
        raise DeploymentError('HOME must be an existing directory outside the checkout.')
    plan(repo, home, packages)
    backup_root = home / '.dotfiles_backup'
    if backup_root.is_symlink():
        raise DeploymentError(f'Backup directory must not be linked: {backup_root}')
    backup_root.mkdir(mode=0o700, exist_ok=True)
    if backup_root.stat().st_uid != os.geteuid() or backup_root.stat().st_mode & 0o022:
        raise DeploymentError(f'Unsafe ownership or permissions on: {backup_root}')
    descriptor = os.open(backup_root / '.bootstrap.lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise DeploymentError('Another dotfiles deployment is running.') from error
        conflicts = plan(repo, home, packages)
        backup = Path(tempfile.mkdtemp(prefix='install-', dir=backup_root)) if conflicts else None
        if backup:
            print(f'Backup directory: {backup}', flush=True)
        moved = []
        command = ['stow', '--dir', str(repo), '--target', str(home), '--no-folding', '-R', *packages]
        try:
            for relative in conflicts:
                destination = backup / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                if exists(destination):
                    raise DeploymentError(f'Refusing to replace backup: {destination}')
                shutil.move(str(home / relative), str(destination))
                moved.append(relative)
            subprocess.run([*command, '--simulate'], cwd=repo, check=True)
        except (OSError, subprocess.CalledProcessError, DeploymentError):
            if backup:
                restore(home, backup, moved)
            raise
        # A real Stow failure may leave new links. Retain backups for inspection,
        # rather than overwriting those links with an automatic rollback.
        subprocess.run(command, cwd=repo, check=True)
        return backup


if __name__ == '__main__':
    try:
        deploy(sys.argv[1], sys.argv[2], sys.argv[3:])
    except (DeploymentError, OSError, subprocess.CalledProcessError) as error:
        print(f'Dotfiles deployment failed: {error}', file=sys.stderr)
        sys.exit(1)
