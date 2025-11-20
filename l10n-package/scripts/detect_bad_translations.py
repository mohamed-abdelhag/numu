#!/usr/bin/env python3
import json
import os
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[3]
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
    en_texts = {k: v for k, v in en_data.items() if not k.startswith("@")}
    bad_translations = {}

    for lang, path in LANG_FILES.items():
        lang_data = load_arb(path)
        bad_keys = []
        for k, v in lang_data.items():
            if k.startswith("@"):
                continue
            if k in en_texts and en_texts[k].strip() == v.strip():
                bad_keys.append(k)
        bad_translations[lang] = bad_keys

    # Write output
    output_path = OUTPUT_DIR / "bad_translations_report.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(bad_translations, f, ensure_ascii=False, indent=2)

    print("⚠️ Bad translation detection complete. Output saved to /output.")

if __name__ == "__main__":
    main()
