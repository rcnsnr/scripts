# 🔒 Secure Repo Scanner - Kullanım Kılavuzu

## Genel Bakış

`secure-repo-scanner.sh` herhangi bir kod repository'sinde hassas bilgileri otomatik olarak tarayan ve maskeleyen profesyonel bir güvenlik aracıdır.

## Özellikler

### ✅ Desteklenen Hassas Bilgi Türleri

1. **Credential'lar**
   - Şifreler (password, passwd, pwd)
   - Secret key'ler
   - API key'ler ve token'lar
   - Bearer token'lar

2. **Database Bilgileri**
   - Database şifreleri
   - Connection string'leri
   - Database kullanıcı adları
   - MySQL, PostgreSQL, MongoDB credential'ları

3. **Network Bilgileri**
   - Private IP adresleri (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
   - Public IP adresleri
   - Host isimleri
   - Server adresleri

4. **Cloud Provider Credential'ları**
   - AWS Access Key ID
   - AWS Secret Access Key
   - Azure connection string'leri
   - GCP service account key'leri

5. **Token ve Key'ler**
   - JWT token'lar
   - OAuth token'ları
   - GitHub Personal Access Token'lar
   - Private SSH key'ler
   - Encryption key'leri

6. **Communication**
   - SMTP şifreleri
   - Email credential'ları
   - Slack webhook'ları
   - Discord webhook'ları

7. **Diğer**
   - Base64 encoded credential'lar
   - Client ID ve Client Secret'lar
   - Application key'leri

### ✅ Desteklenen Dosya Türleri

- **Konfigürasyon:** `.env*`, `.yml`, `.yaml`, `.json`, `.xml`, `.properties`, `.conf`, `.config`, `.ini`, `.toml`
- **Kod:** `.php`, `.js`, `.ts`, `.jsx`, `.tsx`, `.py`, `.java`, `.go`, `.rb`, `.cs`, `.cpp`, `.c`, `.h`
- **Script:** `.sh`, `.bash`, `.sql`, `.gradle`
- **Build:** `.maven`, `.gradle`

### ✅ Güvenlik Özellikleri

- ✅ Otomatik backup oluşturma
- ✅ Dry-run modu (sadece tarama, maskeleme yok)
- ✅ Yanlış pozitif önleme (test değerleri, placeholder'lar)
- ✅ Detaylı raporlama
- ✅ Geri alma (rollback) desteği
- ✅ Binary dosya atlama
- ✅ Güvenli değer kontrolü

## Kurulum

### 1. Script'i İndirin

```bash
# Script dosyasını çalıştırılabilir yapın
chmod +x secure-repo-scanner.sh
```

### 2. Bağımlılıklar

Script aşağıdaki standart Unix araçlarını kullanır:

- `bash` (4.0+)
- `grep`
- `find`
- `sed`
- `awk`
- `date`
- `file`

Bu araçlar çoğu Linux/Unix sistemde varsayılan olarak bulunur.

## Kullanım

### Temel Kullanım

#### 1. Sadece Tarama (Dry-Run)

```bash
# Maskeleme yapmadan sadece hassas bilgileri tara
./secure-repo-scanner.sh --dry-run /path/to/repo
```

#### 2. Tarama ve Maskeleme

```bash
# Hassas bilgileri tara ve maskele
./secure-repo-scanner.sh /path/to/repo
```

### Gelişmiş Kullanım

#### 3. Custom Backup Dizini

```bash
./secure-repo-scanner.sh --backup-dir /tmp/my_backup /path/to/repo
```

#### 4. Custom Rapor Dosyası

```bash
./secure-repo-scanner.sh --report /tmp/security_report.txt /path/to/repo
```

#### 5. Belirli Dizinleri Hariç Tut

```bash
./secure-repo-scanner.sh -e tests -e docs -e examples /path/to/repo
```

#### 6. Backup Olmadan Maskeleme (TEHLİKELİ!)

```bash
./secure-repo-scanner.sh --no-backup /path/to/repo
```

### Kombine Kullanım

```bash
# Tam kontrollü tarama
./secure-repo-scanner.sh \
    --backup-dir /backup/myrepo \
    --report /reports/scan_$(date +%Y%m%d).txt \
    -e node_modules \
    -e vendor \
    -e .git \
    /path/to/repo
```

## Çıktı ve Raporlar

### Terminal Çıktısı

Script çalışırken renkli ve detaylı çıktı verir:

```text
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║           🔒 SECURE REPO SCANNER v1.0.0 🔒                           ║
║                                                                       ║
║           Hassas Bilgi Tarama ve Maskeleme Aracı                     ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

[INFO] Repository taranıyor: /path/to/repo
[INFO] Toplam dosya sayısı: 250

[1/250]
[INFO] Taranıyor: .env.example
  ├─ Pattern: password
  ├─ Line: 15
  ├─ Değer: MyS3cr3tP@ssw0rd
  └─ Maskelendi: ****

[SUCCESS] Dosya maskelendi: .env.example
...

📊 SONUÇ ÖZET:
  ├─ Bulunan hassas bilgi: 45
  ├─ Maskelenen dosya: 12
  ├─ Tarama süresi: 23s
  └─ Rapor: /path/to/repo/security_scan_report_20251017_173000.txt
```

### Rapor Dosyası

Script detaylı bir rapor dosyası oluşturur:

```text
═══════════════════════════════════════════════════════════════════════
              SECURE REPO SCANNER - GÜVENLİK TARAMA RAPORU
═══════════════════════════════════════════════════════════════════════

Tarama Başlangıç: 2025-10-17 17:30:00
Repository: /path/to/repo

File: .env.example
Pattern: password
Line: 15
Value: MyS3cr3tP@ssw0rd
---

File: config/database.php
Pattern: db_password
Line: 42
Value: db_p@ssw0rd123
---

═══════════════════════════════════════════════════════════════════════
                        TARAMA RAPORU ÖZET
═══════════════════════════════════════════════════════════════════════

Repository: /path/to/repo
Tarama Tarihi: 2025-10-17 17:30:23
Tarama Süresi: 23 saniye

Bulunan Hassas Bilgi: 45
Maskelenen Dosya: 12

Mod: MASKELEME YAPILDI

Backup Dizini: /path/to/repo/.backup_20251017_173000
Rapor Dosyası: /path/to/repo/security_scan_report_20251017_173000.txt
```

## Geri Alma (Rollback)

Maskeleme yanlış gittiyse geri alabilirsiniz:

```bash
# Backup'tan tüm dosyaları geri yükle
cp -r /path/to/backup/* /path/to/repo/

# Veya sadece belirli bir dosyayı geri yükle
cp /path/to/backup/.env.example /path/to/repo/.env.example
```

## Güvenlik Notları

### ⚠️ Önemli Uyarılar

1. **Backup Her Zaman Alın:** `--no-backup` kullanmayın!
2. **Dry-Run İle Test Edin:** İlk çalıştırmada `--dry-run` kullanın
3. **Version Control:** Maskelemeden önce git commit yapın
4. **Raporu Kontrol Edin:** Maskelenen değerleri raporda kontrol edin
5. **Test Edin:** Maskelemeden sonra uygulamanızı test edin

### ✅ En İyi Pratikler

```bash
# 1. Git commit yapın
git add .
git commit -m "Pre-security-scan checkpoint"

# 2. Dry-run ile test edin
./secure-repo-scanner.sh --dry-run /path/to/repo

# 3. Raporu inceleyin
cat security_scan_report_*.txt

# 4. Gerçek maskeleme yapın
./secure-repo-scanner.sh /path/to/repo

# 5. Değişiklikleri kontrol edin
git diff

# 6. Backup'ı saklayın
tar -czf backup.tar.gz .backup_*

# 7. Test edin
./run-tests.sh

# 8. Commit edin
git add .
git commit -m "Masked sensitive information"
```

## Yanlış Pozitif Önleme

Script aşağıdaki değerleri otomatik olarak güvenli kabul eder:

- `****` (zaten maskelenmiş)
- `password`, `secret`, `changeme` (placeholder'lar)
- `test`, `demo`, `sample`, `example`
- `localhost`, `127.0.0.1`, `0.0.0.0`
- Boş değerler
- 3 karakterden kısa değerler

## Özelleştirme

Script'i düzenleyerek özelleştirebilirsiniz:

### Yeni Pattern Eklemek

```bash
# Script'te SENSITIVE_PATTERNS array'ine ekleyin
declare -A SENSITIVE_PATTERNS=(
    ...
    ["custom_secret"]='(my[_-]?custom[_-]?secret)[[:space:]]*[:=][[:space:]]*["\047]?([^"\047[:space:]]{8,})["\047]?'
)
```

### Yeni Güvenli Değer Eklemek

```bash
# SAFE_VALUES array'ine ekleyin
SAFE_VALUES=(
    ...
    "my_test_value"
    "my_placeholder"
)
```

### Yeni Dosya Uzantısı Eklemek

```bash
# FILE_EXTENSIONS array'ine ekleyin
FILE_EXTENSIONS=(
    ...
    "*.custom"
    "*.myext"
)
```

## CI/CD Entegrasyonu

### GitHub Actions

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Run Security Scanner
        run: |
          chmod +x ./secure-repo-scanner.sh
          ./secure-repo-scanner.sh --dry-run .

      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: security-report
          path: security_scan_report_*.txt
```

### GitLab CI

```yaml
security-scan:
  stage: test
  script:
    - chmod +x ./secure-repo-scanner.sh
    - ./secure-repo-scanner.sh --dry-run .
  artifacts:
    paths:
      - security_scan_report_*.txt
    expire_in: 1 week
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

./secure-repo-scanner.sh --dry-run . > /dev/null 2>&1

if [ $? -eq 1 ]; then
    echo "⚠️  UYARI: Hassas bilgi tespit edildi!"
    echo "Lütfen maskelemeden önce kontrol edin."
    exit 1
fi
```

## Sorun Giderme

### Problem: "Permission denied"

```bash
# Çözüm: Script'e çalıştırma yetkisi verin
chmod +x secure-repo-scanner.sh
```

### Problem: "Command not found"

```bash
# Çözüm: Eksik bağımlılıkları yükleyin
# Debian/Ubuntu
sudo apt-get install grep findutils sed gawk coreutils file

# CentOS/RHEL
sudo yum install grep findutils sed gawk coreutils file
```

### Problem: Çok fazla yanlış pozitif

```bash
# Çözüm: Daha spesifik pattern'ler veya daha fazla güvenli değer ekleyin
# Script'i düzenleyin ve SAFE_VALUES array'ini genişletin
```

### Problem: Tarama çok yavaş

```bash
# Çözüm: Daha fazla dizini hariç tutun
./secure-repo-scanner.sh \
    -e node_modules \
    -e vendor \
    -e dist \
    -e build \
    /path/to/repo
```

## Sınırlamalar

1. **Binary dosyalar taranmaz** (güvenlik nedeniyle)
2. **Çok büyük dosyalar** (>100MB) yavaş taranabilir
3. **Regex pattern'leri** her edge case'i yakalamayabilir
4. **Encrypted dosyalar** taranamaz
5. **Compressed arşivler** (.zip, .tar.gz) içindeki dosyalar taranmaz

## Lisans

MIT License - Özgürce kullanabilir, değiştirebilir ve dağıtabilirsiniz.

## Katkıda Bulunma

Yeni pattern'ler, özellikler veya iyileştirmeler için pull request gönderebilirsiniz.

## Destek

Sorularınız için:

- GitHub Issues
- Email: <security@example.com>

---

**⚠️ DİKKAT:** Bu araç hassas bilgileri maskelemek için bir yardımcıdır. %100 garanti vermez. Her zaman manuel kontrol yapın!

**🔒 GÜVENLİK:** Maskelemeden önce MUTLAKA backup alın ve dry-run ile test edin!
