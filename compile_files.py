#!/usr/bin/env python3

import os

def compile_files_to_text(output_file, directories):
    with open(output_file, 'w', encoding='utf-8') as outfile:
        for directory in directories:
            if not os.path.exists(directory):
                outfile.write(f"Directory not found: {directory}\n")
                outfile.write("=" * 80 + "\n\n")
                continue
            
            outfile.write(f"Directory: {directory}\n")
            outfile.write("=" * 80 + "\n\n")
            
            for root, _, files in os.walk(directory):
                for file in files:
                    file_path = os.path.join(root, file)
                    outfile.write(f"File: {file_path}\n")
                    outfile.write("-" * 80 + "\n")
                    try:
                        with open(file_path, 'r', encoding='utf-8') as infile:
                            content = infile.read()
                            outfile.write(content + "\n")
                    except UnicodeDecodeError:
                        outfile.write("[Binary or non-text file]\n")
                    except Exception as e:
                        outfile.write(f"[Error reading file: {e}]\n")
                    outfile.write("-" * 80 + "\n\n")

def generate_directory_tree(base_path, output_file):
    with open(output_file, 'a', encoding='utf-8') as outfile:
        outfile.write("Project Directory Tree\n")
        outfile.write("=" * 80 + "\n")
        for root, dirs, files in os.walk(base_path):
            level = root.replace(base_path, '').count(os.sep)
            indent = ' ' * 4 * level
            outfile.write(f"{indent}{os.path.basename(root)}/\n")
            sub_indent = ' ' * 4 * (level + 1)
            for file in files:
                outfile.write(f"{sub_indent}{file}\n")
        outfile.write("=" * 80 + "\n\n")

if __name__ == "__main__":
    # Define base path and target directories
    base_directory = os.path.expanduser("~/Desktop/RocketLaunchTracker")
    directories = [
        os.path.join(base_directory, "App"),
        os.path.join(base_directory, "Services"),
        os.path.join(base_directory, "Models"),
        os.path.join(base_directory, "Utilities"),
        os.path.join(base_directory, "ShareExtension"),
        os.path.join(base_directory, "ViewModels"),
        os.path.join(base_directory, "Views")
    ]
    
    # Output file path on Desktop
    output_file = os.path.expanduser("~/Desktop/compiled_files.txt")
    
    # Compile files
    compile_files_to_text(output_file, directories)
    
    # Generate directory tree
    generate_directory_tree(base_directory, output_file)
    
    print(f"✅ Compilation complete. Output written to {output_file}")
