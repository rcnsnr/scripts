# Secure Repo Scanner - Örnek Kullanım Senaryoları

## Senaryo 1: İlk Kez Kullanım

### Adım 1: Mevcut Durumu Kaydet

```bash
# Git commit ile snapshot al
cd /path/to/your/repo
git add .
git commit -m "Checkpoint before security scan"
git tag -a "pre-scan-v1" -m "Before security masking"
```

### Adım 2: Dry-Run ile Test

```bash
# Sadece tarama yap, hiçbir değişiklik yapma
./secure-repo-scanner.sh --dry-run /path/to/your/repo

# Çıktı örneği:
# [INFO] Repository taranıyor: /path/to/your/repo
# [INFO] Toplam dosya sayısı: 342
# 
# [1/342]
# [INFO] Taranıyor: .env.example
#   ├─ Pattern: password
#   ├─ Line: 15
#   ├─ Değer: MySecretPassword123
#   └─ Maskelendi: ****
# 
# [WARNING] DRY-RUN: Dosya maskelenmedi: .env.example
# ...
# 
# 📊 SONUÇ ÖZET:
#   ├─ Bulunan hassas bilgi: 87
#   ├─ Maskelenen dosya: 0 (DRY-RUN)
#   ├─ Tarama süresi: 34s
#   └─ Rapor: security_scan_report_20251017_180000.txt
```

### Adım 3: Raporu İncele

```bash
# Raporu oku
cat security_scan_report_20251017_180000.txt

# Veya grep ile filtrele
grep "Pattern:" security_scan_report_20251017_180000.txt | sort | uniq -c

# Çıktı:
# 34 Pattern: password
# 23 Pattern: api_key
# 15 Pattern: private_ip
# 10 Pattern: db_password
#  5 Pattern: secret
```

### Adım 4: Gerçek Maskeleme

```bash
# Gerçek maskeleme yap (backup otomatik alınır)
./secure-repo-scanner.sh /path/to/your/repo

# Backup konumu not et
# Backup dizini: /path/to/your/repo/.backup_20251017_180500
```

### Adım 5: Değişiklikleri Kontrol Et

```bash
# Git diff ile değişiklikleri incele
git diff

# Örnek çıktı:
# diff --git a/.env.example b/.env.example
# --- a/.env.example
# +++ b/.env.example
# -DB_PASSWORD="MySecretPassword123"
# +DB_PASSWORD="****"
```

### Adım 6: Commit Et

```bash
git add .
git commit -m "Security: Masked sensitive credentials"
git tag -a "post-scan-v1" -m "After security masking"
```

---

## Senaryo 2: Büyük Monorepo Tarama

### Çoklu Dizinleri Hariç Tut

```bash
./secure-repo-scanner.sh \
    -e node_modules \
    -e vendor \
    -e dist \
    -e build \
    -e coverage \
    -e .next \
    -e .nuxt \
    -e public/assets \
    -e storage/logs \
    /path/to/monorepo

# Neden hariç tutuyoruz?
# - node_modules: 3rd party kod
# - vendor: 3rd party kod
# - dist/build: Build output
# - coverage: Test coverage reports
# - public/assets: Binary dosyalar
# - storage/logs: Log dosyaları
```

---

## Senaryo 3: CI/CD Pipeline Entegrasyonu

### GitHub Actions

```bash
# .github/workflows/security-scan.yml oluştur
cat > .github/workflows/security-scan.yml << 'EOF'
name: Security Scan

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  security-scan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Run Security Scanner
        run: |
          chmod +x ./tools/secure-repo-scanner.sh
          ./tools/secure-repo-scanner.sh --dry-run .

      - name: Check for Secrets
        run: |
          if grep -q "Bulunan hassas bilgi: [1-9]" security_scan_report_*.txt; then
            echo "❌ Hassas bilgi tespit edildi!"
            cat security_scan_report_*.txt
            exit 1
          else
            echo "✅ Hassas bilgi bulunamadı"
          fi

      - name: Upload Security Report
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: security-scan-report
          path: security_scan_report_*.txt
          retention-days: 30
EOF
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit oluştur
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "🔍 Güvenlik taraması yapılıyor..."

# Sadece staged dosyaları tara
git diff --cached --name-only > /tmp/staged_files.txt

# Security scanner'ı sadece staged dosyalar için çalıştır
./tools/secure-repo-scanner.sh --dry-run . > /tmp/scan_output.txt 2>&1

# Hassas bilgi var mı kontrol et
if grep -q "Bulunan hassas bilgi: [1-9]" /tmp/scan_output.txt; then
    echo "❌ Hassas bilgi tespit edildi!"
    echo ""
    grep "Pattern:" /tmp/scan_output.txt | head -10
    echo ""
    echo "Lütfen hassas bilgileri maskeleyin veya .gitignore'a ekleyin."
    exit 1
else
    echo "✅ Güvenlik kontrolü başarılı"
    exit 0
fi
EOF

chmod +x .git/hooks/pre-commit
```

