@echo off
setlocal EnableDelayedExpansion
title SEZDocs - Installer

:: ======================================================================
::  SEZDocs - Windows one-file installer
::  Download this file from GitHub and run it. What it does:
::    1) Install Python (if missing)
::    2) Install Tesseract OCR + the Persian (fas) and English language data
::    3) Install Poppler (converts scanned PDF pages to images for OCR)
::    4) Download the SEZDocs app code from GitHub
::    5) Create a Python virtual environment and install the packages
::    6) Pre-download the search AI model so first use is offline too
::    7) Create a desktop shortcut for future launches
::    8) Run the app
::
::  Note: on a brand-new Windows PC with no Python installed, you may need
::  to run this file twice - the first run installs Python, but this
::  window won't see the updated PATH until a new terminal is opened.
::
::  Persian/Farsi is NOT used for this installer's own on-screen messages,
::  because the Windows console (cmd.exe) does not render right-to-left
::  text correctly and the messages come out garbled. This has no effect
::  on the app itself: SEZDocs's OCR, search and PDF reports all still
::  fully support Persian documents and text.
:: ======================================================================

:: ---------------- Settings: fill these 3 lines in with your repo ----------------
set "GITHUB_USER=sebsari"
set "GITHUB_REPO=SEZDocs"
set "GITHUB_BRANCH=main"
:: ----------------------------------------------------------------------------------

set "ZIP_URL=https://github.com/%GITHUB_USER%/%GITHUB_REPO%/archive/refs/heads/%GITHUB_BRANCH%.zip"
set "INSTALL_DIR=%LOCALAPPDATA%\SEZDocs"
set "APP_DIR=%INSTALL_DIR%\app"
set "TOOLS_DIR=%INSTALL_DIR%\tools"

echo.
echo ================================================================
echo   SEZDocs - automatic setup
echo ================================================================
echo.

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>nul
if not exist "%TOOLS_DIR%"   mkdir "%TOOLS_DIR%"   >nul 2>nul

:: ------------------------------------------------------------
:: 0) Request Administrator access (needed to install Tesseract/language data)
:: ------------------------------------------------------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [Admin required] Reopening with Administrator access...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ------------------------------------------------------------
:: 1) Check for winget
:: ------------------------------------------------------------
where winget >nul 2>nul
if "%errorlevel%"=="0" (set "HAS_WINGET=1") else (set "HAS_WINGET=0")

:: ------------------------------------------------------------
:: 2) Python
:: ------------------------------------------------------------
where python >nul 2>nul
if "%errorlevel%"=="0" (
    echo [OK] Python is already installed.
) else (
    echo [...] Installing Python - this can take a few minutes...
    if "%HAS_WINGET%"=="1" (
        winget install --id Python.Python.3.12 -e --silent --accept-source-agreements --accept-package-agreements
    ) else (
        echo    winget not found; downloading the Python installer directly...
        curl -L -o "%TEMP%\python-installer.exe" "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
        "%TEMP%\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1
        del "%TEMP%\python-installer.exe" >nul 2>nul
    )
    echo.
    echo [Important] Python was installed, but this window doesn't know about
    echo             the PATH change yet. Please close this installer and run
    echo             it again to continue.
    echo.
    pause
    exit /b 0
)

:: ------------------------------------------------------------
:: 3) Tesseract OCR
:: ------------------------------------------------------------
call :find_tesseract
if not defined TESS_EXE (
    echo [...] Installing Tesseract OCR...
    if "%HAS_WINGET%"=="1" (
        winget install --id UB-Mannheim.TesseractOCR -e --silent --accept-source-agreements --accept-package-agreements
    ) else (
        echo.
        echo [Manual install needed] winget is not available.
        echo Install Tesseract from this page, then run this file again:
        echo   https://github.com/UB-Mannheim/tesseract/wiki
        echo.
        pause
        exit /b 1
    )
    call :find_tesseract
    if not defined TESS_EXE (
        echo.
        echo [Error] Tesseract OCR installation failed ^(winget didn't work^).
        echo Install it manually from this page, then run this file again:
        echo   https://github.com/UB-Mannheim/tesseract/wiki
        echo.
        pause
        exit /b 1
    )
) else (
    echo [OK] Tesseract OCR is already installed.
)

:: ------------------------------------------------------------
:: 4) Persian language pack for OCR (Tesseract ships English-only by default)
:: ------------------------------------------------------------
if exist "%TESSDATA_DIR%\fas.traineddata" (
    echo [OK] Persian OCR language pack is already installed.
) else (
    echo [...] Downloading the Persian OCR language pack...
    curl -L -o "%TESSDATA_DIR%\fas.traineddata" "https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/fas.traineddata"
    if exist "%TESSDATA_DIR%\fas.traineddata" (
        echo [OK] Persian language pack installed.
    ) else (
        echo [Warning] Downloading the Persian language pack failed.
        echo To fix this manually, download this file and copy it here:
        echo   Link: https://github.com/tesseract-ocr/tessdata/raw/main/fas.traineddata
        echo   Destination: %TESSDATA_DIR%
    )
)

:: ------------------------------------------------------------
:: 5) Poppler ^(converts scanned PDF pages to images before OCR^)
:: ------------------------------------------------------------
set "POPPLER_BIN=%TOOLS_DIR%\poppler\poppler-24.07.0\Library\bin"
if exist "%POPPLER_BIN%\pdftoppm.exe" (
    echo [OK] Poppler is already set up.
) else (
    echo [...] Downloading Poppler...
    curl -L -o "%TOOLS_DIR%\poppler.zip" "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.07.0-0/Release-24.07.0-0.zip"
    powershell -NoProfile -Command "Expand-Archive -Path '%TOOLS_DIR%\poppler.zip' -DestinationPath '%TOOLS_DIR%\poppler' -Force"
    del "%TOOLS_DIR%\poppler.zip" >nul 2>nul
    for /f "delims=" %%D in ('dir "%TOOLS_DIR%\poppler" /b /ad') do (
        if exist "%TOOLS_DIR%\poppler\%%D\Library\bin\pdftoppm.exe" set "POPPLER_BIN=%TOOLS_DIR%\poppler\%%D\Library\bin"
    )
    echo [OK] Poppler is ready.
)

