"""
SEZDocs Desktop Launcher
========================
Runs the Streamlit app as a background server and opens it in a native
desktop window (via pywebview) instead of a browser tab - so it looks
and feels like a normal Windows application, not a website.

This is the file PyInstaller packages into SEZDocs.exe. See
BUILD_WINDOWS_EXE.md for the exact build command.
"""

import os
import sys
import threading
import socket
import time

import webview
from streamlit.web import cli as stcli


def get_base_dir() -> str:
    """Works both as a normal script and as a PyInstaller-frozen exe."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))


def find_free_port(start: int = 8501) -> int:
    port = start
    while port < start + 50:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                return port
        port += 1
    return start


def run_streamlit(app_path: str, port: int):
    sys.argv = [
        "streamlit",
        "run",
        app_path,
        "--server.port", str(port),
        "--server.address", "127.0.0.1",
        "--server.headless", "true",
        "--browser.gatherUsageStats", "false",
        "--server.runOnSave", "false",
    ]
    stcli.main()


def wait_for_server(port: int, timeout: float = 30.0):
    start = time.time()
    while time.time() - start < timeout:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) == 0:
                return True
        time.sleep(0.25)
    return False


def main():
    base_dir = get_base_dir()
    app_path = os.path.join(base_dir, "app.py")
    port = find_free_port()

    server_thread = threading.Thread(
        target=run_streamlit, args=(app_path, port), daemon=True
    )
    server_thread.start()

    if not wait_for_server(port):
        print("SEZDocs failed to start - the local server never came up.")
        sys.exit(1)

    try:  # let the Report button save PDFs from inside the desktop window
        webview.settings["ALLOW_DOWNLOADS"] = True
    except Exception:
        pass

    webview.create_window(
        "SEZDocs - Offline Document Search",
        f"http://127.0.0.1:{port}",
        width=1280,
        height=860,
        min_size=(900, 600),
    )
    webview.start()


if __name__ == "__main__":
    main()