---

## Senaryo 4: Çoklu Environment Yönetimi

### Production ve Staging Ayrımı

```bash
# Production repo'yu tara ve maskele
./secure-repo-scanner.sh \
    --backup-dir /backups/prod_backup_$(date +%Y%m%d) \
    --report /reports/prod_security_$(date +%Y%m%d).txt \
    /var/www/production

# Staging repo'yu tara ama maskeleme
./secure-repo-scanner.sh \
    --dry-run \
    --report /reports/staging_security_$(date +%Y%m%d).txt \
    /var/www/staging

# İki raporu karşılaştır
diff /reports/prod_security_$(date +%Y%m%d).txt \
     /reports/staging_security_$(date +%Y%m%d).txt
```

---

## Senaryo 5: Docker İçinde Kullanım

### Dockerfile

```bash
# Dockerfile oluştur
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    grep \
    findutils \
    sed \
    gawk \
    coreutils \
    file \
    && rm -rf /var/lib/apt/lists/*

COPY secure-repo-scanner.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/secure-repo-scanner.sh

WORKDIR /scan

ENTRYPOINT ["/usr/local/bin/secure-repo-scanner.sh"]
CMD ["--help"]
EOF

# Build et
docker build -t secure-scanner:1.0 .

# Kullan
docker run -v /path/to/repo:/scan secure-scanner:1.0 --dry-run /scan
```

---

## Senaryo 6: Scheduled Tarama (Cron)

### Günlük Otomatik Tarama

```bash
# Cron job oluştur
cat > /etc/cron.daily/security-scan << 'EOF'
#!/bin/bash

REPOS=(
    "/var/www/app1"
    "/var/www/app2"
    "/opt/backend"
)

REPORT_DIR="/var/reports/security"
mkdir -p "$REPORT_DIR"

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo")
    date_stamp=$(date +%Y%m%d_%H%M%S)

    echo "Taranıyor: $repo"

    /usr/local/bin/secure-repo-scanner.sh \
        --dry-run \
        --report "$REPORT_DIR/${repo_name}_${date_stamp}.txt" \
        "$repo"

    # Hassas bilgi bulunduysa email gönder
    if [ $? -eq 1 ]; then
        mail -s "⚠️  Güvenlik Uyarısı: $repo_name" \
             security@company.com \
             < "$REPORT_DIR/${repo_name}_${date_stamp}.txt"
    fi
done

# Eski raporları temizle (30 günden eski)
find "$REPORT_DIR" -name "*.txt" -mtime +30 -delete
EOF

chmod +x /etc/cron.daily/security-scan
```

---

## Senaryo 7: Microservices Toplu Tarama

### Tüm Servisleri Tara

```bash
#!/bin/bash

SERVICES_ROOT="/opt/microservices"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_REPORT="/tmp/master_security_report_${TIMESTAMP}.txt"

echo "═══════════════════════════════════════════════════════" > "$MASTER_REPORT"
echo "       MİCROSERVICE GÜVENLİK TARAMASI - ÖZET RAPOR" >> "$MASTER_REPORT"
echo "       Tarih: $(date '+%Y-%m-%d %H:%M:%S')" >> "$MASTER_REPORT"
echo "═══════════════════════════════════════════════════════" >> "$MASTER_REPORT"
echo "" >> "$MASTER_REPORT"

# Her microservice'i tara
for service_dir in "$SERVICES_ROOT"/*/; do
    service_name=$(basename "$service_dir")

    echo "🔍 Taranıyor: $service_name"

    ./secure-repo-scanner.sh \
        --dry-run \
        --report "/tmp/${service_name}_report.txt" \
        "$service_dir"

    # Sonuçları master raporda topla
    echo "Servis: $service_name" >> "$MASTER_REPORT"
    grep "Bulunan hassas bilgi:" "/tmp/${service_name}_report.txt" >> "$MASTER_REPORT"
    grep "Maskelenen dosya:" "/tmp/${service_name}_report.txt" >> "$MASTER_REPORT"
    echo "---" >> "$MASTER_REPORT"
done

echo "" >> "$MASTER_REPORT"
echo "Tüm servis raporları /tmp/ dizininde" >> "$MASTER_REPORT"

# Master raporu göster
cat "$MASTER_REPORT"
```

