#!/bin/bash

################################################################################
# Secure Repo Scanner - Hassas Bilgi Tarama ve Maskeleme Aracı
# Version: 1.0.0
# Author: Cascade AI
# Date: 2025-10-17
#
# Bu script herhangi bir repository'de hassas bilgileri tarayıp maskeler:
# - Hard-coded şifreler ve credential'lar
# - API key'ler ve secret'lar
# - Database connection string'leri
# - IP adresleri ve host bilgileri
# - Email adresleri ve kullanıcı adları
# - Token'lar ve session key'leri
# - Private key'ler ve sertifikalar
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Renkli çıktı için ANSI kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global değişkenler
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=""
DRY_RUN=false
BACKUP_DIR=""
REPORT_FILE=""
FOUND_SECRETS=0
MASKED_FILES=0
SCAN_START_TIME=""

# Taranacak dosya uzantıları
FILE_EXTENSIONS=(
    "*.env*"
    "*.php"
    "*.js"
    "*.ts"
    "*.jsx"
    "*.tsx"
    "*.py"
    "*.java"
    "*.go"
    "*.rb"
    "*.cs"
    "*.cpp"
    "*.c"
    "*.h"
    "*.yml"
    "*.yaml"
    "*.json"
    "*.xml"
    "*.properties"
    "*.conf"
    "*.config"
    "*.ini"
    "*.toml"
    "*.sh"
    "*.bash"
    "*.sql"
    "*.gradle"
    "*.maven"
)

# Hariç tutulacak dizinler
EXCLUDE_DIRS=(
    ".git"
    "node_modules"
    "vendor"
    "venv"
    ".venv"
    "env"
    ".env"
    "dist"
    "build"
    "target"
    "__pycache__"
    ".pytest_cache"
    ".idea"
    ".vscode"
    "coverage"
    ".next"
    ".nuxt"
)

# Hassas bilgi pattern'leri (Regex)
declare -A SENSITIVE_PATTERNS=(
    # Şifreler ve Credential'lar
    ["password"]='(password|passwd|pwd|pass)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{6,})["\047]?'
    ["secret"]='(secret|secret_key|client_secret|api_secret)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{8,})["\047]?'
    ["api_key"]='(api[_-]?key|apikey|access[_-]?key)[[:space:]]*[:=][[:space:]]*["\047]?([A-Za-z0-9_\-]{16,})["\047]?'
    ["token"]='(token|auth[_-]?token|access[_-]?token|bearer)[[:space:]]*[:=][[:space:]]*["\047]?([A-Za-z0-9_\.\-]{20,})["\047]?'
    
    # Database Credentials
    ["db_password"]='(db[_-]?password|database[_-]?password|mysql[_-]?password|postgres[_-]?password)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{3,})["\047]?'
    ["db_user"]='(db[_-]?user|database[_-]?user|db[_-]?username)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{3,})["\047]?'
    ["connection_string"]='(connection[_-]?string|database[_-]?url|db[_-]?url)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047]{10,})["\047]?'
    
    # IP Adresleri ve Host'lar
    ["private_ip"]='(host|server|db[_-]?host|redis[_-]?host)[[:space:]]*[:=][[:space:]]*["\047]?(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})["\047]?'
    ["public_ip"]='[^0-9](([0-9]{1,3}\.){3}[0-9]{1,3})(?!\.)[^0-9]'
    
    # AWS Credentials
    ["aws_key"]='(aws[_-]?access[_-]?key[_-]?id|aws[_-]?secret[_-]?access[_-]?key)[[:space:]]*[:=][[:space:]]*["\047]?([A-Z0-9]{16,})["\047]?'
    
    # JWT Token'lar
    ["jwt"]='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    
    # Private Keys
    ["private_key"]='-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----'
    
    # Encryption Keys
    ["encryption_key"]='(encryption[_-]?key|encrypt[_-]?key|aes[_-]?key)[[:space:]]*[:=][[:space:]]*["\047]?([A-Za-z0-9+/=]{16,})["\047]?'
    
    # OAuth ve Client Credentials
    ["client_id"]='(client[_-]?id|application[_-]?id)[[:space:]]*[:=][[:space:]]*["\047]?([a-f0-9\-]{20,})["\047]?'
    
    # Email Credentials
    ["smtp_password"]='(smtp[_-]?password|mail[_-]?password|email[_-]?password)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{6,})["\047]?'
    
    # Slack/Discord Webhook'ları
    ["webhook"]='https://hooks\.slack\.com/services/[A-Za-z0-9+/]{44,}|https://discord\.com/api/webhooks/[0-9]{17,19}/[A-Za-z0-9_-]{68}'
    
    # GitHub Token'lar
    ["github_token"]='(github[_-]?token|gh[_-]?token|github[_-]?pat)[[:space:]]*[:=][[:space:]]*["\047]?(ghp_[A-Za-z0-9]{36})["\047]?'
    
    # Base64 encoded credentials
    ["base64_creds"]='(authorization|auth)[[:space:]]*[:=][[:space:]]*["\047]?[Bb]asic[[:space:]]+([A-Za-z0-9+/]{20,}={0,2})["\047]?'
)

