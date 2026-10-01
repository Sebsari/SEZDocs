# SEZDocs

**Free, offline document search for Windows, with Persian and English OCR.**

SEZDocs indexes your PDF files and lets you search inside them, including
scanned PDFs, without sending anything to the internet. Everything runs on
your own computer.

## Features

- **100% offline and private.** Your documents never leave your PC. After the
  first install, no internet connection is needed.
- **Three search modes:** semantic (by meaning), keyword (exact words), or a
  hybrid of both.
- **OCR for scanned PDFs** in Persian and English (Tesseract + Poppler).
- **Smart indexing.** Files that have not changed are skipped automatically;
  changed files are re-processed. Add new files to an existing index at any time.
- **Named indexes.** Save, load, and clear separate indexes for different projects.
- **File readability status.** See which files were fully read, partially read,
  or are bad scans.
- **PDF report export.** Save your search results (query, file, page, snippet)
  as a PDF. Persian text is supported.
- **Desktop window.** Runs in its own app window, with a desktop shortcut.

## Install (Windows)

1. Download [`INSTALL_WINDOWS.bat`](INSTALL_WINDOWS.bat) from this repository
   (open the file, then use the download button).
2. Double-click it and accept the Administrator (UAC) prompt.
3. Wait while it installs everything automatically: Python, Tesseract OCR
   (with the Persian language pack), Poppler, the app, and the search model
   (about 90 MB, one time).
4. SEZDocs starts, and a **SEZDocs** shortcut is created on your desktop.

**Good to know:**

- On a PC with no Python installed, the first run installs Python and then asks
  you to **run the installer a second time** (Windows needs a fresh window to
  see the new Python).
- The installer needs Administrator rights once, to install Tesseract's language data.
- Internet is only needed during installation.

## Run from source (any OS)

```
pip install -r requirements.txt
streamlit run app.py
```

You also need [Tesseract OCR](https://github.com/UB-Mannheim/tesseract/wiki)
(with the `fas` and `eng` language data) and
[Poppler](https://github.com/oschwartz10612/poppler-windows/releases) installed
for scanned PDFs.

## Where your data is stored

Indexes, saved profiles, and uploaded documents are kept in the
`.my_offline_search_app` folder inside your user folder
(for example `C:\Users\YourName\.my_offline_search_app`).
Uninstalling or re-installing the app does not delete them.

## Known limitations

- Only **PDF** files are supported.
- The default search model (`all-MiniLM-L6-v2`) is English-oriented. Persian
  text is read and indexed, but **keyword search usually works better than
  semantic search for Persian documents**.
- OCR quality depends on scan quality.

## Built with

Streamlit, FAISS, sentence-transformers, Tesseract OCR, Poppler, pywebview,
and ReportLab. The JetBrains Mono font is bundled under the SIL Open Font
License (see `static/OFL.txt`).

This app was built with the help of **Claude** (Anthropic).

## License

Copyright (c) 2026 Mohammad Reza Sebzari

SEZDocs is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License v3.0. See the [LICENSE](LICENSE) file.

---

<div dir="rtl">

## معرفی (فارسی)

**SEZDocs** یک برنامه‌ی رایگان و کاملاً **آفلاین** برای ویندوز است که فایل‌های PDF شما را ایندکس می‌کند و امکان جستجو داخل آن‌ها را می‌دهد، حتی در PDFهای اسکن‌شده با OCR فارسی و انگلیسی. هیچ سندی از کامپیوتر شما خارج نمی‌شود.

### نصب
1. فایل `INSTALL_WINDOWS.bat` را از همین صفحه دانلود کنید.
2. روی آن دوبار کلیک کنید و اجازه‌ی Administrator را بدهید.
3. صبر کنید تا همه‌چیز خودکار نصب شود (پایتون، Tesseract با زبان فارسی، Poppler و مدل جستجو).
4. برنامه اجرا می‌شود و یک میان‌بر **SEZDocs** روی دسکتاپ ساخته می‌شود.

اگر روی کامپیوتر شما پایتون نصب نبود، بعد از اولین اجرا از شما می‌خواهد فایل نصب را **یک بار دیگر** اجرا کنید.

### نکته
فقط فایل‌های PDF پشتیبانی می‌شوند. برای اسناد فارسی، جستجوی «کلمه‌ای» معمولاً نتیجه‌ی بهتری از جستجوی «معنایی» می‌دهد.

</div>
