"""Temporary-home regressions; never deploy or install plugins in the real HOME."""
import importlib.util
import fcntl
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('stow_safe', REPO / 'scripts/stow_safe.py')
safe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(safe)


class DotfilesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.home = self.root / 'home'
        self.home.mkdir()

    def package(self, package, relative, text='config\n'):
        path = self.repo / package / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def run_shell(self, shell, code, *args, **env):
        variables = dict(os.environ, HOME=str(self.home), XDG_CACHE_HOME=str(self.home / '.cache'))
        variables.update(env)
        return subprocess.run([shell, '-c', code, 'test', *map(str, args)],
                              cwd=self.root, env=variables, text=True, capture_output=True)

    def test_foreign_parent_rejected_before_any_backup(self):
        self.package('bash', '.bashrc')
        self.package('kitty', '.config/kitty/kitty.conf')
        (self.home / '.bashrc').write_text('original')
        external = self.root / 'external'
        external.mkdir()
        (self.home / '.config').symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(safe.DeploymentError, 'parent symlink'):
            safe.deploy(self.repo, self.home, ['bash', 'kitty'])
        self.assertEqual((self.home / '.bashrc').read_text(), 'original')
        self.assertFalse((self.home / '.dotfiles_backup').exists())

    def test_foreign_or_broken_leaf_links_are_preserved(self):
        self.package('bash', '.bashrc')
        target = self.home / '.bashrc'
        target.symlink_to(self.root / 'missing')
        with self.assertRaisesRegex(safe.DeploymentError, 'target symlink'):
            safe.deploy(self.repo, self.home, ['bash'])
        self.assertTrue(target.is_symlink())

    def test_duplicate_targets_and_parent_files_are_rejected(self):
        self.package('one', '.config/thing')
        self.package('two', '.config/thing')
        with self.assertRaisesRegex(safe.DeploymentError, 'Duplicate target'):
            safe.plan(self.repo, self.home, ['one', 'two'])
        (self.home / '.config').write_text('keep')
        with self.assertRaisesRegex(safe.DeploymentError, 'not a directory'):
            safe.plan(self.repo, self.home, ['one'])

    def test_backup_directory_symlink_is_rejected(self):
        self.package('bash', '.bashrc')
        (self.home / '.dotfiles_backup').symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(safe.DeploymentError, 'must not be linked'):
            safe.deploy(self.repo, self.home, ['bash'])

    def test_concurrent_deployment_is_rejected_without_moving_original(self):
        self.package('bash', '.bashrc')
        (self.home / '.bashrc').write_text('original')
        directory = self.home / '.dotfiles_backup'
        directory.mkdir(mode=0o700)
        with (directory / '.bootstrap.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaisesRegex(safe.DeploymentError, 'Another dotfiles'):
                safe.deploy(self.repo, self.home, ['bash'])
        self.assertEqual((self.home / '.bashrc').read_text(), 'original')

    def test_unique_backups_and_idempotent_stow(self):
        source = self.package('bash', '.bashrc')
        target = self.home / '.bashrc'
        target.write_text('first')
        first = safe.deploy(self.repo, self.home, ['bash'])
        self.assertTrue(target.samefile(source))
        self.assertEqual((first / '.bashrc').read_text(), 'first')
        self.assertIsNone(safe.deploy(self.repo, self.home, ['bash']))
        target.unlink()
        target.write_text('second')
        second = safe.deploy(self.repo, self.home, ['bash'])
        self.assertNotEqual(first, second)
        self.assertEqual((first / '.bashrc').read_text(), 'first')
        self.assertEqual((second / '.bashrc').read_text(), 'second')
        self.assertEqual(first.stat().st_mode & 0o777, 0o700)

    def test_stow_simulation_failure_restores_originals(self):
        self.package('bash', '.bashrc')
        (self.home / '.bashrc').write_text('original')
        with patch.object(safe.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'stow')):
            with self.assertRaises(subprocess.CalledProcessError):
                safe.deploy(self.repo, self.home, ['bash'])
        self.assertEqual((self.home / '.bashrc').read_text(), 'original')

    def test_move_failure_restores_prior_backups(self):
        self.package('bash', '.bashrc')
        self.package('zsh', '.zshrc')
        (self.home / '.bashrc').write_text('bash original')
        (self.home / '.zshrc').write_text('zsh original')
        move = shutil.move
        def fail_second(source, destination):
            if source == str(self.home / '.zshrc'):
                raise OSError('fixture move failure')
            return move(source, destination)
        with patch.object(safe.shutil, 'move', side_effect=fail_second):
            with self.assertRaises(OSError):
                safe.deploy(self.repo, self.home, ['bash', 'zsh'])
        self.assertEqual((self.home / '.bashrc').read_text(), 'bash original')
        self.assertEqual((self.home / '.zshrc').read_text(), 'zsh original')

    def test_owned_folded_directory_is_unfolded_without_moving_source(self):
        source = self.package('shell', '.config/shell/common.sh')
        (self.home / '.config').mkdir()
        (self.home / '.config/shell').symlink_to(
            os.path.relpath(source.parent, self.home / '.config'), target_is_directory=True)
        self.assertIsNone(safe.deploy(self.repo, self.home, ['shell']))
        self.assertEqual(source.read_text(), 'config\n')
        self.assertFalse((self.home / '.config/shell').is_symlink())
        self.assertTrue((self.home / '.config/shell/common.sh').is_symlink())

    def test_manifest_deploys_all_configs_but_no_support_directories(self):
        # Real resource files must not ignore .gitconfig or deploy scripts/tests.
        packages = (REPO / 'packages.txt').read_text().splitlines()
        safe.deploy(REPO, self.home, packages)
        self.assertTrue((self.home / '.gitconfig').is_symlink())
        self.assertTrue((self.home / '.config/shell/completion.zsh').is_symlink())
        self.assertFalse((self.home / 'tests').exists())
        self.assertFalse((self.home / 'scripts').exists())
        self.assertIsNone(safe.deploy(REPO, self.home, packages))

    def test_local_neovim_and_locale_after_path_setup(self):
        binary = self.home / '.local/bin/nvim'
        binary.parent.mkdir(parents=True)
        binary.write_text('#!/bin/sh\nexit 0\n')
        binary.chmod(0o755)
        env = dict(os.environ, HOME=str(self.home), PATH='/usr/bin:/bin', LANG='C')
        for key in ('EDITOR', 'VISUAL', 'MANPAGER', 'MANWIDTH'):
            env.pop(key, None)
        common = REPO / 'shell/.config/shell/common.sh'
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell):
                result = subprocess.run([shell, '-c', 'source "$1"; setup_editor; printf "%s|%s|%s" "$MANPAGER" "$EDITOR" "$LANG"', 'test', str(common)],
                                        env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, 'nvim +Man!|nvim|C')
        result = subprocess.run(['fish', '--no-config', '-c', 'source $argv[1]; printf "%s|%s|%s" "$MANPAGER" "$EDITOR" "$LANG"', str(REPO / 'fish/.config/fish/config.fish')],
                                env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'nvim +Man!|nvim|C')

    def test_editor_and_pager_preferences_are_preserved(self):
        result = self.run_shell('bash', 'source "$1"; setup_editor; printf "%s|%s|%s" "$EDITOR" "$PAGER" "$LANG"',
                                REPO / 'shell/.config/shell/common.sh', EDITOR='nano', PAGER='more', LANG='C')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'nano|more|C')

    def test_bash_and_zsh_detect_editor_after_mise_activation(self):
        safe.deploy(REPO, self.home, (REPO / 'packages.txt').read_text().splitlines())
        mise = self.home / '.local/bin/mise'
        mise.parent.mkdir(parents=True)
        mise.write_text('#!/bin/sh\nprintf \'export PATH="%s/managed/bin:$PATH"\\n\' "$HOME"\n')
        mise.chmod(0o755)
        nvim = self.home / 'managed/bin/nvim'
        nvim.parent.mkdir(parents=True)
        nvim.write_text('#!/bin/sh\nexit 0\n')
        nvim.chmod(0o755)
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell):
                env = dict(os.environ, HOME=str(self.home), PATH='/usr/bin:/bin',
                           XDG_CONFIG_HOME=str(self.home / '.config'),
                           XDG_CACHE_HOME=str(self.home / '.cache'),
                           XDG_DATA_HOME=str(self.home / '.local/share'), TMUX='fixture', TERM='xterm')
                for key in ('EDITOR', 'VISUAL', 'MANPAGER', 'MANWIDTH'):
                    env.pop(key, None)
                options = ['--noprofile', '--norc', '-ic'] if shell == 'bash' else ['-f', '-ic']
                code = '''
command() {
  if [[ $1 == -v ]]; then
    case $2 in starship|zoxide|fzf|gocomplete) return 1;; esac
  fi
  builtin command "$@"
}
source "$1"
printf '%s\n' "$MANPAGER"
command -v nvim
'''
                result = subprocess.run([shell, *options, code, 'test', str(self.home / f'.{shell}rc')],
                                        env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), ['nvim +Man!', str(nvim)])

    def test_bash_apt_completion(self):
        if not Path('/usr/share/bash-completion/completions/apt').exists():
            self.skipTest('bash-completion is not installed')
        safe.deploy(REPO, self.home, (REPO / 'packages.txt').read_text().splitlines())
        result = subprocess.run(['bash', '--noprofile', '--norc', '-ic', '''
command() {
  if [[ $1 == -v ]]; then
    case $2 in mise|starship|zoxide|fzf|gocomplete) return 1;; esac
  fi
  builtin command "$@"
}
source "$HOME/.bashrc"
_completion_loader apt
COMP_WORDS=(apt ins); COMP_CWORD=1; COMP_LINE="apt ins"; COMP_POINT=${#COMP_LINE}
_apt
printf '%s\n' "${COMPREPLY[@]}"
'''], env=dict(os.environ, HOME=str(self.home), TMUX='fixture', TERM='xterm'),
            text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('install', result.stdout.splitlines())

    def completion_cache(self, age=None, insecure=False):
        version = subprocess.check_output(['zsh', '-fc', 'print $ZSH_VERSION'], text=True).strip()
        cache = self.home / '.cache/zsh'
        cache.mkdir(parents=True)
        dump = cache / f'zcompdump-{version}'
        if age is not None:
            dump.write_text('fixture cache\n')
            stamp = time.time() - age * 3600
            os.utime(dump, (stamp, stamp))
        return self.run_shell('zsh', '''
source "$1"
autoload() { :; }
insecure="$2"
compaudit() { return "$insecure"; }
compinit() { print -r -- "$*"; }
dotfiles_init_completion
''', REPO / 'shell/.config/shell/completion.zsh', int(insecure))

    def test_fresh_completion_cache_is_reused(self):
        result = self.completion_cache(1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('-C -d '), result.stdout)

    def test_missing_completion_cache_is_initialized(self):
        result = self.completion_cache()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('-i -d '), result.stdout)

    def test_stale_completion_cache_is_refreshed(self):
        result = self.completion_cache(48)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('-i -d '), result.stdout)

    def test_insecure_completions_never_use_unaudited_cache(self):
        result = self.completion_cache(1, insecure=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('-i -d '), result.stdout)

    def test_fish_uses_builtin_go_completion(self):
        code = 'source $argv[1]; complete -C "go bu"'
        result = subprocess.run(['fish', '--interactive', '-c', code,
                                 str(REPO / 'fish/.config/fish/config.fish')],
                                env=dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'), XDG_DATA_HOME=str(self.home / '.local/share'), XDG_CACHE_HOME=str(self.home / '.cache'), TMUX='fixture', TERM='xterm'),
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(any(line.startswith('build\t') for line in result.stdout.splitlines()), result.stdout)

    def tpm(self, *, origin='https://github.com/tmux-plugins/tpm', dirty=False, plugin_status=0):
        directory = self.home / '.local/share/tmux/plugins/tpm'
        (directory / '.git').mkdir(parents=True)
        plugin = directory / 'bin/install_plugins'
        plugin.parent.mkdir()
        plugin.write_text(f'#!/bin/sh\necho plugins-ran\nexit {plugin_status}\n')
        plugin.chmod(0o755)
        return self.run_shell('bash', '''
set -euo pipefail
source "$1"
tmux() { :; }
git() {
  shift 2
  case "$1" in
    remote) printf '%s' "$FIXTURE_ORIGIN";;
    status) printf '%s' "$FIXTURE_DIRTY";;
    cat-file|checkout) return 0;;
    *) return 99;;
  esac
}
setup_tmux
''', REPO / 'bootstrap.sh', FIXTURE_ORIGIN=origin, FIXTURE_DIRTY='changed' if dirty else '')

    def test_tpm_plugin_failure_is_reported(self):
        result = self.tpm(plugin_status=46)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('plugins-ran', result.stdout)
        self.assertIn('installation failed', result.stderr)

    def test_tpm_foreign_origin_is_rejected_before_execution(self):
        result = self.tpm(origin='https://example.invalid/foreign')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('plugins-ran', result.stdout)
        self.assertIn('Unexpected TPM origin', result.stderr)

    def test_tpm_dirty_checkout_is_preserved(self):
        result = self.tpm(dirty=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('plugins-ran', result.stdout)
        self.assertIn('local changes', result.stderr)

    def test_tpm_explicit_skip_does_not_clone(self):
        result = self.run_shell('bash', 'source "$1"; setup_tmux', REPO / 'bootstrap.sh', DOTFILES_SKIP_TMUX='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.home / '.local/share/tmux/plugins').exists())


if __name__ == '__main__':
    unittest.main()
