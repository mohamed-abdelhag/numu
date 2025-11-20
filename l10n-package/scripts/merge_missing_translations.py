import json
import os
import re

def merge_missing_translations():
    """
    Appends the translated missing strings to their respective app_XX.arb files.
    Handles proper JSON structure and indentation.
    """

    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(base_dir, "../../.."))

    # Define directories
    output_dir = os.path.join(project_root, "python", "arb", "output")
    l10n_dir = os.path.join(project_root, "cng_customer", "lib", "l10n")

    # Find all missing translation files like missing_translations_*.arb
    for filename in os.listdir(output_dir):
        if not filename.startswith("missing_translations_") or not filename.endswith(".arb"):
            continue

        lang_code = filename.replace("missing_translations_", "").replace(".arb", "")
        missing_path = os.path.join(output_dir, filename)
        target_arb_path = os.path.join(l10n_dir, f"app_{lang_code}.arb")

        print(f"\n{'='*60}")
        print(f"🧩 Merging translations for '{lang_code}'")
        print(f"Missing file: {missing_path}")
        print(f"Target ARB:   {target_arb_path}")
        print(f"{'='*60}")

        if not os.path.isfile(target_arb_path):
            print(f"⚠️ No target ARB found for '{lang_code}' — skipping.")
            continue

        # Load existing ARB content
        with open(target_arb_path, "r", encoding="utf-8") as f:
            target_text = f.read().strip()

        # Remove the last closing brace (if any)
        if target_text.endswith("}"):
            target_text = re.sub(r"\}\s*$", "", target_text)

        # Load missing translations
        with open(missing_path, "r", encoding="utf-8") as f:
            missing_data = json.load(f)

        # Prepare new formatted entries
        new_entries = []
        for key, value in missing_data.items():
            entry = f'  "{key}": {json.dumps(value, ensure_ascii=False)}'
            new_entries.append(entry)
        new_block = ",\n".join(new_entries)

        # Ensure proper comma placement
        if not target_text.endswith("{"):
            target_text += ",\n"

        # Merge and close JSON again
        merged_text = f"{target_text}{new_block}\n}}\n"

        # Clean double commas if any accident occurs
        merged_text = re.sub(r",\s*,", ",", merged_text)

        # Write back
        with open(target_arb_path, "w", encoding="utf-8") as f:
            f.write(merged_text)

        print(f"✅ Merged {len(missing_data)} entries into {target_arb_path}")

if __name__ == "__main__":
    merge_missing_translations()