# Güvenli değerler (Yanlış pozitif önleme)
SAFE_VALUES=(
    "****"
    "password"
    "secret"
    "your_password"
    "your_secret"
    "changeme"
    "example"
    "placeholder"
    "xxx"
    "yyy"
    "zzz"
    "test"
    "demo"
    "sample"
    "localhost"
    "127.0.0.1"
    "0.0.0.0"
    "example.com"
    "null"
    "undefined"
    ""
)

################################################################################
# Yardımcı Fonksiyonlar
################################################################################

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║           🔒 SECURE REPO SCANNER v1.0.0 🔒                           ║
║                                                                       ║
║           Hassas Bilgi Tarama ve Maskeleme Aracı                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1" >&2
}

show_usage() {
    cat << EOF
Kullanım: $(basename "$0") [SEÇENEKLER] <repo_path>

Seçenekler:
    -h, --help              Bu yardım mesajını göster
    -v, --version           Versiyon bilgisini göster
    -d, --dry-run           Sadece tarama yap, maskeleme yapma
    -b, --backup-dir DIR    Backup dizini (varsayılan: ./.backup_<timestamp>)
    -r, --report FILE       Rapor dosyası (varsayılan: ./security_scan_report.txt)
    -e, --exclude DIR       Hariç tutulacak dizin ekle (çoklu kullanılabilir)
    --no-backup             Backup almadan maskeleme yap (TEHLİKELİ!)
    --aggressive            Agresif mod (daha fazla pattern, daha fazla yanlış pozitif)

Örnekler:
    # Dry-run (sadece tarama)
    $(basename "$0") --dry-run /path/to/repo

    # Maskeleme ile tarama
    $(basename "$0") /path/to/repo

    # Custom backup dizini
    $(basename "$0") --backup-dir /tmp/backup /path/to/repo

    # Belirli dizinleri hariç tut
    $(basename "$0") -e tests -e docs /path/to/repo

EOF
}

show_version() {
    echo "Secure Repo Scanner v${SCRIPT_VERSION}"
}

check_dependencies() {
    local missing_deps=()
    
    for cmd in grep find sed awk date; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_critical "Eksik bağımlılıklar: ${missing_deps[*]}"
        exit 1
    fi
}

