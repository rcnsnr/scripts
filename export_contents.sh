#!/bin/bash

# -----------------------------
# Script: export_contents.sh
# Açıklama: Belirli dizinleri ve dosyaları hariç tutarak proje dizinindeki tüm
#           metin tabanlı dosyaların içeriklerini istenen formatta bir metin dosyasına yazdırır.
# Kullanım: ./export_contents.sh
# -----------------------------

OUTPUT_FILE="proje_icerikleri.txt"

EXCLUDE_DIRS=("__pycache__" "tail-db" "sil" "logs" "data" "venv" ".git" "myenv" ".vscode")
EXCLUDE_FILES=("export_contents.sh" "export_contents.v2.sh" ".env" "readme.md" "requirements.in" "roadmap.md" "__init__.py" "*.pyc" "docker-compose.ymlbak")
EXCLUDE_FILES+=("$OUTPUT_FILE")

ALLOWED_EXTENSIONS=("py" "sh" "html" "css" "js" "md" "txt" "json" "yaml" "yml" "xml" "ini" "cfg" "conf" "bat" "cmd")

PROJECT_ROOT=$(pwd)
ROOT_NAME=$(basename "$PROJECT_ROOT")

if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# İşlenen dosyaların listesini tutan bir array
PROCESSED_FILES=()

function traverse_directory() {
    local current_dir="$1"
    local relative_path="$2"

    for exclude in "${EXCLUDE_DIRS[@]}"; do
        if [ "$(basename "$current_dir")" == "$exclude" ]; then
            return
        fi
    done

    for entry in "$current_dir"/*; do
        if [ ! -e "$entry" ]; then
            continue
        fi

        if [ -d "$entry" ]; then
            if [ -z "$relative_path" ]; then
                new_relative_path="$(basename "$entry")"
            else
                new_relative_path="$relative_path/$(basename "$entry")"
            fi
            traverse_directory "$entry" "$new_relative_path"
        elif [ -f "$entry" ]; then
            if [ "$(basename "$entry")" == "$(basename "$OUTPUT_FILE")" ]; then
                continue
            fi

            filename=$(basename "$entry")
            skip_file=false
            for excl_file in "${EXCLUDE_FILES[@]}"; do
                if [[ "$filename" == $excl_file ]]; then
                    skip_file=true
                    break
                fi
            done

            if [ "$skip_file" = true ]; then
                continue
            fi

            extension="${filename##*.}"
            extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

            if [[ " ${ALLOWED_EXTENSIONS[@]} " =~ " ${extension_lower} " ]] || [ "$filename" == "Dockerfile" ]; then
                if [ -z "$relative_path" ]; then
                    full_path="${ROOT_NAME}/$filename"
                else
                    full_path="${ROOT_NAME}/${relative_path}/$filename"
                fi
                echo "$full_path" >> "$OUTPUT_FILE"
                PROCESSED_FILES+=("$full_path")

                echo "" >> "$OUTPUT_FILE"
                echo "--- Başlangıç ---" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
                cat "$entry" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
                echo "--- Bitiş ---" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            else
                echo "İzin verilmeyen uzantılı dosya atlandı: $entry" >&2
            fi
        fi
    done
}

traverse_directory "$PROJECT_ROOT" ""

echo "Dosya içerikleri '$OUTPUT_FILE' dosyasına başarıyla yazdırıldı."

# İşlenen dosyaları TREE başlığı altında yazdır
{
    echo "TREE"
    echo "-----"
    for file in "${PROCESSED_FILES[@]}"; do
        echo "$file"
    done
} >> "$OUTPUT_FILE"
