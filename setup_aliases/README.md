# Ubuntu Server Alias Kurulumu

Bu script, Ubuntu Server sistemlerinde temel ve gelişmiş alias tanımlarını otomatik olarak kurar.

## Özellikler

- Temel dosya ve dizin alias'ları (ll, ld, cls, .., ...)
- Sistem durumu kontrolü (disk, mem, ports, ...)
- Paket yönetimi alias'ları (apt-update, apt-clean)
- Docker ve Docker Compose alias'ları
- Git alias'ları
- Kubernetes (kubectl) alias'ları

## Gereksinimler

- Ubuntu Server
- Bash shell
- Root veya sudo erişimi

## Kullanım

1. Scripti indirin ve çalıştırılabilir yapın:

```bash
chmod +x setup_aliases.sh
```

2. Scripti çalıştırın:

```bash
./setup_aliases.sh
```

3. Yeni terminal oturumlarında alias'lar otomatik olarak yüklenecektir.

## Yedekleme

Script, mevcut `~/.bash_aliases` dosyasını otomatik olarak yedekler (zaman damgası ile).

## Alias Listesi

### Temel

- `ll`: Detaylı dosya listesi
- `ld`: Sadece dizinler
- `cls`: Ekranı temizle
- `..`: Bir üst dizine git
- `disk`: Disk kullanımı
- `mem`: Bellek kullanımı

### Docker

- `dk`: docker
- `dkc`: docker container
- `dki`: docker images
- `dkps`: docker ps
- `dc`: docker-compose
- `dcu`: docker-compose up -d

### Git

- `gst`: git status
- `ga`: git add
- `gp`: git push
- `gco`: git checkout

### Kubernetes

- `k`: kubectl
- `kgp`: kubectl get pods
- `klogs`: kubectl logs -f

## Güvenlik

- Script, mevcut alias dosyasını yedekler
- Sadece kullanıcı dizininde değişiklik yapar
- Root erişimi gerektirmez (sudo gerekli işlemler için kullanılır)

## Sürüm

Sürüm: 1.1.0
Tarih: 2025-05-02