is_safe_value() {
    local value="$1"
    
    # Boş değer kontrolü
    if [ -z "$value" ]; then
        return 0
    fi
    
    # Güvenli değerler listesinde kontrol
    for safe_val in "${SAFE_VALUES[@]}"; do
        if [ "$value" = "$safe_val" ]; then
            return 0
        fi
    done
    
    # Çok kısa değerler (< 3 karakter)
    if [ ${#value} -lt 3 ]; then
        return 0
    fi
    
    return 1
}

create_backup() {
    local file="$1"
    local backup_path="${BACKUP_DIR}/${file#$REPO_ROOT/}"
    local backup_dir_path="$(dirname "$backup_path")"
    
    mkdir -p "$backup_dir_path"
    cp "$file" "$backup_path"
    
    log_info "Backup oluşturuldu: $backup_path"
}

mask_value() {
    local value="$1"
    echo "****"
}

build_find_command() {
    local cmd="find \"$REPO_ROOT\" -type f"
    
    # Dosya uzantıları ekle
    cmd="$cmd \("
    local first=true
    for ext in "${FILE_EXTENSIONS[@]}"; do
        if [ "$first" = true ]; then
            cmd="$cmd -name \"$ext\""
            first=false
        else
            cmd="$cmd -o -name \"$ext\""
        fi
    done
    cmd="$cmd \)"
    
    # Hariç tutulan dizinleri ekle
    for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
        cmd="$cmd -not -path \"*/${exclude_dir}/*\""
    done
    
    echo "$cmd"
}

################################################################################
# Ana Tarama Fonksiyonları
################################################################################

scan_file() {
    local file="$1"
    local file_has_secrets=false
    local temp_file="${file}.tmp"
    
    # Dosya okunabilir mi kontrol et
    if [ ! -r "$file" ]; then
        log_warning "Dosya okunamıyor: $file"
        return
    fi
    
    # Binary dosyaları atla
    if file "$file" | grep -q "executable\|binary"; then
        return
    fi
    
    log_info "Taranıyor: ${file#$REPO_ROOT/}"
    
    # Dosyayı temp dosyaya kopyala
    cp "$file" "$temp_file"
    
    # Her pattern için tara
    for pattern_name in "${!SENSITIVE_PATTERNS[@]}"; do
        local pattern="${SENSITIVE_PATTERNS[$pattern_name]}"
        local matches=0
        
        # Pattern'i dosyada ara
        while IFS= read -r line; do
            if echo "$line" | grep -qiE "$pattern"; then
                matches=$((matches + 1))
                
                # Değeri çıkar ve güvenli mi kontrol et
                local extracted_value=$(echo "$line" | grep -oiE "$pattern" | head -1 | awk -F'[=: \t]' '{print $NF}' | tr -d '"' | tr -d "'")
                
                if is_safe_value "$extracted_value"; then
                    continue
                fi
                
                file_has_secrets=true
                FOUND_SECRETS=$((FOUND_SECRETS + 1))
                
                local line_number=$(grep -n "$line" "$file" | head -1 | cut -d: -f1)
                
                echo "  ${MAGENTA}├─${NC} Pattern: ${YELLOW}${pattern_name}${NC}"
                echo "  ${MAGENTA}├─${NC} Line: ${CYAN}${line_number}${NC}"
                echo "  ${MAGENTA}├─${NC} Değer: ${RED}${extracted_value}${NC}"
                echo "  ${MAGENTA}└─${NC} Maskelendi: ${GREEN}****${NC}"
                echo "" >> "$REPORT_FILE"
                echo "File: ${file#$REPO_ROOT/}" >> "$REPORT_FILE"
                echo "Pattern: $pattern_name" >> "$REPORT_FILE"
                echo "Line: $line_number" >> "$REPORT_FILE"
                echo "Value: $extracted_value" >> "$REPORT_FILE"
                echo "---" >> "$REPORT_FILE"
                
                # Maskeleme yap (dry-run değilse)
                if [ "$DRY_RUN" = false ]; then
                    # Önce backup al
                    if [ ! -f "${BACKUP_DIR}/${file#$REPO_ROOT/}" ]; then
                        create_backup "$file"
                    fi
                    
                    # Değeri maskele
                    sed -i "s|${extracted_value}|****|g" "$temp_file"
                fi
            fi
        done < "$file"
    done
    
    # Değişiklikler varsa dosyayı güncelle
    if [ "$file_has_secrets" = true ]; then
        MASKED_FILES=$((MASKED_FILES + 1))
        
        if [ "$DRY_RUN" = false ]; then
            mv "$temp_file" "$file"
            log_success "Dosya maskelendi: ${file#$REPO_ROOT/}"
        else
            rm -f "$temp_file"
            log_warning "DRY-RUN: Dosya maskelenmedi: ${file#$REPO_ROOT/}"
        fi
    else
        rm -f "$temp_file"
    fi
}

scan_repository() {
    log_info "Repository taranıyor: $REPO_ROOT"
    log_info "Taranacak dosya türleri: ${FILE_EXTENSIONS[*]}"
    log_info "Hariç tutulan dizinler: ${EXCLUDE_DIRS[*]}"
    echo ""
    
    # Find komutu oluştur ve çalıştır
    local find_cmd=$(build_find_command)
    local files=$(eval "$find_cmd" 2>/dev/null)
    local total_files=$(echo "$files" | wc -l)
    local current_file=0
    
    log_info "Toplam dosya sayısı: $total_files"
    echo ""
    
    # Her dosyayı tara
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            current_file=$((current_file + 1))
            echo -e "${CYAN}[${current_file}/${total_files}]${NC}"
            scan_file "$file"
            echo ""
        fi
    done <<< "$files"
}

generate_report() {
    local end_time=$(date +%s)
    local duration=$((end_time - SCAN_START_TIME))
    
    cat << EOF >> "$REPORT_FILE"

═══════════════════════════════════════════════════════════════════════
                        TARAMA RAPORU ÖZET
═══════════════════════════════════════════════════════════════════════

Repository: $REPO_ROOT
Tarama Tarihi: $(date '+%Y-%m-%d %H:%M:%S')
Tarama Süresi: ${duration} saniye

Bulunan Hassas Bilgi: $FOUND_SECRETS
Maskelenen Dosya: $MASKED_FILES

Mod: $([ "$DRY_RUN" = true ] && echo "DRY-RUN (Maskeleme yapılmadı)" || echo "MASKELEME YAPILDI")

Backup Dizini: $BACKUP_DIR
Rapor Dosyası: $REPORT_FILE

═══════════════════════════════════════════════════════════════════════
EOF

    echo ""
    log_success "Tarama tamamlandı!"
    echo ""
    echo -e "${GREEN}📊 SONUÇ ÖZET:${NC}"
    echo -e "  ${CYAN}├─${NC} Bulunan hassas bilgi: ${RED}$FOUND_SECRETS${NC}"
    echo -e "  ${CYAN}├─${NC} Maskelenen dosya: ${GREEN}$MASKED_FILES${NC}"
    echo -e "  ${CYAN}├─${NC} Tarama süresi: ${YELLOW}${duration}s${NC}"
    echo -e "  ${CYAN}└─${NC} Rapor: ${BLUE}$REPORT_FILE${NC}"
    echo ""
    
    if [ "$DRY_RUN" = false ] && [ $FOUND_SECRETS -gt 0 ]; then
        log_warning "Hassas bilgiler maskelendi. Backup'ı kontrol edin: $BACKUP_DIR"
        log_warning "Geri almak için: cp -r $BACKUP_DIR/* $REPO_ROOT/"
    fi
}

################################################################################
# Ana Program
################################################################################

main() {
    local no_backup=false
    
    # Argüman parsing
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -r|--report)
                REPORT_FILE="$2"
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE_DIRS+=("$2")
                shift 2
                ;;
            --no-backup)
                no_backup=true
                shift
                ;;
            --aggressive)
                log_warning "Aggressive mode aktif - daha fazla yanlış pozitif olabilir"
                shift
                ;;
            -*)
                log_error "Bilinmeyen seçenek: $1"
                show_usage
                exit 1
                ;;
            *)
                REPO_ROOT="$1"
                shift
                ;;
        esac
    done
    
    # Banner göster
    print_banner
    
    # Bağımlılık kontrolü
    check_dependencies
    
    # Repo path kontrolü
    if [ -z "$REPO_ROOT" ]; then
        log_error "Repository path belirtilmedi!"
        show_usage
        exit 1
    fi
    
    # Repo var mı kontrolü
    if [ ! -d "$REPO_ROOT" ]; then
        log_critical "Repository bulunamadı: $REPO_ROOT"
        exit 1
    fi
    
    # Absolute path'e çevir
    REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
    
    # Varsayılan değerler
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="${REPO_ROOT}/.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ -z "$REPORT_FILE" ]; then
        REPORT_FILE="${REPO_ROOT}/security_scan_report_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    # Backup dizini oluştur
    if [ "$DRY_RUN" = false ] && [ "$no_backup" = false ]; then
        mkdir -p "$BACKUP_DIR"
        log_success "Backup dizini oluşturuldu: $BACKUP_DIR"
    fi
    
    # Rapor dosyası oluştur
    cat << EOF > "$REPORT_FILE"
═══════════════════════════════════════════════════════════════════════
              SECURE REPO SCANNER - GÜVENLİK TARAMA RAPORU
═══════════════════════════════════════════════════════════════════════

Tarama Başlangıç: $(date '+%Y-%m-%d %H:%M:%S')
Repository: $REPO_ROOT

EOF
    
    SCAN_START_TIME=$(date +%s)
    
    # Ana tarama
    scan_repository
    
    # Rapor oluştur
    generate_report
    
    # Çıkış kodu
    if [ $FOUND_SECRETS -gt 0 ]; then
        exit 1
    else
        log_success "Hassas bilgi bulunamadı. Repository güvenli görünüyor!"
        exit 0
    fi
}

# Trap ile temizlik
trap 'log_error "Script kesintiye uğradı!"; exit 130' INT TERM

# Ana programı çalıştır
main "$@"