:: ------------------------------------------------------------
:: 6) Download the SEZDocs app code from GitHub
:: ------------------------------------------------------------
if exist "%APP_DIR%\app.py" (
    echo [OK] SEZDocs is already downloaded.
    echo      ^(To get the latest version: delete the "%APP_DIR%" folder and run this file again^)
) else (
    echo [...] Downloading SEZDocs from GitHub...
    curl -L -o "%INSTALL_DIR%\sezdocs.zip" "%ZIP_URL%"
    powershell -NoProfile -Command "Expand-Archive -Path '%INSTALL_DIR%\sezdocs.zip' -DestinationPath '%INSTALL_DIR%\extracted' -Force"
    for /d %%D in ("%INSTALL_DIR%\extracted\*") do (
        xcopy "%%D" "%APP_DIR%\" /E /I /Y >nul
    )
    rmdir /S /Q "%INSTALL_DIR%\extracted" >nul 2>nul
    del "%INSTALL_DIR%\sezdocs.zip" >nul 2>nul
    if not exist "%APP_DIR%\app.py" (
        echo.
        echo [Error] Downloading or extracting the SEZDocs code from GitHub failed.
        echo Please check your internet connection and that this address is correct:
        echo   %ZIP_URL%
        echo.
        pause
        exit /b 1
    )
    echo [OK] Download complete.
)

:: Save the Poppler path to a file next to the app - an env var set with setx
:: isn't always picked up in time by the desktop shortcut, this is more reliable.
> "%APP_DIR%\poppler_path.txt" echo %POPPLER_BIN%

:: ------------------------------------------------------------
:: 7) Python virtual environment + packages
:: ------------------------------------------------------------
cd /d "%APP_DIR%"
if not exist "%APP_DIR%\venv\Scripts\python.exe" (
    echo [...] Creating the Python virtual environment...
    python -m venv venv
)
echo [...] Installing required packages ^(this can take a few minutes^)...
"%APP_DIR%\venv\Scripts\python.exe" -m pip install --upgrade pip -q
"%APP_DIR%\venv\Scripts\python.exe" -m pip install -r requirements.txt -q

echo [...] Downloading the search AI model ^(one time, about 90 MB - fully offline after this^)...
"%APP_DIR%\venv\Scripts\python.exe" -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
if "%errorlevel%"=="0" (
    echo [OK] Search model is ready - no internet needed from here on.
) else (
    echo [Warning] Downloading the search model failed ^(check your internet connection^).
    echo The app will still start, but the first search will try to download it again.
)

:: ------------------------------------------------------------
:: 8) Create a desktop shortcut for future launches ^(no need to re-run this installer^)
:: ------------------------------------------------------------
set "SHORTCUT_PS1=%TEMP%\sezdocs_make_shortcut.ps1"
> "%SHORTCUT_PS1%" echo $shell = New-Object -COM WScript.Shell
>> "%SHORTCUT_PS1%" echo $lnk = $shell.CreateShortcut("$env:USERPROFILE\Desktop\SEZDocs.lnk")
>> "%SHORTCUT_PS1%" echo $lnk.TargetPath = "%APP_DIR%\venv\Scripts\python.exe"
>> "%SHORTCUT_PS1%" echo $lnk.Arguments = '"%APP_DIR%\desktop_launcher.py"'
>> "%SHORTCUT_PS1%" echo $lnk.WorkingDirectory = "%APP_DIR%"
>> "%SHORTCUT_PS1%" echo $lnk.IconLocation = "%APP_DIR%\venv\Scripts\python.exe"
>> "%SHORTCUT_PS1%" echo $lnk.Save()
powershell -NoProfile -ExecutionPolicy Bypass -File "%SHORTCUT_PS1%"
del "%SHORTCUT_PS1%" >nul 2>nul
echo [OK] SEZDocs desktop shortcut created.

:: ------------------------------------------------------------
:: 9) Run the app
:: ------------------------------------------------------------
echo.
echo ================================================================
echo   Setup complete! Starting SEZDocs...
echo   Next time, just open the SEZDocs icon on your desktop.
echo ================================================================
echo.
"%APP_DIR%\venv\Scripts\python.exe" "%APP_DIR%\desktop_launcher.py"

pause
exit /b 0

:: ------------------------------------------------------------
:: Finds an existing Tesseract install and derives its tessdata folder,
:: wherever it actually is (not just the default Program Files location) -
:: sets TESS_EXE and TESSDATA_DIR, or leaves both undefined if not found.
:: ------------------------------------------------------------
:find_tesseract
set "TESS_EXE="
set "TESSDATA_DIR="
if exist "%ProgramFiles%\Tesseract-OCR\tesseract.exe" (
    set "TESS_EXE=%ProgramFiles%\Tesseract-OCR\tesseract.exe"
) else (
    for /f "delims=" %%I in ('where tesseract 2^>nul') do (
        if not defined TESS_EXE set "TESS_EXE=%%I"
    )
)
if defined TESS_EXE (
    for %%I in ("%TESS_EXE%") do set "TESSDATA_DIR=%%~dpItessdata"
)
exit /b
