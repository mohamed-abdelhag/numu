#!/usr/bin/env python3
"""
Batch translate missing strings from English to target languages.
Processes 50 strings at a time for much faster translation.
"""
import json
import os
import time
from googletrans import Translator

# ----------------------------
# 🔧 CONFIGURATION
# ----------------------------
BATCH_SIZE = 50  # Translate 50 strings at once
DELAY_BETWEEN_BATCHES = 1  # seconds

def generate_missing_translations():
    """
    Reads missing string keys from missing_strings_report.json,
    fetches their English text from app_en.arb,
    translates them in batches, and outputs per-language ARB files.
    """
    
    # ----------------------------
    # 📂 PATH SETUP
    # ----------------------------
    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(base_dir, "../../.."))
    
    english_arb_path = os.path.join(
        project_root, "cng_customer", "lib", "l10n", "app_en.arb"
    )
    missing_report_path = os.path.join(
        project_root, "python", "arb", "output", "missing_strings_report.json"
    )
    output_dir = os.path.join(project_root, "python", "arb", "output")
    os.makedirs(output_dir, exist_ok=True)
    
    print("📂 English ARB file:", english_arb_path)
    print("📂 Missing strings report:", missing_report_path)
    print("📂 Output directory:", output_dir)
    print("=" * 70)
    
    # ----------------------------
    # 📥 LOAD FILES
    # ----------------------------
    if not os.path.isfile(english_arb_path):
        raise FileNotFoundError(
            f"❌ English ARB file not found at: {english_arb_path}"
        )
    
    if not os.path.isfile(missing_report_path):
        raise FileNotFoundError(
            f"❌ Missing strings report not found at: {missing_report_path}"
        )
    
    with open(english_arb_path, "r", encoding="utf-8") as f:
        english_arb = json.load(f)
    
    with open(missing_report_path, "r", encoding="utf-8") as f:
        missing_report = json.load(f)
    
    # Filter out metadata keys (starting with @)
    english_strings = {
        k: v for k, v in english_arb.items() 
        if not k.startswith('@') and isinstance(v, str)
    }
    
    # ----------------------------
    # 🌍 TRANSLATE BY LANGUAGE
    # ----------------------------
    translator = Translator()
    
    for lang_code, keys in missing_report.items():
        print(f"\n{'=' * 70}")
        print(f"🌍 TRANSLATING TO: {lang_code.upper()}")
        print(f"📊 Total strings: {len(keys)}")
        print(f"⚙️  Batch size: {BATCH_SIZE}")
        print(f"{'=' * 70}\n")
        
        # Build list of (key, english_text) pairs
        to_translate = []
        for key in keys:
            english_value = english_strings.get(key)
            if english_value:
                to_translate.append((key, english_value))
            else:
                print(f"⚠️  Skipping '{key}' — not found in app_en.arb")
        
        if not to_translate:
            print(f"⚠️  No valid strings to translate for {lang_code}")
            continue
        
        # ----------------------------
        # 🔄 BATCH TRANSLATION
        # ----------------------------
        translated_output = {}
        total = len(to_translate)
        
        for i in range(0, total, BATCH_SIZE):
            batch = to_translate[i:i + BATCH_SIZE]
            batch_num = (i // BATCH_SIZE) + 1
            total_batches = (total + BATCH_SIZE - 1) // BATCH_SIZE
            
            print(f"\n📦 Batch {batch_num}/{total_batches} ({len(batch)} strings)")
            print("-" * 70)
            
            # Collect all English texts for this batch
            texts_to_translate = [text for _, text in batch]
            
            try:
                # Translate entire batch at once
                # Join with newline separator for batch translation
                combined_text = "\n###SEPARATOR###\n".join(texts_to_translate)
                
                translation_result = translator.translate(
                    combined_text, 
                    src='en', 
                    dest=lang_code
                )
                
                # Split the translated text back
                translated_texts = translation_result.text.split("\n###SEPARATOR###\n")
                
                # Handle case where separator might not be preserved perfectly
                if len(translated_texts) != len(batch):
                    print(f"⚠️  Batch translation split mismatch, falling back to individual...")
                    translated_texts = []
                    for key, text in batch:
                        try:
                            result = translator.translate(text, src='en', dest=lang_code)
                            translated_texts.append(result.text)
                            time.sleep(0.1)
                        except Exception as e:
                            print(f"✗ Error: {key} — {e}")
                            translated_texts.append(text)
                
                # Store results
                for (key, original), translated in zip(batch, translated_texts):
                    translated_output[key] = translated.strip()
                    print(f"✓ {key}")
                
                print(f"✅ Batch {batch_num} complete!")
                
            except Exception as e:
                print(f"❌ Batch translation failed: {e}")
                print("🔄 Falling back to individual translation...")
                
                # Fallback: translate one by one
                for key, text in batch:
                    try:
                        result = translator.translate(text, src='en', dest=lang_code)
                        translated_output[key] = result.text
                        print(f"✓ {key}")
                        time.sleep(0.1)
                    except Exception as err:
                        print(f"✗ Error: {key} — {err}")
                        translated_output[key] = text  # fallback to English
            
            # Delay between batches to avoid rate limiting
            if i + BATCH_SIZE < total:
                time.sleep(DELAY_BETWEEN_BATCHES)
        
        # ----------------------------
        # 💾 SAVE OUTPUT
        # ----------------------------
        output_file = os.path.join(
            output_dir, 
            f"missing_translations_{lang_code}.arb"
        )
        
        # Sort keys alphabetically
        sorted_output = {k: translated_output[k] for k in sorted(translated_output.keys())}
        
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(sorted_output, f, ensure_ascii=False, indent=2)
        
        print(f"\n{'=' * 70}")
        print(f"✅ COMPLETED: {lang_code.upper()}")
        print(f"📊 Translated: {len(translated_output)}/{total} strings")
        print(f"📄 Output: {output_file}")
        print(f"{'=' * 70}")
    
    print("\n" + "=" * 70)
    print("🎉 ALL TRANSLATIONS COMPLETE!")
    print("=" * 70)


if __name__ == "__main__":
    generate_missing_translations()