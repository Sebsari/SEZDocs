# SEZDocs - Copyright (c) 2026 Mohammad Reza Sebzari
# Licensed under the GNU General Public License v3.0 (see LICENSE).
"""
SEZDocs Desktop Launcher
========================
Runs the Streamlit app as a background server and opens it in a native
desktop window (via pywebview) instead of a browser tab - so it looks
and feels like a normal Windows application, not a website.

The Streamlit server runs as a separate subprocess (not an in-process
thread) because Streamlit registers a SIGTERM handler on startup, and
that only works from the main thread of a process - running it inside
a background thread raises "signal only works in main thread".

This is the file PyInstaller packages into SEZDocs.exe. See
BUILD_WINDOWS_EXE.md for the exact build command.
"""

import os
import sys
import subprocess
import socket
import time
import atexit
import threading
import traceback

import webview


WINDOW_TITLE = "SEZDocs - Offline Document Search"


def get_base_dir() -> str:
    """Works both as a normal script and as a PyInstaller-frozen exe."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))


def get_icon_path() -> str | None:
    """static/sezdocs.ico next to the app, if it's there."""
    path = os.path.join(get_base_dir(), "static", "sezdocs.ico")
    return path if os.path.isfile(path) else None


def set_taskbar_identity():
    """Give the window its own Windows taskbar identity, so the taskbar shows
    the SEZDocs icon instead of grouping it under the generic Python icon."""
    if os.name != "nt":
        return
    try:
        import ctypes
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "SEZTools.SEZDocs"
        )
    except Exception:
        pass


def apply_window_icon_when_ready(icon_path: str, timeout: float = 30.0):
    """Sets the title-bar AND taskbar icon straight through the Windows API
    (WM_SETICON) once the window exists. This does not depend on the
    pywebview version, so it works even where webview.start(icon=...) is
    ignored. Runs in a background thread and gives up quietly."""
    if os.name != "nt" or not icon_path:
        return

    def worker():
        try:
            import ctypes
            user32 = ctypes.windll.user32
            user32.FindWindowW.restype = ctypes.c_void_p
            user32.FindWindowW.argtypes = [ctypes.c_wchar_p, ctypes.c_wchar_p]
            user32.LoadImageW.restype = ctypes.c_void_p
            user32.LoadImageW.argtypes = [
                ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_uint,
                ctypes.c_int, ctypes.c_int, ctypes.c_uint,
            ]
            user32.SendMessageW.restype = ctypes.c_void_p
            user32.SendMessageW.argtypes = [
                ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p, ctypes.c_void_p,
            ]
            WM_SETICON, ICON_SMALL, ICON_BIG = 0x0080, 0, 1
            IMAGE_ICON, LR_LOADFROMFILE = 1, 0x0010
            deadline = time.time() + timeout
            while time.time() < deadline:
                hwnd = user32.FindWindowW(None, WINDOW_TITLE)
                if hwnd:
                    big = user32.LoadImageW(
                        None, icon_path, IMAGE_ICON,
                        user32.GetSystemMetrics(11), user32.GetSystemMetrics(11),
                        LR_LOADFROMFILE)
                    small = user32.LoadImageW(
                        None, icon_path, IMAGE_ICON,
                        user32.GetSystemMetrics(49), user32.GetSystemMetrics(49),
                        LR_LOADFROMFILE)
                    if big:
                        user32.SendMessageW(hwnd, WM_SETICON, ICON_BIG, big)
                    if small:
                        user32.SendMessageW(hwnd, WM_SETICON, ICON_SMALL, small)
                    return
                time.sleep(0.3)
        except Exception:
            pass

    threading.Thread(target=worker, daemon=True).start()


def log_path() -> str:
    return os.path.join(get_base_dir(), "sezdocs.log")


def log_error(text: str):
    """The app now starts without a console window, so errors that used to
    be printed on screen go to sezdocs.log next to the app instead."""
    try:
        with open(log_path(), "a", encoding="utf-8") as f:
            f.write(time.strftime("[%Y-%m-%d %H:%M:%S] ") + text + "\n")
    except Exception:
        pass


def show_error_box(message: str):
    """A plain Windows message box - visible even with no console."""
    if os.name != "nt":
        print(message)
        return
    try:
        import ctypes
        ctypes.windll.user32.MessageBoxW(0, message, "SEZDocs", 0x10)
    except Exception:
        pass


def find_free_port(start: int = 8501) -> int:
    port = start
    while port < start + 50:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                return port
        port += 1
    return start


def child_python() -> str:
    """The launcher itself may run under pythonw.exe (no console). The
    Streamlit server child uses the regular python.exe next to it - it is
    started with CREATE_NO_WINDOW, so no black window appears either way."""
    exe = sys.executable
    if os.name == "nt" and os.path.basename(exe).lower() == "pythonw.exe":
        candidate = os.path.join(os.path.dirname(exe), "python.exe")
        if os.path.isfile(candidate):
            return candidate
    return exe


def start_streamlit(app_path: str, port: int) -> subprocess.Popen:
    creationflags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    return subprocess.Popen(
        [
            child_python(), "-m", "streamlit", "run", app_path,
            "--server.port", str(port),
            "--server.address", "127.0.0.1",
            "--server.headless", "true",
            "--browser.gatherUsageStats", "false",
            "--server.runOnSave", "false",
        ],
        cwd=os.path.dirname(app_path),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=creationflags,
    )


def wait_for_server(port: int, proc: subprocess.Popen, timeout: float = 60.0):
    start = time.time()
    while time.time() - start < timeout:
        if proc.poll() is not None:
            return False  # the server process died on its own
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) == 0:
                return True
        time.sleep(0.25)
    return False


def main():
    base_dir = get_base_dir()
    app_path = os.path.join(base_dir, "app.py")
    port = find_free_port()

    proc = start_streamlit(app_path, port)
    atexit.register(lambda: proc.poll() is None and proc.terminate())

    if not wait_for_server(port, proc):
        msg = "SEZDocs failed to start - the local server never came up."
        log_error(msg)
        show_error_box(msg)
        sys.exit(1)

    try:  # let the Report button save PDFs from inside the desktop window
        webview.settings["ALLOW_DOWNLOADS"] = True
    except Exception:
        pass

    set_taskbar_identity()
    webview.create_window(
        WINDOW_TITLE,
        f"http://127.0.0.1:{port}",
        width=1280,
        height=860,
        min_size=(900, 600),
    )
    icon = get_icon_path()
    apply_window_icon_when_ready(icon)
    try:
        webview.start(icon=icon) if icon else webview.start()
    except TypeError:  # older pywebview without the icon argument
        webview.start()

    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        err = traceback.format_exc()
        log_error(err)
        show_error_box(
            "SEZDocs hit an unexpected error.\n\nDetails were saved to:\n"
            + log_path()
        )
        sys.exit(1)
