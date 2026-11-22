import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock,patch
import navigation_bridge as bridge

class NavigationBridge(unittest.TestCase):
    def test_windows_opt_in_precedes_all_context_access(self):
        with patch.object(bridge,'context') as context:
            with self.assertRaisesRegex(ValueError,'experimental'):
                bridge.run('.', 'Windows','game','','install',Mock())
            context.assert_not_called()

    def test_restore_needs_no_experimental_opt_in(self):
        engine=Mock();closed=Mock()
        with patch.object(bridge,'context',return_value=(engine,Path('/game'),Path('/hack'),'windows')):
            bridge.run('.', 'Windows','game','','restore',closed)
        self.assertIs(engine.uninstall.call_args.kwargs['game_closed'],closed)
        engine.install.assert_not_called()

    def test_running_game_check_propagates(self):
        engine=Mock();closed=Mock(side_effect=ValueError('running'))
        engine.install.side_effect=lambda *a,**kw:kw['game_closed'](a[0])
        with patch.object(bridge,'context',return_value=(engine,Path('/game'),Path('/hack'),'linux')):
            with self.assertRaisesRegex(ValueError,'running'):
                bridge.run('.', 'Linux','game','','install',closed)

    def test_empty_game_refused(self):
        with self.assertRaisesRegex(ValueError,'game folder'):bridge.context('.', 'Linux','')

    def test_platform_specific_discovery_ignores_stale_windows_files(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);game=root/'Dwarf Fortress';(game/'hack').mkdir(parents=True)
            (game/'hack/dfhack.dll').write_bytes(b'stale')
            hack=root/'DFHack/hack';hack.mkdir(parents=True);(hack/'libdfhack.so').write_bytes(b'fixture')
            bundle=Path(__file__).resolve().parents[1]
            _,selected_game,selected_hack,platform=bridge.context(bundle,'Linux',str(game))
            self.assertEqual(selected_hack,hack.resolve());self.assertEqual(platform,'linux')

    def test_check_is_read_only(self):
        engine=Mock();engine.inspect.return_value={'payload':{'file':b'fixture'}};closed=Mock()
        with patch.object(bridge,'context',return_value=(engine,Path('/game'),Path('/hack'),'linux')):
            self.assertIn('No game files were changed',bridge.run('.', 'Linux','game','','check',closed))
        closed.assert_not_called();engine.install.assert_not_called();engine.uninstall.assert_not_called()
