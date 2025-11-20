#!/usr/bin/env python3
import os
import re
from pathlib import Path

# === Paths ===
ROOT = Path(__file__).resolve().parents[3]  # go up to the project root
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

APPS = ["cng_customer"]  # only scan customer app

# === Target text patterns ===
TEXT_PATTERNS = [
    # Widget constructors
    r'Text\s*\(\s*["\'](.*?)["\']',
    r'SelectableText\s*\(\s*["\'](.*?)["\']',
    r'RichText\s*\(\s*["\'](.*?)["\']',
    r'TextSpan\s*\(\s*text\s*:\s*["\'](.*?)["\']',

    # Common properties
    r'labelText\s*:\s*["\'](.*?)["\']',
    r'hintText\s*:\s*["\'](.*?)["\']',
    r'helperText\s*:\s*["\'](.*?)["\']',
    r'errorText\s*:\s*["\'](.*?)["\']',
    r'counterText\s*:\s*["\'](.*?)["\']',
    r'prefixText\s*:\s*["\'](.*?)["\']',
    r'suffixText\s*:\s*["\'](.*?)["\']',
    r'placeholder\s*:\s*["\'](.*?)["\']',
    r'tooltip\s*:\s*["\'](.*?)["\']',
    r'title\s*:\s*["\'](.*?)["\']',
    r'subtitle\s*:\s*["\'](.*?)["\']',
    r'header\s*:\s*["\'](.*?)["\']',
    r'footer\s*:\s*["\'](.*?)["\']',
    r'message\s*:\s*["\'](.*?)["\']',
    r'content\s*:\s*["\'](.*?)["\']',
    r'buttonText\s*:\s*["\'](.*?)["\']',
    r'cancelText\s*:\s*["\'](.*?)["\']',
    r'confirmText\s*:\s*["\'](.*?)["\']',
    r'label\s*:\s*["\'](.*?)["\']',
    r'tab\s*:\s*["\'](.*?)["\']',
    r'text\s*:\s*["\'](.*?)["\']',  # fallback catch-all
]

# Combine into one master regex
PATTERN = re.compile("|".join(TEXT_PATTERNS), re.DOTALL)

# Exclude certain lines entirely
EXCLUDE_LINES = re.compile(r'^\s*(import|export|part|debugPrint|print|logger\.|log\.|SharedLoggingUtility\.)', re.IGNORECASE)


def extract_ui_strings(file_path: Path):
    """Extract only UI-relevant strings from a Dart file."""
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Remove excluded lines
    content = "\n".join(
        [line for line in content.splitlines() if not EXCLUDE_LINES.match(line)]
    )

    matches = PATTERN.findall(content)
    extracted = []
    for match_tuple in matches:
        # Each regex alternation produces a tuple; only one group is non-empty
        for match in match_tuple:
            text = match.strip()
            if text:
                extracted.append(text)
    return extracted


def scan_app(app_name: str):
    """Walk through the app folder and collect localized strings grouped by folder."""
    app_path = ROOT / app_name / "lib"
    grouped = {}

    if not app_path.exists():
        print(f"🚫 {app_name}: lib folder not found.")
        return grouped

    for root, _, files in os.walk(app_path):
        dart_files = [f for f in files if f.endswith(".dart")]
        if not dart_files:
            continue

        relative_folder = Path(root).relative_to(app_path)
        folder_strings = set()

        for file in dart_files:
            file_path = Path(root) / file
            folder_strings.update(extract_ui_strings(file_path))

        if folder_strings:
            grouped[str(relative_folder)] = sorted(folder_strings)

    return grouped


def save_grouped_strings_as_text(app_name: str, grouped: dict):
    """Save grouped strings as a readable text file."""
    out_path = OUTPUT_DIR / f"{app_name}_unlocalized.txt"

    with open(out_path, "w", encoding="utf-8") as f:
        total = 0
        for folder, strings in sorted(grouped.items()):
            f.write(f"\n=== {folder} ===\n")
            for s in sorted(strings):
                f.write(f"- {s}\n")
                total += 1

    print(f"✅ {app_name}: Saved {total} UI strings → {out_path}")


def main():
    for app in APPS:
        grouped = scan_app(app)
        if grouped:
            save_grouped_strings_as_text(app, grouped)
        else:
            print(f"⚠️ {app}: No UI strings found or lib folder missing.")


if __name__ == "__main__":
    main()
