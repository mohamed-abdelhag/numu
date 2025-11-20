#!/usr/bin/env python3
"""
Step 3: Replace hardcoded strings in Dart files with l10n references
Run AFTER flutter gen-l10n succeeds
"""
import os
import re
from pathlib import Path

# === Paths ===
# === Paths ===
ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "output"
INPUT_FILE = OUTPUT_DIR / "custom_unlocalized.txt"
APP_LIB = ROOT / "lib"

# === Exclusions ===
EXCLUDE_DIRS = {"l10n", "generated", ".dart_tool", "build"}

def make_key_from_text(text: str) -> str:
    """Generate same key as in step 2."""
    cleaned = re.sub(r'[^a-zA-Z0-9 ]+', '', text)
    parts = cleaned.strip().split()
    
    if not parts:
        return ""
    
    key = parts[0].lower() + "".join(p.capitalize() for p in parts[1:])
    
    if key and key[0].isdigit():
        key = "text" + key.capitalize()
    
    if not key or not any(c.isalpha() for c in key):
        return ""
    
    if not (key[0].isalpha() or key[0] == '_'):
        key = "text" + key.capitalize()
    
    if len(key) > 50:
        key = key[:50]
    
    return key

def parse_strings(input_file: Path) -> dict:
    """Parse strings and create text -> key mapping."""
    if not input_file.exists():
        print(f"🚫 Input file not found: {input_file}")
        return {}
    
    mapping = {}
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('- '):
                text = line[2:].strip()
                key = make_key_from_text(text)
                if key:
                    mapping[text] = key
    
    return mapping

def replace_in_file(file_path: Path, string_map: dict) -> bool:
    """Replace strings in a single Dart file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Error reading {file_path}: {e}")
        return False
    
    original_content = content
    replacements_made = []
    
    for text, key in string_map.items():
        # Escape special regex characters in the text
        escaped_text = re.escape(text)
        
        # Pattern to match the string in various contexts
        # Matches "text" or 'text' but not inside interpolation
        patterns = [
            # Simple string literals
            rf'(["\']){escaped_text}\1',
        ]
        
        for pattern in patterns:
            matches = list(re.finditer(pattern, content))
            
            for match in matches:
                # Check if this is inside a string interpolation
                start_pos = match.start()
                
                # Look back to check if we're in interpolation
                check_back = content[max(0, start_pos-10):start_pos]
                if '${' in check_back or '$' in check_back:
                    continue
                
                # Replace this occurrence
                old_match = match.group(0)
                new_text = f'context.l10n.{key}'
                content = content[:match.start()] + new_text + content[match.end():]
                replacements_made.append((text, key))
                break  # Only replace first occurrence of each pattern
    
    # Only write if changes were made
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"⚠️  Error writing {file_path}: {e}")
            return False
    
    return False

def process_directory(app_lib: Path, string_map: dict):
    """Process all Dart files in directory."""
    modified_files = []
    
    if not app_lib.exists():
        print(f"🚫 Directory not found: {app_lib}")
        return modified_files
    
    for root, dirs, files in os.walk(app_lib):
        # Exclude directories
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        relative_folder = Path(root).relative_to(app_lib)
        if any(excl in relative_folder.parts for excl in EXCLUDE_DIRS):
            continue
        
        for file in files:
            if not file.endswith('.dart'):
                continue
            if file.endswith('.g.dart') or file.endswith('.freezed.dart'):
                continue
            
            file_path = Path(root) / file
            
            if replace_in_file(file_path, string_map):
                relative_path = file_path.relative_to(app_lib)
                modified_files.append(str(relative_path))
                print(f"✏️  Modified: {relative_path}")
    
    return modified_files

def main():
    print("🔄 Replacing hardcoded strings with l10n references...\n")
    
    string_map = parse_strings(INPUT_FILE)
    
    if not string_map:
        print("⚠️  No strings found to replace!")
        return
    
    print(f"📋 Found {len(string_map)} strings to replace")
    print(f"📁 Scanning: {APP_LIB}\n")
    
    modified = process_directory(APP_LIB, string_map)
    
    if modified:
        print(f"\n✅ Modified {len(modified)} file(s)")
        print("\n📌 Next steps:")
        print("   1. Run: flutter gen-l10n")
        print("   2. Check for any compilation errors")
        print("   3. Test the app to ensure strings display correctly")
    else:
        print("\nℹ️  No files needed modification")
        print("   (All strings may already be localized)")

if __name__ == "__main__":
    main()