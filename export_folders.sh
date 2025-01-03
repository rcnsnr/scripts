#!/bin/bash

# -----------------------------
# Script: export_contents.sh
# Açıklama: Proje dizin yapısını ve metin tabanlı dosyaların içeriklerini dışa aktarır.
# Kullanım: ./export_contents.sh
# -----------------------------

set -e  # Hata durumunda script'i durdur

OUTPUT_DIR="./exports/"
mkdir -p "$OUTPUT_DIR"

EXCLUDE_DIRS=(
    "__pycache__"
    ".git"
    "node_modules"
    "venv"
    ".vscode"
    "dist"
    "build"
    "logs"
    ".next"
    ".pytest_cache"
    ".mypy_cache"
    "cache"
    "coverage"
    "docker"
    ".idea"
    ".env"
    "exports"
)

EXCLUDE_FILES=(
    "*.lock"
    "*.pyc"
    "*.log"
    "*.env"
    "*.bak"
    "package-lock.json"
    "yarn.lock"
    "pnpm-lock.yaml"
    "export_contents.sh"
    ".gitignore"
    ".dockerignore"
    "repo-to-text_*"
)

ALLOWED_EXTENSIONS=(
    "py"
    "ts"
    "js"
    "jsx"
    "tsx"
    "html"
    "css"
    "scss"
    "md"
    "txt"
    "json"
    "yaml"
    "yml"
    "ini"
    "cfg"
    "conf"
    "Dockerfile"
)

PROJECT_ROOT=$(pwd)
ROOT_NAME=$(basename "$PROJECT_ROOT")

# Dosya içeriğini ekleyen fonksiyon
function process_file() {
    local file_path="$1"
    local relative_path="${file_path#$current_subdir/}"
    
    echo "Contents of $relative_path:" >> "$sub_output_file"
    echo '```' >> "$sub_output_file"
    
    cat "$file_path" >> "$sub_output_file"
    
    echo '```' >> "$sub_output_file"
    echo "" >> "$sub_output_file"
}

# Dizin içinde gezerek dosyaları işleyen fonksiyon
function traverse_directory() {
    local current_dir="$1"
    
    for entry in "$current_dir"/*; do
        if [ ! -e "$entry" ]; then
            continue
        fi

        # Exports dizininde işlem yapmayı önle
        if [[ "$entry" == "$OUTPUT_DIR"* ]]; then
            continue
        fi
        
        if [ -d "$entry" ]; then
            skip_dir=false
            for exclude in "${EXCLUDE_DIRS[@]}"; do
                if [[ "$entry" == *"$exclude"* ]]; then
                    skip_dir=true
                    break
                fi
            done
            if [ "$skip_dir" = true ]; then
                continue
            fi
            traverse_directory "$entry"
        elif [ -f "$entry" ]; then
            filename=$(basename "$entry")
            skip_file=false

            for excl_file in "${EXCLUDE_FILES[@]}"; do
                if [[ "$filename" == $excl_file || "$filename" == *$excl_file ]]; then
                    skip_file=true
                    break
                fi
            done

            if [ "$skip_file" = true ]; then
                continue
            fi

            extension="${filename##*.}"
            if [[ " ${ALLOWED_EXTENSIONS[@]} " =~ " ${extension} " || "$filename" == "Dockerfile" ]]; then
                process_file "$entry"
            fi
        fi
    done
}

# Kök dizin altındaki birinci seviye dizinleri işleyin
for subdir in "$PROJECT_ROOT"/*/; do
    if [ -d "$subdir" ]; then
        subdir_name=$(basename "$subdir")
        sub_output_file="${OUTPUT_DIR}${subdir_name}.txt"
        current_subdir="$subdir"
        
        # exports dizinini atla
        if [[ "$subdir_name" == "exports" ]]; then
            continue
        fi
        
        echo "Processing subdirectory: $subdir_name"
        
        echo "Directory: $subdir_name" > "$sub_output_file"
        echo "" >> "$sub_output_file"
        
        echo "Directory Structure:" >> "$sub_output_file"
        echo '```' >> "$sub_output_file"
        tree -a -I "$(IFS=\|; echo "${EXCLUDE_DIRS[*]}")" "$subdir" >> "$sub_output_file"
        echo '```' >> "$sub_output_file"
        echo "" >> "$sub_output_file"
        
        traverse_directory "$subdir"
        
        echo "$subdir_name içeriği '$sub_output_file' dosyasına yazdırıldı."
    fi
done

echo "Tüm alt dizinlerin içeriği '$OUTPUT_DIR' altına başarıyla yazdırıldı."