---

## Senaryo 8: Legacy Kod Temizliği

### Adım Adım Temizlik

```bash
# 1. Mevcut durumu analiz et
./secure-repo-scanner.sh --dry-run /path/to/legacy > initial_scan.txt

# Bulunan sorunları kategorize et
grep "Pattern:" initial_scan.txt | sort | uniq -c > pattern_summary.txt

# Çıktı:
# 156 Pattern: password
#  89 Pattern: api_key
#  67 Pattern: private_ip
#  45 Pattern: db_password

# 2. En kritik olanlardan başla (password'ler)
# Manuel olarak .env dosyalarını düzenle
vim .env.example
vim config/database.php

# 3. İkinci taramayı yap
./secure-repo-scanner.sh --dry-run /path/to/legacy > second_scan.txt

# 4. İlerlemeyi karşılaştır
diff initial_scan.txt second_scan.txt | grep "Bulunan hassas bilgi:"

# 5. Otomatik maskeleme ile bitir
./secure-repo-scanner.sh /path/to/legacy
```

---

## Senaryo 9: Hata Durumunda Geri Alma

### Rollback İşlemi

```bash
# Maskeleme yaptınız ama bir şeyler ters gitti

# 1. Backup dizinini bul
BACKUP_DIR=$(ls -td .backup_* | head -1)
echo "Backup dizini: $BACKUP_DIR"

# 2. Tam geri yükleme
cp -r "$BACKUP_DIR"/* .

# 3. Git ile geri al
git checkout .

# 4. Veya sadece belirli dosyaları geri yükle
cp "$BACKUP_DIR/.env.example" .
cp "$BACKUP_DIR/config/database.php" config/

# 5. Değişiklikleri kontrol et
git status
git diff
```

---

## Senaryo 10: Raporlama ve Metrikler

### Metrik Toplama

```bash
#!/bin/bash

# Son 30 günün raporlarını analiz et
REPORT_DIR="/var/reports/security"

echo "📊 SON 30 GÜN GÜVENLİK METRİKLERİ"
echo "=================================="
echo ""

# Toplam tarama sayısı
total_scans=$(find "$REPORT_DIR" -name "*.txt" -mtime -30 | wc -l)
echo "Toplam Tarama: $total_scans"

# Toplam bulunan hassas bilgi
total_secrets=$(grep "Bulunan hassas bilgi:" "$REPORT_DIR"/*.txt 2>/dev/null | \
                awk '{sum+=$NF} END {print sum}')
echo "Toplam Hassas Bilgi: $total_secrets"

# En çok bulunan pattern'ler
echo ""
echo "En Çok Bulunan Pattern'ler:"
grep "Pattern:" "$REPORT_DIR"/*.txt 2>/dev/null | \
    awk '{print $NF}' | \
    sort | uniq -c | sort -rn | head -5

# Haftalık trend
echo ""
echo "Haftalık Trend:"
for week in {0..3}; do
    start_day=$((week * 7))
    end_day=$(((week + 1) * 7))

    count=$(find "$REPORT_DIR" -name "*.txt" -mtime -$end_day -mtime +$start_day | wc -l)
    echo "Hafta $((4-week)): $count tarama"
done
```

---

## En İyi Pratikler Özeti

### ✅ Her Zaman Yapın

1. Git commit ile checkpoint alın
2. Dry-run ile test edin
3. Raporu inceleyin
4. Backup'ı saklayın
5. Değişiklikleri test edin

### ❌ Asla Yapmayın

1. `--no-backup` kullanmayın
2. Backup'sız maskeleme yapmayın
3. Raporu okumadan commit etmeyin
4. Production'da test etmeyin
5. Manuel backup almadan rollback yapmayın

### 🎯 Öneriler

1. CI/CD pipeline'ına entegre edin
2. Scheduled scan'ler yapın
3. Pre-commit hook kullanın
4. Metrik toplayın
5. Security awareness eğitimi verin

---

**Son Güncelleme:** 17 Ekim 2025  
**Versiyon:** 1.0.0
