"""Graphical PGM assistant. Build with PyInstaller; no subprocess or elevated rights."""
import contextlib
import io
import os
from pathlib import Path
import platform
import queue
import sys
import threading
import webbrowser
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import core
import pack
import navigation_bridge
import animations_installer

ROOT = Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parent))


class App:
    def __init__(self, window):
        self.window = window
        window.title('PGM — Installation and updates')
        window.geometry('900x750')
        window.minsize(860, 700)
        self.events = queue.Queue()
        self.busy = False
        self.asset = None
        self.downloaded = None
        self.buttons = []
        self.system = platform.system()
        self.windows_available = (ROOT / 'traduction-windows/installer.py').is_file()
        self.experimental = tk.BooleanVar(value=False)
        self.navigation_experimental = tk.BooleanVar(value=False)
        self.navigation_window = None
        self.animations_window = None
        box = ttk.Frame(window, padding=22)
        box.pack(fill='both', expand=True)
        ttk.Label(box, text='PGM · Starter Quest Mods', font=('', 20, 'bold')).pack(anchor='w')
        ttk.Label(box, text=f'Assistant {core.VERSION} · content {core.PAYLOAD_VERSION} · game 53.17 · DFHack required').pack(anchor='w', pady=(2, 14))
        self.game = tk.StringVar(value=str(next(iter(core.game_candidates()), '')))
        self.hack = tk.StringVar()
        self.workshop = tk.StringVar()
        self.mods = tk.StringVar()
        self.row(box, 'Dwarf Fortress folder', self.game)
        self.row(box, 'DFHack folder (optional if detected)', self.hack)
        self.row(box, 'Workshop content/975370 folder (optional if detected)', self.workshop)
        self.row(box, 'Local mods folder (optional if detected)', self.mods)
        note = ('Native Linux: install the French translation or restore the original files.'
                if self.system == 'Linux' else
                ('Windows: modpack setup and optional experimental PGM French translation (tested under Proton; native Windows gameplay unverified).'
                 if self.windows_available else 'Windows: modpack setup available. PGM French translation is not included in this build.'))
        ttk.Label(box, text=note, wraplength=700).pack(anchor='w', pady=10)
        actions = ttk.Frame(box)
        actions.pack(fill='x')
        for label, action in [('Check files', self.check), ('Install / update', self.install),
                              ('Remove translation', self.uninstall)]:
            self.button(actions, label, lambda f=action: self.run(f), linux=True)
        if self.system == 'Windows' and self.windows_available:
            ttk.Checkbutton(box, text='Enable experimental Windows French translation (tested under Proton; native Windows gameplay unverified)', variable=self.experimental).pack(anchor='w')
            win_actions = ttk.Frame(box)
            win_actions.pack(fill='x', pady=8)
            for label, action in [('Check Windows files', self.windows_check), ('Install experimental translation', self.windows_install), ('Restore Windows files', self.windows_restore)]:
                self.button(win_actions, label, lambda f=action: self.run(f))
        presets = ttk.Frame(box)
        presets.pack(fill='x', pady=(8, 0))
        self.button(presets, 'Install modpack presets', lambda: self.run(self.presets))
        self.button(presets, 'Restore previous presets', lambda: self.run(self.restore_presets))
        extras = ttk.Frame(box)
        extras.pack(fill='x', pady=8)
        self.button(extras, 'Prepare modpack variants', lambda: self.run(self.variants))
        self.button(extras, 'Check for updates', lambda: self.run(self.updates))
        self.button(extras, 'Download update', self.get_update)
        self.button(extras, 'Open download folder', self.open_download)
        self.output = tk.Text(box, height=6, wrap='word', state='disabled')
        self.output.pack(fill='both', expand=True, pady=8)
        bottom = ttk.Frame(box)
        bottom.pack(fill='x')
        ttk.Button(bottom, text='Installation guide', command=self.guide).pack(side='left')
        ttk.Button(bottom, text='Save report', command=self.report).pack(side='right')
        self.button(bottom, 'World map navigation…', self.navigation_dialog)
        self.button(bottom, 'Animations & speed…', self.animations_dialog)
        window.protocol('WM_DELETE_WINDOW', self.close)
        self.log('Close the game before making changes. Modified local files are protected.\n'
                 'To update: download and open the new installer, select your game folder, then choose Install / update.\n'
                 'Steam updates Workshop mods. This installer manages the additional files.\n')
        window.after(100, self.poll)

    def row(self, parent, title, variable):
        ttk.Label(parent, text=title).pack(anchor='w')
        row = ttk.Frame(parent)
        row.pack(fill='x', pady=(3, 9))
        ttk.Entry(row, textvariable=variable).pack(side='left', fill='x', expand=True)
        def choose():
            folder = filedialog.askdirectory()
            if folder:
                variable.set(folder)
        ttk.Button(row, text='Browse…', command=choose).pack(side='right', padx=(8, 0))

    def button(self, parent, label, action, linux=False):
        button = ttk.Button(parent, text=label, command=action)
        button.pack(side='left', padx=(0, 7))
        allowed = not linux or self.system == 'Linux'
        if not allowed:
            button.state(['disabled'])
        self.buttons.append((button, allowed))

    def log(self, text):
        self.output.configure(state='normal')
        self.output.insert('end', text + '\n')
        self.output.see('end')
        self.output.configure(state='disabled')

    def run(self, action):
        if self.busy:
            return
        # Tk values must be read on the UI thread.
        self.selected_experimental = self.experimental.get()
        self.selected_navigation_experimental = self.navigation_experimental.get()
        self.selected_game = self.game.get()
        self.selected_hack = self.hack.get()
        self.selected_workshop = self.workshop.get()
        self.selected_mods = self.mods.get()
        self.busy = True
        for button, _ in self.buttons:
            button.state(['disabled'])
        def work():
            stream = io.StringIO()
            try:
                with contextlib.redirect_stdout(stream):
                    result = action()
                self.events.put(stream.getvalue() + str(result or 'Operation completed.'))
            except Exception as error:
                self.events.put(stream.getvalue() + 'Operation stopped: ' + str(error))
            finally:
                self.events.put(None)
        threading.Thread(target=work, daemon=True).start()

    def poll(self):
        try:
            while True:
                event = self.events.get_nowait()
                if event is None:
                    self.busy = False
                    for button, allowed in self.buttons:
                        if allowed:
                            button.state(['!disabled'])
                else:
                    self.log(event)
        except queue.Empty:
            pass
        self.window.after(100, self.poll)

    def navigation_dialog(self):
        if self.navigation_window and self.navigation_window.winfo_exists():
            self.navigation_window.deiconify();self.navigation_window.lift();return
        panel = tk.Toplevel(self.window)
        self.navigation_window = panel
        panel.title('PGM — World map navigation')
        panel.geometry('700x300');panel.minsize(680,280)
        panel.protocol('WM_DELETE_WINDOW',panel.withdraw)
        box=ttk.Frame(panel,padding=20);box.pack(fill='both',expand=True)
        ttk.Label(box,text='Optional world map zoom and pan',font=('',15,'bold')).pack(anchor='w')
        ttk.Label(box,text='Use the mouse wheel to zoom and drag with the middle mouse button to pan. '
                  'Left-click selection stays enabled. DFHack is required. This option is independent of the French translation and modpack presets.',wraplength=640).pack(anchor='w',pady=12)
        if self.system=='Windows':
            ttk.Checkbutton(box,text='Enable experimental Windows navigation (tested under Proton only)',variable=self.navigation_experimental).pack(anchor='w',pady=8)
        ttk.Label(box,text='Close the game first. Use the game and DFHack folders selected in the main window. '
                  'Only the exact tested game/DFHack files are accepted.',wraplength=640).pack(anchor='w',pady=8)
        row=ttk.Frame(box);row.pack(fill='x',pady=8)
        for label,action in [('Check before install','check'),('Install navigation','install'),('Restore previous files','restore')]:
            self.button(row,label,lambda action=action:self.run(lambda:self.navigation(action)))

    def animations_dialog(self):
        if self.animations_window and self.animations_window.winfo_exists():
            self.animations_window.deiconify();self.animations_window.lift();return
        panel = tk.Toplevel(self.window)
        self.animations_window = panel
        panel.title('PGM — Animations & speed')
        panel.geometry('700x280');panel.minsize(680,260)
        panel.protocol('WM_DELETE_WINDOW',panel.withdraw)
        box=ttk.Frame(panel,padding=20);box.pack(fill='both',expand=True)
        ttk.Label(box,text='Optional animations and speed controls',font=('',15,'bold')).pack(anchor='w')
        ttk.Label(box,text='Smooth dwarf walking, work gestures (mining, felling, building), speed buttons and an FPS counter. '
                  'DFHack is required. Turn gestures off in game with: pgm-motion work off.',wraplength=640).pack(anchor='w',pady=12)
        ttk.Label(box,text='Close the game first. Uses the game and DFHack folders selected in the main window; replaced files are backed up.',wraplength=640).pack(anchor='w',pady=8)
        row=ttk.Frame(box);row.pack(fill='x',pady=8)
        for label,action in [('Check before install','check'),('Install animations','install'),('Restore previous files','restore')]:
            self.button(row,label,lambda action=action:self.run(lambda:self.animations(action)))

    def animations(self,action):
        game,hack=self.selected_game,self.selected_hack
        if action=='check':
            result=animations_installer.check(game,hack,self.system)
            return '\n'.join(f'{k}: {v}' for k,v in sorted(result.items()))
        if action=='install':
            done=animations_installer.install(game,hack,self.system,core.game_closed)
            return 'Animations installed (%d files). Start a fortress with DFHack.' % len(done)
        done=animations_installer.uninstall(game,hack,core.game_closed)
        return 'Previous files restored (%d).' % len(done)

    def navigation(self,action):
        return navigation_bridge.run(ROOT,self.system,self.selected_game,self.selected_hack,action,
                                     core.game_closed,self.selected_navigation_experimental)

    def engine(self):
        if self.system != 'Linux':
            raise ValueError('Native Windows translation still needs validation.')
        if not self.selected_game:
            raise ValueError('Select your game folder.')
        if os.geteuid() == 0:
            raise ValueError('Run PGM with your normal account, without sudo.')
        return core.linux_engine(ROOT), Path(self.selected_game).expanduser().resolve(), (
            Path(self.selected_hack).expanduser().resolve() if self.selected_hack else None)

    def check(self):
        engine, game, hack = self.engine()
        if (game / engine.STATE_DIR / 'state.json').exists():
            engine.make_plan_without_init(game, hack)
        else:
            engine.make_plan(game, hack)
        return 'Game and translation checked. No game files were changed.'

    def mutate(self, remove=False):
        engine, game, hack = self.engine()
        if not remove:
            import linux_upgrade
            return linux_upgrade.run(engine, game, hack)
        # The existing CLI provides its validated state, lock, backup and rollback.
        if (game / engine.STATE_DIR / 'migration.json').exists():
            raise ValueError('Interrupted migration: keep the .pgm-linux-install folder and request recovery assistance.')
        old = sys.argv
        sys.argv = ['installer', 'uninstall' if remove else 'install', '--game', str(game)]
        if hack:
            sys.argv += ['--dfhack', str(hack)]
        try:
            engine.main()
        finally:
            sys.argv = old

    def install(self):
        return self.mutate()

    def uninstall(self):
        return self.mutate(True)

    def windows_context(self):
        if self.system != 'Windows' or not self.windows_available:
            raise ValueError('This build does not include the experimental Windows module.')
        if not self.selected_game:
            raise ValueError('Select your game folder.')
        game = Path(self.selected_game).expanduser().resolve()
        def closed():
            core.game_closed(game)
            return True
        return core.windows_engine(ROOT), game, closed

    def windows_check(self):
        engine, game, closed = self.windows_context()
        engine.check(game, ROOT / 'traduction-windows/payload', ROOT / 'traduction-windows/payload-sha256.json', closed)
        return 'Experimental Windows module checked. No files were changed.'

    def windows_install(self):
        if not self.selected_experimental:
            raise ValueError('Enable the experimental Windows translation option before installing.')
        engine, game, closed = self.windows_context()
        engine.install(game, ROOT / 'traduction-windows/payload', ROOT / 'traduction-windows/payload-sha256.json', closed)
        return 'Experimental Windows French translation installed. Check its appearance in the game.'

    def windows_restore(self):
        engine, game, closed = self.windows_context()
        engine.uninstall(game, closed)
        return 'Previous Windows files restored.'

    def variants(self):
        import importlib.util
        if not self.selected_game:
            raise ValueError('Select your game folder.')
        game = Path(self.selected_game).resolve()
        executable = 'Dwarf Fortress.exe' if self.system == 'Windows' else 'dwarfort'
        if not (game / executable).is_file():
            raise ValueError('This folder does not contain the expected game executable.')
        core.game_closed(game)
        workshop = Path(self.selected_workshop).expanduser().resolve() if self.selected_workshop else game.parent.parent / 'workshop/content/975370'
        if self.selected_mods:
            mods = Path(self.selected_mods).expanduser().resolve()
        elif self.system == 'Windows':
            if not os.environ.get('APPDATA'):
                raise ValueError('Select your local mods folder.')
            mods = Path(os.environ['APPDATA']) / 'Bay 12 Games/Dwarf Fortress/mods'
        else:
            mods = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'Bay 12 Games/Dwarf Fortress/mods'
        spec = importlib.util.spec_from_file_location('pgm_variants', ROOT / 'preparer-variantes.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        module.prepare(workshop / '3635878659', mods, 'born_normally_linux', 'vanilla_born_normally', 9)
        module.prepare(workshop / '3072627813', mods, 'pgm_accurate_domestic_graphics', 'accurate_domestic_animal_graphics', 105, animals=True)
        return 'Variants prepared. You can now install the modpack presets.'

    def checked_game(self):
        if not self.selected_game:
            raise ValueError('Select your game folder.')
        game = Path(self.selected_game).expanduser().resolve()
        executable = 'Dwarf Fortress.exe' if self.system == 'Windows' else 'dwarfort'
        if not (game / executable).is_file():
            raise ValueError('This folder does not contain the expected game executable.')
        core.game_closed(game)
        return game

    def presets(self):
        game = self.checked_game()
        if not (game / 'dfhack-config').is_dir():
            raise ValueError('Launch the game with DFHack once, then close it.')
        return pack.install(game, ROOT / 'presets/mod-manager.json')

    def restore_presets(self):
        return pack.restore(self.checked_game())

    def updates(self):
        self.asset = None
        candidate = core.release_for(self.system)
        if not core.newer_than(candidate['version'], core.VERSION):
            return ('No newer release is available. Current version: ' + core.VERSION +
                    '\nLatest release: ' + candidate['version'])
        self.asset = candidate
        return ('New installer available: ' + candidate['version'] +
                '\nCurrent version: ' + core.VERSION +
                '\nThe download will be verified. It will not run automatically.')

    def get_update(self):
        if not self.asset:
            messagebox.showinfo('PGM', 'Check for updates first.')
            return
        folder = filedialog.askdirectory(title='Save update package')
        if folder:
            def download():
                self.downloaded = core.download(self.asset, folder)
                return str(self.downloaded) + '\nDownload verified. Close this installer, open the downloaded installer, select the same game folder, then choose Install / update. You do not need the old installer.'
            self.run(download)

    def open_download(self):
        if self.busy:
            return
        if self.downloaded:
            webbrowser.open(self.downloaded.parent.as_uri())
        else:
            messagebox.showinfo('PGM', 'Download an update first.')

    def guide(self):
        name = 'LINUX' if self.system == 'Linux' else 'WINDOWS'
        webbrowser.open(f'https://github.com/{core.REPO}/blob/main/docs/INSTALL-{name}.md')

    def report(self):
        filename = filedialog.asksaveasfilename(defaultextension='.txt', initialfile='PGM-report.txt')
        if filename:
            Path(filename).write_text(self.output.get('1.0', 'end'), encoding='utf-8')

    def close(self):
        if self.busy:
            messagebox.showinfo('PGM', 'Wait for the current operation to finish before closing.')
        else:
            self.window.destroy()


if __name__ == '__main__':
    root = tk.Tk()
    app = App(root)
    if '--smoke-test' in sys.argv:
        root.update()
        assert len(app.buttons) == (14 if app.system == "Windows" and app.windows_available else 11)
        assert app.output.winfo_exists()
        app.navigation_dialog();root.update()
        assert app.navigation_window.winfo_exists()
        assert not app.navigation_experimental.get()
        assert (ROOT / 'presets/mod-manager.json').is_file()
        if app.system == 'Linux':
            assert len(core.linux_engine(ROOT).read_manifest()) == 7
        if app.system == 'Windows' and app.windows_available:
            assert callable(core.windows_engine(ROOT).install)
        root.destroy()
    else:
        root.mainloop()
