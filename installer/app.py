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

ROOT = Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parent))


class App:
    def __init__(self, window):
        self.window = window
        window.title('PGM — Installation et mises à jour')
        window.geometry('900x750')
        window.minsize(860, 700)
        self.events = queue.Queue()
        self.busy = False
        self.asset = None
        self.downloaded = None
        self.buttons = []
        self.system = platform.system()
        box = ttk.Frame(window, padding=22)
        box.pack(fill='both', expand=True)
        ttk.Label(box, text='PGM · Starter Quest Mods', font=('', 20, 'bold')).pack(anchor='w')
        ttk.Label(box, text='Bêta 1 · jeu 53.17 · DFHack requis · Windows / Linux x86-64').pack(anchor='w', pady=(2, 14))
        self.game = tk.StringVar(value=str(next(iter(core.game_candidates()), '')))
        self.hack = tk.StringVar()
        self.workshop = tk.StringVar()
        self.mods = tk.StringVar()
        self.row(box, 'Dossier de Dwarf Fortress', self.game)
        self.row(box, 'Dossier de DFHack (facultatif si détecté)', self.hack)
        self.row(box, 'Dossier Workshop content/975370 (facultatif si détecté)', self.workshop)
        self.row(box, 'Dossier des mods locaux (facultatif si détecté)', self.mods)
        note = ('Linux natif : installation de la traduction et restauration des fichiers d’origine.'
                if self.system == 'Linux' else
                'Windows : préparation du modpack disponible. Traduction native PGM non intégrée ici.')
        ttk.Label(box, text=note, wraplength=700).pack(anchor='w', pady=10)
        actions = ttk.Frame(box)
        actions.pack(fill='x')
        for label, action in [('Vérifier', self.check), ('Installer la traduction', self.install),
                              ('Désinstaller la traduction', self.uninstall)]:
            self.button(actions, label, lambda f=action: self.run(f), linux=True)
        presets = ttk.Frame(box)
        presets.pack(fill='x', pady=(8, 0))
        self.button(presets, 'Installer les presets du pack', lambda: self.run(self.presets))
        self.button(presets, 'Restaurer les presets précédents', lambda: self.run(self.restore_presets))
        extras = ttk.Frame(box)
        extras.pack(fill='x', pady=8)
        self.button(extras, 'Préparer les variantes du pack', lambda: self.run(self.variants))
        self.button(extras, 'Chercher une mise à jour', lambda: self.run(self.updates))
        self.button(extras, 'Télécharger la mise à jour', self.get_update)
        self.button(extras, 'Ouvrir le téléchargement', self.open_download)
        self.output = tk.Text(box, height=12, wrap='word', state='disabled')
        self.output.pack(fill='both', expand=True, pady=8)
        bottom = ttk.Frame(box)
        bottom.pack(fill='x')
        ttk.Button(bottom, text='Guide d’installation', command=self.guide).pack(side='left')
        ttk.Button(bottom, text='Enregistrer le rapport', command=self.report).pack(side='right')
        window.protocol('WM_DELETE_WINDOW', self.close)
        self.log('Ferme le jeu avant toute modification. Les fichiers locaux modifiés sont protégés.\n'
                 'Steam gère les mises à jour des mods Workshop. Cet outil gère les fichiers complémentaires.\n')
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
        ttk.Button(row, text='Parcourir…', command=choose).pack(side='right', padx=(8, 0))

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
                self.events.put(stream.getvalue() + str(result or 'Opération terminée.'))
            except Exception as error:
                self.events.put(stream.getvalue() + 'Opération arrêtée : ' + str(error))
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

    def engine(self):
        if self.system != 'Linux':
            raise ValueError('La traduction native Windows reste à valider.')
        if not self.selected_game:
            raise ValueError('Choisis le dossier du jeu.')
        if os.geteuid() == 0:
            raise ValueError('Lance PGM avec ton compte habituel, sans sudo.')
        return core.linux_engine(ROOT), Path(self.selected_game).expanduser().resolve(), (
            Path(self.selected_hack).expanduser().resolve() if self.selected_hack else None)

    def check(self):
        engine, game, hack = self.engine()
        if (game / engine.STATE_DIR / 'state.json').exists():
            engine.make_plan_without_init(game, hack)
        else:
            engine.make_plan(game, hack)
        return 'Jeu et traduction vérifiés. Aucun fichier du jeu modifié.'

    def mutate(self, remove=False):
        engine, game, hack = self.engine()
        # The existing CLI provides its validated state, lock, backup and rollback.
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

    def variants(self):
        import importlib.util
        if not self.selected_game:
            raise ValueError('Choisis le dossier du jeu.')
        game = Path(self.selected_game).resolve()
        executable = 'Dwarf Fortress.exe' if self.system == 'Windows' else 'dwarfort'
        if not (game / executable).is_file():
            raise ValueError('Ce dossier ne contient pas le jeu attendu.')
        core.game_closed(game)
        workshop = Path(self.selected_workshop).expanduser().resolve() if self.selected_workshop else game.parent.parent / 'workshop/content/975370'
        if self.selected_mods:
            mods = Path(self.selected_mods).expanduser().resolve()
        elif self.system == 'Windows':
            if not os.environ.get('APPDATA'):
                raise ValueError('Choisis le dossier des mods locaux.')
            mods = Path(os.environ['APPDATA']) / 'Bay 12 Games/Dwarf Fortress/mods'
        else:
            mods = game / 'mods'
        spec = importlib.util.spec_from_file_location('pgm_variants', ROOT / 'preparer-variantes.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        module.prepare(workshop / '3635878659', mods, 'born_normally_linux', 'vanilla_born_normally', 9)
        module.prepare(workshop / '3072627813', mods, 'pgm_accurate_domestic_graphics', 'accurate_domestic_animal_graphics', 105, animals=True)
        return 'Variantes préparées. Tu peux maintenant installer les presets du pack.'

    def checked_game(self):
        if not self.selected_game:
            raise ValueError('Choisis le dossier du jeu.')
        game = Path(self.selected_game).expanduser().resolve()
        executable = 'Dwarf Fortress.exe' if self.system == 'Windows' else 'dwarfort'
        if not (game / executable).is_file():
            raise ValueError('Ce dossier ne contient pas le jeu attendu.')
        core.game_closed(game)
        return game

    def presets(self):
        game = self.checked_game()
        if not (game / 'dfhack-config').is_dir():
            raise ValueError('Lance d’abord le jeu avec DFHack, puis ferme-le.')
        return pack.install(game, ROOT / 'presets/mod-manager.json')

    def restore_presets(self):
        return pack.restore(self.checked_game())

    def updates(self):
        self.asset = core.release_for(self.system)
        return (('Tu disposes déjà de cette version. ' if self.asset['version'] == core.VERSION else 'Installateur disponible : ') + self.asset['version'] + '\nVersion embarquée : ' + core.VERSION +
                '\nLe téléchargement est vérifié avant enregistrement. Aucun fichier téléchargé n’est exécuté automatiquement.')

    def get_update(self):
        if not self.asset:
            messagebox.showinfo('PGM', 'Cherche d’abord une mise à jour.')
            return
        folder = filedialog.askdirectory(title='Enregistrer le paquet de mise à jour')
        if folder:
            def download():
                self.downloaded = core.download(self.asset, folder)
                return str(self.downloaded) + '\nTéléchargement vérifié. Ouvre-le après avoir fermé cet assistant. La traduction déjà installée n’est pas remplacée automatiquement.'
            self.run(download)

    def open_download(self):
        if self.busy:
            return
        if self.downloaded:
            webbrowser.open(self.downloaded.parent.as_uri())
        else:
            messagebox.showinfo('PGM', 'Télécharge d’abord une mise à jour.')

    def guide(self):
        name = 'LINUX' if self.system == 'Linux' else 'WINDOWS'
        webbrowser.open(f'https://github.com/{core.REPO}/blob/main/docs/INSTALL-{name}.md')

    def report(self):
        filename = filedialog.asksaveasfilename(defaultextension='.txt', initialfile='PGM-rapport.txt')
        if filename:
            Path(filename).write_text(self.output.get('1.0', 'end'), encoding='utf-8')

    def close(self):
        if self.busy:
            messagebox.showinfo('PGM', 'Attends la fin de l’opération avant de fermer.')
        else:
            self.window.destroy()


if __name__ == '__main__':
    root = tk.Tk()
    app = App(root)
    if '--smoke-test' in sys.argv:
        root.update()
        assert len(app.buttons) == 9
        assert app.output.winfo_exists()
        root.destroy()
    else:
        root.mainloop()
