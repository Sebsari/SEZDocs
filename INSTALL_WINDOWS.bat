@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title SEZDocs - نصب خودکار

:: ======================================================================
::  SEZDocs - نصب‌کننده یک‌مرحله‌ای ویندوز
::  این فایل رو از گیت‌هاب دانلود و اجرا کن. کارهایی که خودش انجام می‌ده:
::    1) نصب پایتون (اگر نباشه)
::    2) نصب Tesseract OCR + پکیج زبان فارسی (fas) + انگلیسی
::    3) نصب Poppler (برای تبدیل PDF اسکن‌شده به تصویر جهت OCR)
::    4) دانلود کد برنامه SEZDocs از گیت‌هاب
::    5) ساخت محیط مجازی پایتون و نصب پکیج‌ها
::    6) ساخت یک آیکون روی دسکتاپ برای اجراهای بعدی
::    7) اجرای برنامه
::
::  نکته: روی یک ویندوز کاملاً تازه (بدون پایتون)، ممکنه لازم باشه این
::  فایل رو دو بار اجرا کنی؛ بار اول پایتون نصب می‌شه ولی PATH ویندوز تا
::  باز کردن یک پنجره ترمینال جدید به‌روز نمی‌شه.
:: ======================================================================

:: ---------------- تنظیمات: این سه خط رو با اطلاعات ریپوی خودت پر کن ----------------
set "GITHUB_USER=Sebsari"
set "GITHUB_REPO=SEZDocs"
set "GITHUB_BRANCH=main"
:: -----------------------------------------------------------------------------------

set "ZIP_URL=https://github.com/%GITHUB_USER%/%GITHUB_REPO%/archive/refs/heads/%GITHUB_BRANCH%.zip"
set "INSTALL_DIR=%LOCALAPPDATA%\SEZDocs"
set "APP_DIR=%INSTALL_DIR%\app"
set "TOOLS_DIR=%INSTALL_DIR%\tools"
set "TESS_EXE=%ProgramFiles%\Tesseract-OCR\tesseract.exe"
set "TESSDATA_DIR=%ProgramFiles%\Tesseract-OCR\tessdata"

echo.
echo ================================================================
echo   SEZDocs - نصب و راه‌اندازی خودکار
echo ================================================================
echo.

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>nul
if not exist "%TOOLS_DIR%"   mkdir "%TOOLS_DIR%"   >nul 2>nul

:: ------------------------------------------------------------
:: 0) درخواست دسترسی Administrator (لازم برای نصب Tesseract/زبان فارسی)
:: ------------------------------------------------------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [نیاز به دسترسی مدیر] در حال باز کردن دوباره با دسترسی Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" 
    exit /b
)

:: ------------------------------------------------------------
:: 1) بررسی وجود winget
:: ------------------------------------------------------------
where winget >nul 2>nul
if "%errorlevel%"=="0" (set "HAS_WINGET=1") else (set "HAS_WINGET=0")

:: ------------------------------------------------------------
:: 2) پایتون
:: ------------------------------------------------------------
where python >nul 2>nul
if "%errorlevel%"=="0" (
    echo [OK] پایتون از قبل نصب است.
) else (
    echo [...] در حال نصب پایتون - ممکنه چند دقیقه طول بکشه...
    if "%HAS_WINGET%"=="1" (
        winget install --id Python.Python.3.12 -e --silent --accept-source-agreements --accept-package-agreements
    ) else (
        echo    winget پیدا نشد؛ دانلود مستقیم نصب‌کننده پایتون...
        curl -L -o "%TEMP%\python-installer.exe" "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
        "%TEMP%\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1
        del "%TEMP%\python-installer.exe" >nul 2>nul
    )
    echo.
    echo [مهم] پایتون نصب شد اما این پنجره از تغییرات PATH خبر نداره.
    echo       لطفاً این فایل نصب رو ببند و دوباره اجراش کن تا ادامه بده.
    echo.
    pause
    exit /b 0
)

:: ------------------------------------------------------------
:: 3) Tesseract OCR
:: ------------------------------------------------------------
if exist "%TESS_EXE%" (
    echo [OK] Tesseract OCR از قبل نصب است.
) else (
    where tesseract >nul 2>nul
    if "%errorlevel%"=="0" (
        echo [OK] Tesseract OCR از قبل نصب است ^(در PATH^).
    ) else (
        echo [...] در حال نصب Tesseract OCR...
        if "%HAS_WINGET%"=="1" (
            winget install --id UB-Mannheim.TesseractOCR -e --silent --accept-source-agreements --accept-package-agreements
        ) else (
            echo.
            echo [نیاز به نصب دستی] winget موجود نیست.
            echo Tesseract رو از این آدرس نصب کن و بعد این فایل رو دوباره اجرا کن:
            echo   https://github.com/UB-Mannheim/tesseract/wiki
            echo.
            pause
            exit /b 1
        )
        if not exist "%TESS_EXE%" (
            echo.
            echo [خطا] نصب Tesseract OCR ناموفق بود ^(winget کار نکرد^).
            echo دستی از این آدرس نصب کن و بعد این فایل رو دوباره اجرا کن:
            echo   https://github.com/UB-Mannheim/tesseract/wiki
            echo.
            pause
            exit /b 1
        )
    )
)

