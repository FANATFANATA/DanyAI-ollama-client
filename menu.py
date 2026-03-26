import os
import subprocess
import sys
import shutil
import time
from pathlib import Path
from typing import List, Set, Optional

ROOT: Path = Path(__file__).parent.resolve()
RELEASE_DIR: Path = ROOT / "release_output"


class Colors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"


def find_flutter() -> str:
    path = shutil.which("flutter")
    if path:
        return path
    default = r"C:\Users\Dmode\flutter\bin\flutter.bat"
    return default if os.path.exists(default) else "flutter"


FLUTTER: str = find_flutter()

ALLOWED_EXT: Set[str] = {
    ".dart",
    ".yaml",
    ".yml",
    ".json",
    ".txt",
    ".md",
    ".mdx",
    ".gradle",
    ".xml",
    ".properties",
    ".pro",
    ".cmake",
    ".cpp",
    ".c",
    ".h",
    ".hpp",
    ".py",
    ".sh",
    ".bat",
    ".ps1",
    ".plist",
    ".xcconfig",
    ".lock",
}

EXCLUDE_ALWAYS: Set[str] = {
    ".git",
    "build",
    ".dart_tool",
    ".idea",
    ".vscode",
    "__pycache__",
    "release_output",
}


def is_binary(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            chunk = f.read(8192)
            return b"\x00" in chunk
    except:
        return True


def run_dump(
    filename: str,
    include_dirs: Optional[List[str]] = None,
    exclude_dirs: Optional[List[str]] = None,
) -> None:
    output_path = ROOT / filename
    written = 0
    print(f"{Colors.OKCYAN}Генерация дампа: {filename}...{Colors.ENDC}")

    try:
        with open(output_path, "w", encoding="utf-8") as out:
            for root, dirs, files in os.walk(ROOT):
                rel_root = os.path.relpath(root, ROOT)
                root_parts = Path(rel_root).parts

                if any(ex in root_parts for ex in EXCLUDE_ALWAYS):
                    continue

                if include_dirs:
                    if rel_root != "." and not any(
                        root_parts[0] == inc for inc in include_dirs
                    ):
                        continue

                if exclude_dirs and any(root_parts[0] == exc for exc in exclude_dirs):
                    continue

                for f in sorted(files):
                    if f in {"menu.py", filename} or f.endswith(
                        ("_dump.txt", "project_dump.txt")
                    ):
                        continue

                    path = Path(root) / f
                    if path.suffix.lower() not in ALLOWED_EXT and path.suffix != "":
                        continue

                    if is_binary(path):
                        continue

                    try:
                        rel_path = path.relative_to(ROOT)
                        content = path.read_text(encoding="utf-8", errors="replace")
                        out.write(f"{rel_path}:\n{content}\n\n{'=' * 80}\n\n")
                        written += 1
                    except:
                        continue

        print(f"{Colors.OKGREEN}Дамп завершен. Файлов: {written}{Colors.ENDC}")

        if include_dirs is None or "lib" in include_dirs:
            print(f"{Colors.OKCYAN}Анализ проекта...{Colors.ENDC}")
            res = subprocess.run(
                [FLUTTER, "analyze"],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            with open(output_path, "a", encoding="utf-8") as out:
                out.write(
                    f"\nFLUTTER ANALYZE:\n{'=' * 80}\n\n{res.stdout}\n{res.stderr}"
                )
    except Exception as e:
        print(f"{Colors.FAIL}Ошибка: {e}{Colors.ENDC}")


def run_build(target: str) -> bool:
    print(f"\n{Colors.HEADER}--- Сборка: {target} ---{Colors.ENDC}")
    cmd = [FLUTTER, "build", target]
    if target == "ios":
        cmd.append("--no-codesign")
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if process.stdout:
            for line in process.stdout:
                print(line, end="")
        process.wait()
        if process.returncode == 0:
            print(f"\n{Colors.OKGREEN}[УСПЕХ: {target}]{Colors.ENDC}")
            return True
        else:
            print(f"\n{Colors.FAIL}[ОШИБКА: {target}]{Colors.ENDC}")
            return False
    except Exception as e:
        print(f"\n{Colors.FAIL}[ИСКЛЮЧЕНИЕ: {e}]{Colors.ENDC}")
        return False


def collect_builds() -> None:
    if not RELEASE_DIR.exists():
        RELEASE_DIR.mkdir()
    mapping = {
        "apk": ROOT / "build/app/outputs/flutter-apk/app-release.apk",
        "windows": ROOT / "build/windows/x64/runner/Release",
    }
    for name, path in mapping.items():
        if path.exists():
            dest = RELEASE_DIR / name
            if path.is_file():
                shutil.copy2(path, RELEASE_DIR / f"danyai_{name}{path.suffix}")
            else:
                if dest.exists():
                    shutil.rmtree(dest)
                shutil.copytree(path, dest)
            print(f"{Colors.OKGREEN}[СКОПИРОВАНО] {name}{Colors.ENDC}")
    if sys.platform == "win32":
        os.startfile(RELEASE_DIR)


def main() -> None:
    while True:
        print(
            f"\n{Colors.OKBLUE}{'='*50}\n{Colors.BOLD}{' DanyAI ULTIMATE MANAGER PRO ':^50}\n{Colors.OKBLUE}{'='*50}{Colors.ENDC}"
        )
        print(f"{Colors.OKCYAN}1.{Colors.ENDC}  Dump: Flutter Core (lib, yaml, md)")
        print(f"{Colors.OKCYAN}2.{Colors.ENDC}  Dump: Ollama Docs")
        print(f"{Colors.OKCYAN}3.{Colors.ENDC}  Dump: Android Native")
        print(f"{Colors.OKCYAN}4.{Colors.ENDC}  Dump: Windows Native")
        print(f"{Colors.OKCYAN}5.{Colors.ENDC}  Dump: FULL PROJECT")
        print(f"{Colors.OKBLUE}-{Colors.ENDC}" * 50)
        print(f"{Colors.OKGREEN}6.{Colors.ENDC}  Build: APK")
        print(f"{Colors.OKGREEN}7.{Colors.ENDC}  Build: Windows")
        print(f"{Colors.OKGREEN}8.{Colors.ENDC}  Build: ALL (APK + Windows)")
        print(f"{Colors.OKBLUE}-{Colors.ENDC}" * 50)
        print(f"{Colors.WARNING}9.{Colors.ENDC}  Clean & Pub Get")
        print(f"{Colors.WARNING}10.{Colors.ENDC} Pub Upgrade")
        print(f"{Colors.WARNING}11.{Colors.ENDC} Pub Outdated")
        print(f"{Colors.WARNING}12.{Colors.ENDC} Flutter Doctor")
        print(f"{Colors.OKGREEN}13.{Colors.ENDC} Collect & Open Release Folder")
        print(f"{Colors.FAIL}0.{Colors.ENDC}  Exit")

        choice = input(f"\n{Colors.BOLD}Выбор > {Colors.ENDC}").strip()

        if choice == "1":
            run_dump(
                "flutter_core_dump.txt",
                exclude_dirs=[
                    "android",
                    "windows",
                    "ios",
                    "macos",
                    "linux",
                    "web",
                    "ollama-docs",
                ],
            )
        elif choice == "2":
            run_dump("ollama_docs_dump.txt", include_dirs=["ollama-docs"])
        elif choice == "3":
            run_dump("android_native_dump.txt", include_dirs=["android"])
        elif choice == "4":
            run_dump("windows_native_dump.txt", include_dirs=["windows"])
        elif choice == "5":
            run_dump("full_project_dump.txt")
        elif choice == "6":
            run_build("apk")
        elif choice == "7":
            run_build("windows")
        elif choice == "8":
            run_build("apk")
            run_build("windows")
            collect_builds()
        elif choice == "9":
            subprocess.run([FLUTTER, "clean"], cwd=ROOT)
            subprocess.run([FLUTTER, "pub", "get"], cwd=ROOT)
        elif choice == "10":
            subprocess.run([FLUTTER, "pub", "upgrade"], cwd=ROOT)
        elif choice == "11":
            subprocess.run([FLUTTER, "pub", "outdated"], cwd=ROOT)
        elif choice == "12":
            subprocess.run([FLUTTER, "doctor"], cwd=ROOT)
        elif choice == "13":
            collect_builds()
        elif choice == "0":
            break


if __name__ == "__main__":
    main()
