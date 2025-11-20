#!/usr/bin/env python3
"""
Step 2: Generate auto_extracted.arb from custom_unlocalized.txt
Outputs: auto_extracted.arb (manually merge into app_en.arb)
"""
import re
import json
from pathlib import Path

# === Paths ===
# === Paths ===
ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "output"
INPUT_FILE = OUTPUT_DIR / "custom_unlocalized.txt"
OUTPUT_ARB = OUTPUT_DIR / "auto_extracted.arb"

def make_key_from_text(text: str) -> str:
    """Generate valid camelCase Dart identifier from text."""
    # Remove punctuation and special chars
    cleaned = re.sub(r'[^a-zA-Z0-9 ]+', '', text)
    parts = cleaned.strip().split()
    
    if not parts:
        return ""
    
    # Build camelCase
    key = parts[0].lower() + "".join(p.capitalize() for p in parts[1:])
    
    # Fix if starts with number
    if key and key[0].isdigit():
        key = "text" + key.capitalize()
    
    # Ensure valid identifier
    if not key or not any(c.isalpha() for c in key):
        return ""
    
    if not (key[0].isalpha() or key[0] == '_'):
        key = "text" + key.capitalize()
    
    # Limit length
    if len(key) > 50:
        key = key[:50]
    
    return key

def parse_unlocalized(input_file: Path) -> list:
    """Parse custom_unlocalized.txt and return unique strings."""
    if not input_file.exists():
        print(f"🚫 Input file not found: {input_file}")
        return []
    
    strings = set()
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('- '):
                s = line[2:].strip()
                if s:
                    strings.add(s)
    
    return sorted(strings)

def generate_arb(strings: list) -> dict:
    """Generate ARB dictionary from strings."""
    arb_data = {}
    skipped = []
    duplicates = {}
    
    for text in strings:
        key = make_key_from_text(text)
        
        if not key:
            skipped.append(text)
            print(f"⚠️  Invalid key for: '{text}'")
            continue
        
        # Handle duplicate keys
        if key in arb_data:
            if key not in duplicates:
                duplicates[key] = [arb_data[key], text]
            else:
                duplicates[key].append(text)
            
            # Create unique key by appending number
            counter = 2
            new_key = f"{key}{counter}"
            while new_key in arb_data:
                counter += 1
                new_key = f"{key}{counter}"
            key = new_key
            print(f"⚠️  Duplicate key, using: {key}")
        
        # Add to ARB
        arb_data[key] = text
        arb_data[f"@{key}"] = {
            "description": f"Auto-extracted: {text[:60]}"
        }
        
        print(f"✅ {key} = '{text}'")
    
    return arb_data, skipped, duplicates

def save_arb(arb_data: dict, output_file: Path):
    """Save ARB file with proper formatting."""
    # Separate keys and metadata
    regular = {k: v for k, v in arb_data.items() if not k.startswith('@')}
    metadata = {k: v for k, v in arb_data.items() if k.startswith('@')}
    
    # Build sorted output
    sorted_data = {}
    for key in sorted(regular.keys()):
        sorted_data[key] = regular[key]
        meta_key = f"@{key}"
        if meta_key in metadata:
            sorted_data[meta_key] = metadata[meta_key]
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(sorted_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ Generated ARB with {len(regular)} entries")
    print(f"📄 Output: {output_file}")

def main():
    print("🔧 Generating ARB file from extracted strings...\n")
    
    strings = parse_unlocalized(INPUT_FILE)
    
    if not strings:
        print("⚠️  No strings found in input file!")
        return
    
    print(f"📋 Processing {len(strings)} unique strings...\n")
    
    arb_data, skipped, duplicates = generate_arb(strings)
    
    if arb_data:
        save_arb(arb_data, OUTPUT_ARB)
        
        if skipped:
            print(f"\n⚠️  Skipped {len(skipped)} strings with invalid keys")
        
        if duplicates:
            print(f"\n⚠️  Found {len(duplicates)} duplicate text strings:")
            for key, texts in duplicates.items():
                print(f"   {key}: {texts}")
        
        print(f"\n📌 Next step: Manually copy contents of {OUTPUT_ARB.name}")
        print(f"   into your app_en.arb file")
    else:
        print("❌ No valid ARB entries generated!")

if __name__ == "__main__":
    main()