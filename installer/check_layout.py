"""Exercise English Linux and Windows UI layouts without installing anything."""
import sys
from unittest.mock import patch
import tkinter as tk
from tkinter import ttk
import app

def children(widget):
    for child in widget.winfo_children():
        yield child
        yield from children(child)

for system in ('Linux','Windows'):
    root=tk.Tk()
    with patch.object(app.platform,'system',return_value=system):ui=app.App(root)
    ui.navigation_dialog();root.update()
    for window in (root,ui.navigation_window):
        for widget in children(window):
            if isinstance(widget,ttk.Button):
                assert widget.winfo_x()>=0 and widget.winfo_x()+widget.winfo_width()<=widget.master.winfo_width(), (system,widget.cget('text'),'horizontal clipping')
                assert widget.winfo_y()>=0 and widget.winfo_y()+widget.winfo_height()<=widget.master.winfo_height(), (system,widget.cget('text'),'vertical clipping')
                assert widget.winfo_width()>=widget.winfo_reqwidth(),(system,widget.cget('text'),'button text clipped')
    assert not ui.navigation_experimental.get()
    assert not ui.experimental.get()
    ui.navigation_window.withdraw();root.destroy()
    print('English',system,'layout passed (simulated platform branch, not native Windows)')
