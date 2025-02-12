#!/bin/bash
set -e  # Hata durumunda script'i durdur

OUTPUT_DIR="./"
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S-UTC")
OUTPUT_FILE="repo-to-text_${TIMESTAMP}.txt"

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
    "monitoring/victoriametrics/indexdb/"
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
    "export_content*.sh"
    "export_folder*.sh"
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

# Çıkış dosyasını temizle
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

echo "Aşağıda projenin tüm repo içeriğini paylaştım. docs/talimatlar.md ve diğer .md dosyalarını oku hafızana al. talimatlara ve **ÇOK ÖNEMLİ!** yazan kısımlara kati bir şekilde uyarak geliştirmeye devam et." > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Directory: $ROOT_NAME" >> "$OUTPUT_FILE"
#echo "" >> "$OUTPUT_FILE"

# Dizin yapısını ekle
echo "Directory Structure:" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

# Dizin yapısını oluştur
#tree -a -I "$(IFS=\|; echo "${EXCLUDE_DIRS[*]}")" >> "$OUTPUT_FILE"
tree -a -I "$(IFS=\|; echo "${EXCLUDE_DIRS[*]}|${EXCLUDE_FILES[*]}")" >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Dosya içeriğini ekleyen fonksiyon
function process_file() {
    local file_path="$1"
    local relative_path="${file_path#$PROJECT_ROOT/}"
    
    echo "Contents of $relative_path:" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat "$file_path" >> "$OUTPUT_FILE"
    
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Dizin içinde gezerek dosyaları işleyen fonksiyon
function traverse_directory() {
    local current_dir="$1"
    
    for entry in "$current_dir"/*; do
        if [ ! -e "$entry" ]; then
            continue
        fi
        
        # Dizinleri hariç tut
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

            # Dosya hariç tutma kuralları
            for excl_file in "${EXCLUDE_FILES[@]}"; do
                if [[ "$filename" == $excl_file || "$filename" == *$excl_file ]]; then
                    skip_file=true
                    break
                fi
            done

            if [ "$skip_file" = true ]; then
                continue
            fi

            # Uzantı kontrolü
            extension="${filename##*.}"
            if [[ " ${ALLOWED_EXTENSIONS[@]} " =~ " ${extension} " || "$filename" == "Dockerfile" ]]; then
                process_file "$entry"
            fi
        fi
    done
}

# Dizinleri ve içerikleri işleyin
traverse_directory "$PROJECT_ROOT"

echo "Repo içerikleri '$OUTPUT_FILE' dosyasına başarıyla yazdırıldı."

