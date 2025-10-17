# Medya Sunucusu Docker Compose Yapılandırması

Bu proje, medya yönetimi için kapsamlı bir Docker Compose yapılandırması sağlar. Sonarr, Radarr, Prowlarr, Lidarr, Bazarr ve qBittorrent servislerini içerir.

## Servisler

### Sonarr
- **Port:** 8989
- **Açıklama:** TV dizisi yönetim sistemi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/sonarr`

### Radarr
- **Port:** 7878
- **Açıklama:** Film yönetim sistemi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/radarr`

### Prowlarr
- **Port:** 9696
- **Açıklama:** Torrent indeksi yönetim sistemi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/prowlarr`

### Lidarr
- **Port:** 8686
- **Açıklama:** Müzik yönetim sistemi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/lidarr`

### Bazarr
- **Port:** 6767
- **Açıklama:** Altyazı yönetim sistemi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/bazaar`

### qBittorrent
- **Port:** 8080 (Web UI), 6881 (Torrent)
- **Açıklama:** Torrent istemcisi
- **Konfigürasyon:** `/mnt/4CA6BC377086A62B/MEDIA/configs/qbittorrent`

## Kullanım

1. Docker ve Docker Compose'un yüklü olduğundan emin olun.
2. Yapılandırma dizinlerinin mevcut olduğundan emin olun.
3. Komutu çalıştırın:

```bash
docker-compose up -d
```

## Ağ Yapılandırması

Tüm servisler `mediacenter` ağında çalışır (172.19.0.0/16 subnet).

## Zaman Dilimi

Tüm servisler Europe/Istanbul (GMT+03) zaman dilimine ayarlanmıştır.

## Notlar

- Konfigürasyon yolları sisteminize göre uyarlanmalıdır.
- İlk çalıştırmada servisler yapılandırma dosyalarını oluşturacaktır.
