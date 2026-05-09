#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
DB_NAME="gnuboard"
DB_USER="luel"
DB_PASS="asdf"

WEB_ROOT="/var/www/gnuboard"
NGINX_CONF="/etc/nginx/sites-available/gnuboard"
NGINX_LINK="/etc/nginx/sites-enabled/gnuboard"

# Official-ish GitHub source archive for latest master/main snapshot
GNUBOARD_ZIP_URL="https://github.com/gnuboard/gnuboard5/archive/refs/heads/master.zip"
TMP_DIR="/tmp/gnuboard-install"
PHP_VER="8.3"

echo "[1/10] Updating apt packages..."
apt update

echo "[2/10] Installing nginx, php, mariadb, unzip, curl..."
DEBIAN_FRONTEND=noninteractive apt install -y \
  nginx \
  mariadb-server \
  unzip \
  wget \
  git \
  software-properties-common \
  php${PHP_VER}-fpm \
  php${PHP_VER}-cli \
  php${PHP_VER}-common \
  php${PHP_VER}-mysql \
  php${PHP_VER}-curl \
  php${PHP_VER}-gd \
  php${PHP_VER}-mbstring \
  php${PHP_VER}-xml \
  php${PHP_VER}-xmlrpc \
  php${PHP_VER}-zip \
  php${PHP_VER}-bcmath \
  php${PHP_VER}-intl \
  php${PHP_VER}-soap \
  php${PHP_VER}-opcache

echo "[3/10] Enabling and starting services..."
systemctl enable nginx
systemctl enable mariadb
systemctl enable php${PHP_VER}-fpm
systemctl restart mariadb
systemctl restart php${PHP_VER}-fpm
systemctl restart nginx

echo "[4/10] Preparing temporary directory..."
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

echo "[5/10] Downloading Gnuboard..."
cd "${TMP_DIR}"
wget -O gnuboard.zip "${GNUBOARD_ZIP_URL}"

echo "[6/10] Extracting Gnuboard..."
unzip -q gnuboard.zip

EXTRACTED_DIR="$(find . -maxdepth 1 -type d -name 'gnuboard5-*' | head -n 1)"
if [[ -z "${EXTRACTED_DIR}" ]]; then
  echo "ERROR: Could not find extracted Gnuboard directory."
  exit 1
fi

echo "[7/10] Deploying files to ${WEB_ROOT}..."
mkdir -p "${WEB_ROOT}"
rm -rf "${WEB_ROOT:?}/"*
cp -a "${EXTRACTED_DIR}/." "${WEB_ROOT}/"

echo "[8/10] Setting ownership and permissions..."
chown -R www-data:www-data "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

# Writable directories commonly needed
mkdir -p "${WEB_ROOT}/data"
chmod -R 775 "${WEB_ROOT}/data"
chown -R www-data:www-data "${WEB_ROOT}/data"

echo "[9/10] Creating MariaDB database and user..."
mysql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[10/10] Configuring nginx..."
cat > "${NGINX_CONF}" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name localhost;
    root ${WEB_ROOT};
    index index.php index.html index.htm;

    client_max_body_size 100M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|svg|webp|woff|woff2|ttf)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\.(ht|git) {
        deny all;
    }
}
EOF

if [[ -L /etc/nginx/sites-enabled/default ]]; then
  rm -f /etc/nginx/sites-enabled/default
fi

ln -sf "${NGINX_CONF}" "${NGINX_LINK}"

nginx -t
systemctl reload nginx

echo
echo "============================================"
echo "Gnuboard installation files deployed."
echo "Open in your browser:"
echo "  http://localhost/"
echo
echo "Database info for web installer:"
echo "  DB Host: localhost"
echo "  DB Name: ${DB_NAME}"
echo "  DB User: ${DB_USER}"
echo "  DB Pass: ${DB_PASS}"
echo "============================================"
