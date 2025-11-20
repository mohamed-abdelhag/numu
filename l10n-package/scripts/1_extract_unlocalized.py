#!/usr/bin/env python3
"""
Step 1: Extract unlocalized UI strings from Flutter app
Outputs: custom_unlocalized.txt
Handles multi-line patterns like:
  Text(
    'string on next line'
  )
"""
import os
import re
from pathlib import Path

# === Paths ===
# === Paths ===
ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
APP_LIB = ROOT / "lib"
OUTPUT_FILE = OUTPUT_DIR / "custom_unlocalized.txt"

# === Exclusions ===
EXCLUDE_DIRS = {"l10n", "generated", ".dart_tool", "build"}
EXCLUDE_FILES = {"*.g.dart", "*.freezed.dart"}

# Exclude lines with logging, imports, debug, etc.
EXCLUDE_LINE_PATTERNS = [
    r'^\s*(import|export|part)\s',
    r'(debugPrint|print|log\.|logger\.|SharedLoggingUtility\.)',
]
EXCLUDE_LINE_REGEX = re.compile('|'.join(EXCLUDE_LINE_PATTERNS), re.IGNORECASE)

# === UI Text Patterns (Multi-line aware) ===
# These patterns will work across multiple lines
UI_TEXT_PATTERNS = [
    # Text widgets - handles newlines between Text( and 'string'
    r'Text\s*\(\s*["\']([^"\']+)["\']',
    r'SelectableText\s*\(\s*["\']([^"\']+)["\']',
    
    # TextSpan with property name
    r'TextSpan\s*\(\s*text\s*:\s*["\']([^"\']+)["\']',
    
    # Input decoration properties
    r'labelText\s*:\s*["\']([^"\']+)["\']',
    r'hintText\s*:\s*["\']([^"\']+)["\']',
    r'helperText\s*:\s*["\']([^"\']+)["\']',
    r'errorText\s*:\s*["\']([^"\']+)["\']',
    r'prefixText\s*:\s*["\']([^"\']+)["\']',
    r'suffixText\s*:\s*["\']([^"\']+)["\']',
    r'counterText\s*:\s*["\']([^"\']+)["\']',
    
    # Common UI properties
    r'tooltip\s*:\s*["\']([^"\']+)["\']',
    r'placeholder\s*:\s*["\']([^"\']+)["\']',
    r'semanticLabel\s*:\s*["\']([^"\']+)["\']',
    
    # Dialog/Snackbar content
    r'SnackBar\s*\(\s*content\s*:\s*Text\s*\(\s*["\']([^"\']+)["\']',
    
    # AppBar/Card/ListTile titles
    r'title\s*:\s*Text\s*\(\s*["\']([^"\']+)["\']',
    r'subtitle\s*:\s*Text\s*\(\s*["\']([^"\']+)["\']',
    r'label\s*:\s*Text\s*\(\s*["\']([^"\']+)["\']',
]

# === Validation ===
def is_valid_ui_string(text: str) -> bool:
    """Check if string should be localized."""
    text = text.strip()
    
    # Must have content
    if not text or len(text) < 2:
        return False
    
    # Must contain letters
    if not any(c.isalpha() for c in text):
        return False
    
    # Exclude code patterns
    code_patterns = [
        r'\$\{',           # ${} interpolation
        r'\$\w+',          # $variable
        r'widget\.',       # widget properties
        r'\?\s*["\']',     # ternary
        r'==|!=|<=|>=',    # comparisons
        r'^\w+\(\)',       # function calls
        r'^\d+$',          # just numbers
        r'setState',       # setState
        r'context\.',      # context.something
    ]
    
    for pattern in code_patterns:
        if re.search(pattern, text):
            return False
    
    # Exclude common non-UI strings
    non_ui = [
        'null', 'true', 'false', 'const', 'var', 'final', 'return',
        'async', 'await', 'void', 'class', 'extends', 'implements',
        'http', 'https', 'www', '.com', '.json', '.png', '.jpg',
        'widget', 'build', 'state',
    ]
    
    if text.lower() in non_ui or any(x in text.lower() for x in ['.com', 'http', 'www.', '.json']):
        return False
    
    return True

def clean_content(content: str) -> str:
    """Remove comments and unwanted content."""
    # Remove single-line comments
    content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
    # Remove multi-line comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    return content

def extract_from_file(file_path: Path) -> set:
    """Extract valid UI strings from a single Dart file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Error reading {file_path}: {e}")
        return set()
    
    # Clean content
    content = clean_content(content)
    
    # Check each line for exclusions
    lines = content.split('\n')
    clean_lines = []
    for line in lines:
        if not EXCLUDE_LINE_REGEX.search(line):
            clean_lines.append(line)
    
    # Rejoin for multi-line matching
    content = '\n'.join(clean_lines)
    
    extracted = set()
    
    # Try each pattern
    for pattern_str in UI_TEXT_PATTERNS:
        pattern = re.compile(pattern_str, re.DOTALL | re.MULTILINE)
        matches = pattern.findall(content)
        
        for match in matches:
            # Handle both single matches and tuples from groups
            if isinstance(match, tuple):
                for text in match:
                    if text and is_valid_ui_string(text):
                        extracted.add(text.strip())
            else:
                if match and is_valid_ui_string(match):
                    extracted.add(match.strip())
    
    return extracted

def scan_directory(app_lib: Path) -> dict:
    """Scan directory and group strings by folder."""
    grouped = {}
    
    if not app_lib.exists():
        print(f"🚫 Directory not found: {app_lib}")
        return grouped
    
    for root, dirs, files in os.walk(app_lib):
        # Exclude directories
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        # Get relative folder path
        relative_folder = Path(root).relative_to(app_lib)
        
        # Skip if in excluded directory
        if any(excl in relative_folder.parts for excl in EXCLUDE_DIRS):
            continue
        
        folder_strings = set()
        
        for file in files:
            # Skip non-Dart and generated files
            if not file.endswith('.dart'):
                continue
            if file.endswith('.g.dart') or file.endswith('.freezed.dart'):
                continue
            
            file_path = Path(root) / file
            file_strings = extract_from_file(file_path)
            if file_strings:
                folder_strings.update(file_strings)
        
        if folder_strings:
            grouped[str(relative_folder)] = sorted(folder_strings)
    
    return grouped

def save_output(grouped: dict, output_file: Path):
    """Save extracted strings to text file."""
    with open(output_file, 'w', encoding='utf-8') as f:
        total = 0
        
        for folder, strings in sorted(grouped.items()):
            f.write(f"\n=== {folder} ===\n")
            for s in strings:
                f.write(f"- {s}\n")
                total += 1
        
        # Add summary at the end
        f.write(f"\n=== SUMMARY ===\n")
        f.write(f"Total folders: {len(grouped)}\n")
        f.write(f"Total strings: {total}\n")
    
    print(f"✅ Extracted {total} UI strings from {len(grouped)} folders")
    print(f"📄 Output: {output_file}")

def main():
    print("🔍 Scanning for unlocalized UI strings...")
    print(f"📁 App lib: {APP_LIB}")
    print(f"🚫 Excluding: {', '.join(EXCLUDE_DIRS)}\n")
    
    grouped = scan_directory(APP_LIB)
    
    if grouped:
        save_output(grouped, OUTPUT_FILE)
    else:
        print("⚠️  No UI strings found!")

if __name__ == "__main__":
    main()