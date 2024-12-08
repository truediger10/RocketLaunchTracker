import os

def compile_files_to_text(output_file, directories):
    with open(output_file, 'w') as outfile:
        for directory in directories:
            for root, _, files in os.walk(directory):
                for file in files:
                    file_path = os.path.join(root, file)
                    # Write the file path
                    outfile.write(f"File: {file_path}\n")
                    outfile.write("-" * 80 + "\n")
                    try:
                        # Read the file contents
                        with open(file_path, 'r') as infile:
                            outfile.write(infile.read() + "\n")
                    except Exception as e:
                        # Handle errors (e.g., binary files or permission issues)
                        outfile.write(f"Error reading file: {e}\n")
                    outfile.write("-" * 80 + "\n\n")

if __name__ == "__main__":
    # Define directories to scan
    directories = [
        "./App",
        "./Services",
        "./Models",
        "./Utilities",
        "./ViewModels",
        "./Views"
    ]
    
    # Output file path on desktop
    output_file = os.path.expanduser("~/Desktop/compiled_files.txt")
    
    # Compile files
    compile_files_to_text(output_file, directories)
    print(f"Compilation complete. Output written to {output_file}")
