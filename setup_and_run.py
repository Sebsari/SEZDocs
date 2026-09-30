import os
import sys
import subprocess
import urllib.request
import zipfile

# ------------------------------------------------------------------
# ۱. مسیرهای محلی پروژه (بدون نیاز به دستکاری مسیرهای سیستم عامل)
# ------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
POPPLER_DIR = os.path.join(TOOLS_DIR, "poppler")
TESSERACT_DIR = os.path.join(TOOLS_DIR, "tesseract")
INDEX_DIR = os.path.join(BASE_DIR, "search_index")

os.makedirs(TOOLS_DIR, exist_ok=True)

# ------------------------------------------------------------------
# ۲. نصب خودکار کتابخانه‌های پایتون (در صورت عدم وجود)
# ------------------------------------------------------------------
REQUIRED_PACKAGES = [
    "streamlit", "pypdf", "pdf2image", 
    "pytesseract", "sentence-transformers", "faiss-cpu"
]

IMPORT_NAME_OVERRIDES = {"faiss-cpu": "faiss"}

def install_packages():
    print("🔄 Checking Python packages...")
    for package in REQUIRED_PACKAGES:
        import_name = IMPORT_NAME_OVERRIDES.get(package, package.replace("-", "_"))
        try:
            __import__(import_name)
        except ImportError:
            print(f"📦 Installing {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# ------------------------------------------------------------------
# ۳. دانلود و آماده‌سازی خودکار Tesseract و Poppler (فقط بار اول)
# ------------------------------------------------------------------
def setup_external_tools():
    # لینک‌های مستقیم نسخه‌های پرتابل و بدون نیاز به نصب
    POPPLER_URL = "https://github.com/oschwartz10612/poppler-windows/releases/download/v24.07.0-0/Release-24.07.0-0.zip"
    
    # دانلود Poppler در صورت عدم وجود
    poppler_bin = os.path.join(POPPLER_DIR, "Library", "bin")
    if not os.path.exists(poppler_bin):
        print("📥 Downloading Poppler Portable (one-time setup)...")
        zip_path = os.path.join(TOOLS_DIR, "poppler.zip")
        urllib.request.urlretrieve(POPPLER_URL, zip_path)
        
        print("📦 Extracting Poppler...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(POPPLER_DIR)
        os.remove(zip_path)
        print("✅ Poppler ready!")
    else:
        print("✅ Poppler already exists. Skipping download.")

    # تنظیم مسیرها برای استفاده پایتون
    os.environ["PATH"] += os.pathsep + poppler_bin
    
    # راهنمای Tesseract (چون نصب‌کننده exe دارد، مسیر استاندارد بررسی می‌شود)
    tesseract_exe = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    if os.path.exists(tesseract_exe):
        import pytesseract
        pytesseract.pytesseract.tesseract_cmd = tesseract_exe
        print("✅ Tesseract OCR detected!")
    else:
        print("⚠️ Tesseract OCR not found in default path.")
        print("   Please install Tesseract OCR manually from: https://github.com/UB-Mannheim/tesseract/wiki")

# ------------------------------------------------------------------
# ۴. اجرای خودکار برنامه اصلی Streamlit
# ------------------------------------------------------------------
if __name__ == "__main__":
    install_packages()
    setup_external_tools()
    
    # ساخت فایل اصلی برنامه در صورت عدم وجود
    app_script_path = os.path.join(BASE_DIR, "app.py")
    
    if not os.path.exists(app_script_path):
        print("📄 Creating default app.py...")
        # کدی که از AI Studio می‌گیرید را می‌توانید اینجا جایگزین کنید
        with open(app_script_path, "w", encoding="utf-8") as f:
            f.write('''
import streamlit as st
st.title("🔎 جستجوگر آفلاین اسناد مهندسی")
st.write("کد اصلی سرچ AI Studio در این فایل قرار می‌گیرد.")
''')

    print("\n🚀 Launching Application...")
    subprocess.run([sys.executable, "-m", "streamlit", "run", app_script_path])