:: ------------------------------------------------------------
:: 4) بسته زبان فارسی برای OCR (پیش‌فرض Tesseract فقط انگلیسی داره)
:: ------------------------------------------------------------
if exist "%TESSDATA_DIR%\fas.traineddata" (
    echo [OK] بسته زبان فارسی OCR از قبل نصب است.
) else (
    echo [...] در حال دانلود بسته زبان فارسی برای OCR...
    curl -L -o "%TESSDATA_DIR%\fas.traineddata" "https://raw.githubusercontent.com/tesseract-ocr/tessdata/main/fas.traineddata"
    if exist "%TESSDATA_DIR%\fas.traineddata" (
        echo [OK] بسته زبان فارسی نصب شد.
    ) else (
        echo [هشدار] دانلود بسته زبان فارسی ناموفق بود.
        echo برای رفع دستی، این فایل رو دانلود و در این پوشه کپی کن:
        echo   لینک: https://github.com/tesseract-ocr/tessdata/raw/main/fas.traineddata
        echo   مقصد: %TESSDATA_DIR%
    )
)

:: ------------------------------------------------------------
:: 5) Poppler ^(برای تبدیل صفحات اسکن‌شده PDF به تصویر پیش از OCR^)
:: ------------------------------------------------------------
set "POPPLER_BIN=%TOOLS_DIR%\poppler\poppler-24.07.0\Library\bin"
if exist "%POPPLER_BIN%\pdftoppm.exe" (
    echo [OK] Poppler از قبل موجود است.
) else (
    echo [...] در حال دانلود Poppler...
    curl -L -o "%TOOLS_DIR%\poppler.zip" "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.07.0-0/Release-24.07.0-0.zip"
    powershell -NoProfile -Command "Expand-Archive -Path '%TOOLS_DIR%\poppler.zip' -DestinationPath '%TOOLS_DIR%\poppler' -Force"
    del "%TOOLS_DIR%\poppler.zip" >nul 2>nul
    for /f "delims=" %%D in ('dir "%TOOLS_DIR%\poppler" /b /ad') do (
        if exist "%TOOLS_DIR%\poppler\%%D\Library\bin\pdftoppm.exe" set "POPPLER_BIN=%TOOLS_DIR%\poppler\%%D\Library\bin"
    )
    echo [OK] Poppler آماده شد.
)
:: ------------------------------------------------------------
:: 6) دانلود کد برنامه SEZDocs از گیت‌هاب
:: ------------------------------------------------------------
if exist "%APP_DIR%\app.py" (
    echo [OK] SEZDocs از قبل دانلود شده.
    echo      ^(برای دریافت آخرین نسخه: پوشه "%APP_DIR%" رو پاک کن و این فایل رو دوباره اجرا کن^)
) else (
    echo [...] در حال دانلود SEZDocs از گیت‌هاب...
    curl -L -o "%INSTALL_DIR%\sezdocs.zip" "%ZIP_URL%"
    powershell -NoProfile -Command "Expand-Archive -Path '%INSTALL_DIR%\sezdocs.zip' -DestinationPath '%INSTALL_DIR%\extracted' -Force"
    for /d %%D in ("%INSTALL_DIR%\extracted\*") do (
        xcopy "%%D" "%APP_DIR%\" /E /I /Y >nul
    )
    rmdir /S /Q "%INSTALL_DIR%\extracted" >nul 2>nul
    del "%INSTALL_DIR%\sezdocs.zip" >nul 2>nul
    if not exist "%APP_DIR%\app.py" (
        echo.
        echo [خطا] دانلود یا استخراج کد SEZDocs از گیت‌هاب ناموفق بود.
        echo لطفاً اتصال اینترنت و صحت این آدرس رو چک کن:
        echo   %ZIP_URL%
        echo.
        pause
        exit /b 1
    )
    echo [OK] دانلود کامل شد.
)

:: ذخیره مسیر Poppler در یک فایل کنار برنامه - چون متغیر محیطی ست‌شده با
:: setx همیشه به‌موقع توسط میانبر دسکتاپ دیده نمی‌شه، این روش مطمئن‌تره.
> "%APP_DIR%\poppler_path.txt" echo %POPPLER_BIN%

:: ------------------------------------------------------------
:: 7) محیط مجازی پایتون + نصب پکیج‌ها
:: ------------------------------------------------------------
cd /d "%APP_DIR%"
if not exist "%APP_DIR%\venv\Scripts\python.exe" (
    echo [...] در حال ساخت محیط مجازی پایتون...
    python -m venv venv
)
echo [...] در حال نصب پکیج‌های مورد نیاز ^(ممکنه چند دقیقه طول بکشه^)...
"%APP_DIR%\venv\Scripts\python.exe" -m pip install --upgrade pip -q
"%APP_DIR%\venv\Scripts\python.exe" -m pip install -r requirements.txt -q

echo [...] در حال دانلود مدل هوش مصنوعی جستجو ^(یک‌بار، حدود 90 مگابایت - بعدش کاملاً آفلاینه^)...
"%APP_DIR%\venv\Scripts\python.exe" -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
if "%errorlevel%"=="0" (
    echo [OK] مدل جستجو آماده شد - از این به بعد بدون نیاز به اینترنت کار می‌کنه.
) else (
    echo [هشدار] دانلود مدل جستجو ناموفق بود ^(اینترنت رو چک کن^).
    echo برنامه بازم بالا میاد، ولی اولین جستجو دوباره سعی می‌کنه دانلودش کنه.
)

:: ------------------------------------------------------------
:: 8) ساخت آیکون روی دسکتاپ برای اجراهای بعدی ^(بدون نیاز دوباره به این نصب‌کننده^)
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
echo [OK] آیکون SEZDocs روی دسکتاپ ساخته شد.

:: ------------------------------------------------------------
:: 9) اجرای برنامه
:: ------------------------------------------------------------
echo.
echo ================================================================
echo   نصب کامل شد! در حال اجرای SEZDocs...
echo   دفعات بعد، فقط آیکون SEZDocs روی دسکتاپ رو باز کن.
echo ================================================================
echo.
"%APP_DIR%\venv\Scripts\python.exe" "%APP_DIR%\desktop_launcher.py"

pause
