#!/usr/bin/env python3
import json
import os
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[3]  # go up to project root
L10N_DIR = ROOT / "cng_customer" / "lib" / "l10n"
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

EN_FILE = L10N_DIR / "app_en.arb"
LANG_FILES = {
    "ar": L10N_DIR / "app_ar.arb",
    "bn": L10N_DIR / "app_bn.arb",
}

def load_arb(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)

def main():
    en_data = load_arb(EN_FILE)
    en_keys = {k for k in en_data.keys() if not k.startswith("@")}
    missing = {}

    for lang, path in LANG_FILES.items():
        data = load_arb(path)
        lang_keys = {k for k in data.keys() if not k.startswith("@")}
        missing_keys = sorted(en_keys - lang_keys)
        missing[lang] = missing_keys

    # Write JSON report
    report_path = OUTPUT_DIR / "missing_strings_report.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(missing, f, ensure_ascii=False, indent=2)

    # Write summary
    summary_path = OUTPUT_DIR / "missing_summary.txt"
    with open(summary_path, "w", encoding="utf-8") as f:
        for lang, keys in missing.items():
            f.write(f"--- Missing keys in {lang.upper()} ---\n")
            if keys:
                for k in keys:
                    f.write(f"  {k}\n")
            else:
                f.write("  None ✅\n")
            f.write("\n")

    print("✅ Missing string check complete. Output saved to /output.")

if __name__ == "__main__":
    main()
