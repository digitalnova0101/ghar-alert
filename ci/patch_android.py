"""
`flutter create` ke baad Android Gradle files mein Firebase + notifications ki
zaroori settings jodta hai. GitHub Actions isko apne aap chalata hai.
"""
import re
import sys
from pathlib import Path

GMS_VERSION = "4.4.3"
DESUGAR = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'


def die(msg):
    print("PATCH ERROR:", msg)
    sys.exit(1)


def patch_settings(path: Path):
    text = path.read_text()
    if "com.google.gms.google-services" in text:
        return
    m = re.search(r'^(\s*)id\("com\.android\.application"\)[^\n]*\n', text, re.M)
    if not m:
        die(f"{path}: android application plugin line nahi mili")
    line = f'{m.group(1)}id("com.google.gms.google-services") version "{GMS_VERSION}" apply false\n'
    text = text[:m.end()] + line + text[m.end():]
    path.write_text(text)
    print("patched", path)


def patch_app(path: Path):
    text = path.read_text()

    # 1. google-services plugin
    if 'id("com.google.gms.google-services")' not in text:
        m = re.search(r'^(\s*)id\("dev\.flutter\.flutter-gradle-plugin"\)[^\n]*\n', text, re.M)
        if not m:
            die(f"{path}: flutter gradle plugin line nahi mili")
        text = text[:m.end()] + f'{m.group(1)}id("com.google.gms.google-services")\n' + text[m.end():]

    # 2. compileSdk 36, minSdk 24
    text, n = re.subn(r'compileSdk\s*=\s*[^\n]+', "compileSdk = 36", text, count=1)
    if n == 0:
        die(f"{path}: compileSdk nahi mila")
    text, n = re.subn(r'minSdk\s*=\s*[^\n]+', "minSdk = 24", text, count=1)
    if n == 0:
        die(f"{path}: minSdk nahi mila")

    # 3. desugaring (flutter_local_notifications ke liye zaroori)
    if "isCoreLibraryDesugaringEnabled" not in text:
        text, n = re.subn(r'compileOptions\s*\{\n',
                          "compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n",
                          text, count=1)
        if n == 0:
            die(f"{path}: compileOptions block nahi mila")
    if "desugar_jdk_libs" not in text:
        text = text.rstrip() + f"\n\ndependencies {{\n    {DESUGAR}\n}}\n"

    path.write_text(text)
    print("patched", path)


if __name__ == "__main__":
    android = Path(sys.argv[1] if len(sys.argv) > 1 else "android")
    settings = android / "settings.gradle.kts"
    app = android / "app" / "build.gradle.kts"
    if not settings.exists() or not app.exists():
        die("Kotlin DSL gradle files (.kts) nahi mili")
    patch_settings(settings)
    patch_app(app)
