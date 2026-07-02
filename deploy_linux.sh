#!/usr/bin/env bash

# ==============================================================================
# Miryam Zelig Static Site Deployment Script (Server-Side)
# ==============================================================================

set -euo pipefail

APP_NAME="Miryam_Zelig"
ROUTE_BASE="/Miryam_Zelig"
LOWER_ROUTE_BASE="/miryam_zelig"
WEB_ROOT="/var/www/${APP_NAME}"
NGINX_SITE="/etc/nginx/sites-available/vee-app.co.il.conf"
NGINX_SNIPPET="/etc/nginx/snippets/${APP_NAME}-locations.conf"

echo "[INFO] Starting ${APP_NAME} deployment..."

if [ ! -f "index.html" ]; then
  echo "[ERROR] index.html was not found in $(pwd)" >&2
  exit 1
fi

echo "[INFO] Pulling latest code..."
git fetch origin main
git reset --hard origin/main

echo "[INFO] Copying static site to ${WEB_ROOT}..."
mkdir -p "${WEB_ROOT}"
rm -rf "${WEB_ROOT:?}/"*
cp index.html "${WEB_ROOT}/index.html"
cp -R gallery "${WEB_ROOT}/gallery"
cp miryam.jpeg "${WEB_ROOT}/miryam.jpeg"

echo "[INFO] Setting permissions..."
chown -R www-data:www-data "${WEB_ROOT}"
chmod -R 755 "${WEB_ROOT}"

echo "[INFO] Writing Nginx route snippet..."
cat > "${NGINX_SNIPPET}" <<EOF
location = ${ROUTE_BASE} {
    return 301 ${ROUTE_BASE}/;
}

location = ${LOWER_ROUTE_BASE} {
    return 301 ${ROUTE_BASE}/;
}

location ^~ ${LOWER_ROUTE_BASE}/ {
    return 301 ${ROUTE_BASE}/;
}

location ^~ ${ROUTE_BASE}/ {
    root /var/www;
    index index.html;
    try_files \$uri \$uri/ ${ROUTE_BASE}/index.html;

    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF

if ! grep -q "include ${NGINX_SNIPPET};" "${NGINX_SITE}"; then
  echo "[INFO] Registering route snippet in ${NGINX_SITE}..."
  cp "${NGINX_SITE}" "${NGINX_SITE}.bak.$(date +%Y%m%d%H%M%S)"
  sed -i "/server_name vee-app.co.il www.vee-app.co.il;/a\\    include ${NGINX_SNIPPET};" "${NGINX_SITE}"
fi

echo "[INFO] Testing Nginx configuration..."
nginx -t

echo "[INFO] Reloading Nginx..."
systemctl reload nginx

echo "[SUCCESS] ${APP_NAME} deployment complete: https://vee-app.co.il${ROUTE_BASE}/"
