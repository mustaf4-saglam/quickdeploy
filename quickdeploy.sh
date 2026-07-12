#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$PROJECT_DIR/.version"
ENV_FILE="$PROJECT_DIR/.deploy.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}🚀 QuickDeploy${NC} ${DIM}Yönetim Aracı${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}\n"
}

load_config() {
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    else
        echo -e "  ${RED}✗${NC} .deploy.env bulunamadı! './quickdeploy.sh ayarla' komutunu çalıştırın."
        return 1
    fi
}

get_version() {
    if [ -f "$VERSION_FILE" ]; then cat "$VERSION_FILE"; else echo "1.0.0"; fi
}

set_version() { echo "$1" > "$VERSION_FILE"; }

bump_version() {
    local current=$(get_version)
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    echo "${major}.${minor}.$((patch + 1))"
}

cmd_deploy() {
    print_header
    cd "$PROJECT_DIR"
    if ! load_config; then return 1; fi

    echo -e "  ${BOLD}🛠️ Adım 1: Derleniyor (${BUILD_COMMAND})...${NC}"
    eval "$BUILD_COMMAND" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
         echo -e "  ${RED}✗${NC} Derleme hatası!"
         return 1
    fi
    echo -e "  ${GREEN}✓${NC} Derleme tamamlandı."
    
    echo -e "  ${BOLD}☁️ Adım 2: Sunucuya yükleniyor...${NC}"
    node deploy.js
    
    echo -e "\n  ${GREEN}🎉 İŞLEM TAMAMLANDI!${NC}\n"
}

cmd_yayinla() {
    print_header
    cd "$PROJECT_DIR"
    if ! load_config; then return 1; fi
    
    if [ ! -d ".git" ]; then git init > /dev/null 2>&1; fi
    
    local changes=$(git diff --name-only 2>/dev/null)
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
    
    if [ -n "$changes" ] || [ -n "$untracked" ]; then
        echo -ne "  ${BOLD}Güncelleme açıklaması:${NC} "
        read -r msg
        msg=${msg:-"Güncelleme"}
        
        local new_version=$(bump_version)
        set_version "$new_version"
        
        git add . 2>/dev/null
        git commit -m "v${new_version} - ${msg}" --quiet 2>/dev/null
        git tag "v${new_version}" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} v${new_version} kaydedildi."
    else
        echo -e "  ${GREEN}✓${NC} Değişiklik yok."
    fi
    
    echo ""
    cmd_deploy
}

cmd_ayarla() {
    print_header
    echo -e "  ${BOLD}Yapılandırma Ayarları${NC}\n"
    
    read -p "  Proje Adı (örn: my-app): " p_name
    read -p "  Build Komutu (örn: npm run build): " b_cmd
    read -p "  Yerel Çıktı Klasörü (örn: ./out): " l_dir
    read -p "  Uzak Sunucu Klasörü (örn: /htdocs): " r_dir
    
    echo -e "\n  ${BOLD}FTP Bilgileri${NC}"
    read -p "  Sunucu (örn: ftp.site.com): " f_host
    read -p "  Kullanıcı: " f_user
    read -sp "  Şifre: " f_pass
    echo ""
    
    cat <<EOF > "$ENV_FILE"
PROJECT_NAME="${p_name:-my-project}"
BUILD_COMMAND="${b_cmd:-npm run build}"
LOCAL_DIR="${l_dir:-./out}"
REMOTE_DIR="${r_dir:-/htdocs}"
EXCLUDE_DIRS="db,.git,node_modules"

FTP_HOST="${f_host}"
FTP_USER="${f_user}"
FTP_PASSWORD="${f_pass}"
EOF
    
    echo -e "\n  ${GREEN}✓${NC} Ayarlar .deploy.env dosyasına kaydedildi!"
    grep -q ".deploy.env" .gitignore 2>/dev/null || echo -e ".deploy.env\n.deploy-cache.json" >> .gitignore
}

cmd_yardim() {
    print_header
    echo -e "  ${BOLD}Komutlar:${NC}"
    echo -e "  ${GREEN}yayinla${NC}      Git'e kaydet + Derle + Yükle"
    echo -e "  ${GREEN}deploy${NC}       Sadece derle ve yükle"
    echo -e "  ${GREEN}ayarla${NC}       Proje ve FTP ayarlarını yap (.deploy.env)"
}

cd "$PROJECT_DIR"
case "${1:-yardim}" in
    yayinla|y)       cmd_yayinla ;;
    deploy|u)        cmd_deploy ;;
    ayarla|c)        cmd_ayarla ;;
    yardim|h)        cmd_yardim ;;
    *)               echo -e "${RED}Bilinmeyen komut:${NC} $1"; cmd_yardim ;;
esac
