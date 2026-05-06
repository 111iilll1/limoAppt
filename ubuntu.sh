#!/bin/bash
#############################################
# 🐧 Tom's Ubuntu/WSL 자동 설치 스크립트
# 용도: 웹서버 + 개발 환경 구축 
#############################################

set -e  # 에러 발생시 중단

echo "=========================================="
echo "🐧 Tom's Ubuntu Setup Script 시작!"
echo "=========================================="

# 0. 기존 apt 락 해제
echo ""
echo "🔓 [0/9] apt 락 해제..."
sudo killall apt apt-get unattended-upgr 2>/dev/null || true
sleep 2
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo dpkg --configure -a 2>/dev/null || true
echo "   ✅ 락 해제 완료"

# 1. 시스템 업데이트
echo ""
echo "📦 [1/9] 시스템 업데이트..."
sudo apt update && sudo apt upgrade -y

# 2. 한국어/이모지 폰트
echo ""
echo "🇰🇷 [2/9] 한국어 & 이모지 폰트 설치..."
sudo apt install fonts-noto-cjk fonts-noto-color-emoji -y

# 3. 기본 도구
echo ""
echo "🔧 [3/9] 기본 도구 설치..."
sudo apt install curl wget git unzip nano htop tree ncdu neofetch net-tools -y

# Node.js & live-server
echo ""
echo "📦 Node.js & live-server 설치..."
sudo apt install nodejs npm -y
sudo npm install -g live-server || npm install -g live-server

# 4. Nginx 웹서버
echo ""
echo "🌐 [4/9] Nginx 설치..."
sudo apt install nginx -y
sudo systemctl enable nginx 2>/dev/null || true
sudo systemctl start nginx 2>/dev/null || sudo service nginx start || true

# 5. PHP 설치
echo ""
echo "🐘 [5/9] PHP 설치..."
sudo apt install php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip -y

# PHP 버전 확인
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "   PHP 버전: $PHP_VERSION"

# 6. MariaDB 설치
echo ""
echo "🗄️ [6/9] MariaDB 설치..."
sudo apt install mariadb-server mariadb-client -y
sudo systemctl enable mariadb 2>/dev/null || true
sudo systemctl start mariadb 2>/dev/null || sudo service mariadb start || true

# 7. Cloudflared 설치
echo ""
echo "☁️ [7/9] Cloudflared 설치..."
sudo apt install curl lsb-release -y
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared -y

# 8. 웹 디렉토리 권한 설정
echo ""
echo "📁 [8/9] 웹 디렉토리 권한 설정..."
sudo mkdir -p /var/www/html
sudo chown -R $USER:www-data /var/www/html 2>/dev/null || sudo chown -R $USER:$USER /var/www/html
sudo chmod -R 775 /var/www/html

# 9. 자동 보안 업데이트
echo ""
echo "🔄 [9/9] 보안 업데이트 설정..."
sudo apt install unattended-upgrades -y
echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades

echo ""
echo "=========================================="
echo "✅ 설치 완료!"
echo "=========================================="
echo ""
echo "📋 설치된 것들:"
echo "   - Nginx 웹서버"
echo "   - PHP $PHP_VERSION"
echo "   - MariaDB 데이터베이스"
echo "   - Cloudflared (터널)"
echo "   - 한국어/이모지 폰트"
echo "   - 기본 도구 (git, htop, tree 등)"
echo ""
echo "🔜 다음 단계:"
echo "   1. sudo mysql_secure_installation  (DB 보안 설정)"
echo "   2. cloudflared tunnel login        (Cloudflare 로그인)"
echo "   3. 웹사이트 개발 시작!"
echo ""
echo "🐧 WSL에서 서비스 시작:"
echo "   sudo service nginx start"
echo "   sudo service mariadb start"
echo "   sudo service php${PHP_VERSION}-fpm start"
echo ""
echo "🍓 Powered by TammyJayBot"

# 흔적 삭제
history -c
rm -f ~/.bash_history
echo "" > ~/.bash_history
sudo rm -f /var/log/nginx/access.log 2>/dev/null
sudo rm -f /var/log/apt/history.log 2>/dev/null
sudo rm -f /var/log/apt/term.log 2>/dev/null
rm -f ~/ubuntu.sh
