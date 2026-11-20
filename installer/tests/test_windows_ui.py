import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch
import app
import prepare_build

class WindowsActions(unittest.TestCase):
    def setUp(self):
        self.ui=app.App.__new__(app.App)
        self.ui.system='Windows';self.ui.windows_available=True
        self.ui.selected_game='/tmp/fake-game';self.ui.selected_experimental=False
        self.engine=Mock()
    def test_opt_in_required_before_engine_or_files(self):
        with patch('core.windows_engine') as load:
            with self.assertRaises(ValueError):self.ui.windows_install()
            load.assert_not_called()
    def test_restore_does_not_require_opt_in(self):
        with patch('core.windows_engine',return_value=self.engine),patch('core.game_closed') as closed:
            self.ui.windows_restore()
            game,callback=self.engine.uninstall.call_args.args
            self.assertTrue(callback());closed.assert_called_once_with(game)
    def test_install_callback_propagates_running_game(self):
        self.ui.selected_experimental=True
        def install(game,payload,manifest,callback):callback()
        self.engine.install.side_effect=install
        with patch('core.windows_engine',return_value=self.engine),patch('core.game_closed',side_effect=ValueError('running')):
            with self.assertRaisesRegex(ValueError,'running'):self.ui.windows_install()
    def test_absent_bundle_refused(self):
        self.ui.windows_available=False
        with self.assertRaises(ValueError):self.ui.windows_check()
    def test_malformed_bundle_refused(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d)/'traduction-windows').mkdir()
            with self.assertRaises((ValueError,OSError)):prepare_build.verify_windows(Path(d))
