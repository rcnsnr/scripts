#!/bin/bash
# Dosya: ~/setup_aliases.sh
# Açıklama: Ubuntu Server için temel ve Docker/Git/Kubectl alias tanımlarını oluşturur.
# Sürüm: 1.1.0
# Tarih: 2025-05-02

set -euo pipefail

# Basit log fonksiyonu: zaman damgası ile bilgi mesajı verir
LOG() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*"
}

ALIAS_FILE="$HOME/.bash_aliases"
BACKUP_FILE="$HOME/.bash_aliases.bak_$(date +%Y%m%d_%H%M%S)"

# 1) Var olan alias dosyasını yedekle
if [[ -f "$ALIAS_FILE" ]]; then
    LOG "Mevcut alias dosyası bulundu. Yedekleniyor: $BACKUP_FILE"
    cp "$ALIAS_FILE" "$BACKUP_FILE"
else
    LOG "Önceki alias dosyası bulunamadı. Yeni oluşturulacak."
fi

# 2) Alias tanımlarını dosyaya yaz
LOG "Alias tanımları $ALIAS_FILE dosyasına yazılıyor..."
cat << 'EOF' > "$ALIAS_FILE"
# Temel Alias Tanımları - otomatik oluşturuldu

## Dosya ve dizin
alias ll='ls -alF'
alias ld='ls -lF | grep "^d"'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias disk='df -h | grep -v snap'
alias mem='free -h'
alias here='pwd'
alias psa='ps auxf'
alias ports='sudo netstat -tulpn'
alias sysstatus='systemctl list-units --type=service --state=running'
alias ips='ip -c a'
alias connections='ss -tuna'

## Paket yönetimi
alias apt-update='sudo apt update && sudo apt upgrade -y'
alias apt-clean='sudo apt autoremove -y && sudo apt clean'

## SSH (anahtar kullanımı)
alias ssh='ssh -i ~/.ssh/id_rsa'

# Docker alias’ları
alias dk='docker'
alias dkc='docker container'
alias dki='docker images'
alias dkps='docker ps'
alias dkstop='docker stop'
alias dkrm='docker rm'
alias dkrmi='docker rmi'
alias dklogs='docker logs -f'

# Docker-Compose alias’ları
alias dc='docker-compose'
alias dcu='dc up -d'
alias dcd='dc down'
alias dclogs='dc logs -f'

# Git alias’ları
alias gst='git status'
alias ga='git add'
alias gcmsg='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glg='git log --oneline --graph --all'
alias gbd='git branch -d'

# Kubectl alias’ları
alias k='kubectl'
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgall='kubectl get all --all-namespaces'
alias kdps='kubectl describe pods'
alias klogs='kubectl logs -f'
alias kexec='kubectl exec -it'
alias kdel='kubectl delete'

EOF
LOG "Alias tanımları oluşturuldu."

# 3) .bashrc içinde alias dosyasını etkinleştir
if ! grep -q "if \\[ -f ~/.bash_aliases \\]; then . ~/.bash_aliases; fi" "$HOME/.bashrc"; then
    LOG ".bashrc dosyasına alias yükleme bloğu ekleniyor."
    cat << 'EOB' >> "$HOME/.bashrc"

# Alias dosyasını yükle
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOB
else
    LOG ".bashrc içinde alias bloğu zaten mevcut."
fi

# 4) Geçerli oturuma uygula
LOG "Alias’lar bu oturuma yükleniyor..."
# Hata olursa ilerlemesini kesme, sadece bilgi ver
set +e
source "$ALIAS_FILE" && LOG "Alias’lar başarıyla yüklendi."
set -e

LOG "İşlem tamamlandı. Yeni terminal oturumlarında alias’lar otomatik aktif olacak."
