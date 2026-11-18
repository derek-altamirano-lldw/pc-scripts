import os
import shutil
import subprocess
from pathlib import Path

def check_qr_installed():
    """Verify that 'qr' is available and 'qr --version' executes without error."""
    if not shutil.which("qr"):
        return False
    
    try:
        subprocess.run(["qr", "--version"], capture_output=True, text=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def main():
    # Pre-check dependency
    if not check_qr_installed():
        print("\033[91mError: 'qr' command-line tool is missing or not functioning properly.\033[0m")
        print("\033[93mPlease install it by running:\033[0m")
        print("  pip install qrcode[pil]\n")
        return

    url = input("Enter the URL: ").strip().strip('"').strip("'")
    filename_input = input("Enter output file name or path (e.g., my_qr.svg): ").strip().strip('"').strip("'")

    if not url or not filename_input:
        print("URL and filename are required.")
        return

    # Ensure .svg extension
    if not filename_input.lower().endswith('.svg'):
        filename_input += '.svg'

    path_obj = Path(filename_input)

    # Resolve output path: if relative, default to Downloads
    if path_obj.is_absolute():
        output_path = path_obj
    else:
        downloads_dir = Path.home() / "Downloads"
        output_path = downloads_dir / path_obj

    # Create destination folder if it doesn't exist
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Execute the CLI tool and write output directly
    try:
        cmd = ["qr", "--factory=svg-path", url]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(result.stdout)

        print(f"\nSuccess! SVG saved to:\n{output_path}")
    except subprocess.CalledProcessError as e:
        print(f"\nError running qr command: {e.stderr}")
    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main()