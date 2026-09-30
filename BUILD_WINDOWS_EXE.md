# Building SEZDocs.exe (Windows desktop app)

PyInstaller has to run **on Windows** to produce a Windows `.exe` — it can't
be cross-compiled from Linux/Mac. These steps take about 10 minutes on your
Windows machine.

## 1. One-time setup

1. Install Python 3.11+ from python.org (check "Add Python to PATH" during install).
2. Install Tesseract OCR: https://github.com/UB-Mannheim/tesseract/wiki
   (default install path `C:\Program Files\Tesseract-OCR\` is auto-detected by the app).
3. Open PowerShell in the `sezdocs` folder and run:
   ```
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt
   ```

## 2. Test it runs normally first

```
python desktop_launcher.py
```

A native window titled "SEZDocs - Offline Document Search" should open.
Fix any missing-dependency errors here before packaging — it's much easier
to debug now than inside a frozen exe.

## 3. Build the exe

```
pyinstaller --noconfirm --windowed --name SEZDocs ^
  --add-data "app.py;." ^
  --add-data ".streamlit;.streamlit" ^
  --collect-all streamlit ^
  --collect-all sentence_transformers ^
  --collect-all faiss ^
  desktop_launcher.py
```

This produces `dist\SEZDocs\SEZDocs.exe`. The `dist\SEZDocs` folder is the
whole app — copy that entire folder wherever you want to run it from (a USB
stick, another PC, etc.). Don't move just the `.exe` on its own.

## 4. First run will feel slow — that's expected

`sentence-transformers` downloads the `all-MiniLM-L6-v2` model (~90 MB) the
first time it's used, then caches it locally. On a machine with no internet
access, run the app once *with* internet first so the model is cached in
`%USERPROFILE%\.cache`, then it works fully offline after that.

## 5. Optional: a proper icon

Add `--icon=sezdocs.ico` to the pyinstaller command once you have an
`.ico` file, otherwise it ships with a default Python icon.

## Troubleshooting

- **"Failed to execute script"**: run the exe from a terminal
  (`dist\SEZDocs\SEZDocs.exe`) instead of double-clicking, so you can see
  the actual error.
- **Antivirus flags the exe**: this is a common PyInstaller false positive
  (unsigned exe + bundled Python interpreter). Code-signing the exe removes
  most warnings but requires a paid certificate.
- **OCR doesn't work**: confirm Tesseract is installed system-wide, not just
  in your venv — `pytesseract` calls the actual `tesseract.exe` binary.
