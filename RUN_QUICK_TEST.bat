@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ==== SEZDocs quick test ====
where python >nul 2>&1
if errorlevel 1 (
  echo Python not found. Install Python 3.12 from python.org and tick "Add python.exe to PATH", then run this again.
  pause
  exit /b 1
)
if not exist venv_test\Scripts\python.exe python -m venv venv_test
echo Installing packages (first run takes a few minutes)...
venv_test\Scripts\python.exe -m pip install --upgrade pip -q
venv_test\Scripts\python.exe -m pip install streamlit pypdf pdf2image pytesseract sentence-transformers faiss-cpu pandas numpy reportlab arabic-reshaper python-bidi
echo Starting SEZDocs in your browser...
venv_test\Scripts\python.exe -m streamlit run app.py --server.headless false --server.address localhost
pause
