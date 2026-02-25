#!/usr/bin/env bash

set -e

BOOTSTRAP_REPO="https://github.com/yourname/brainzmash-bootstrap.git"
BOOTSTRAP_TMP=".brainzmash-bootstrap-tmp"

echo "Ensure we are in musicbrainz-docker root"
if [ ! -f "docker-compose.yml" ]; then
    echo "Run this script from the musicbrainz-docker root directory."
    exit 1
fi

if [ ! -f "admin/configure" ]; then
    echo "admin/configure not found. Wrong directory?"
    exit 1
fi

echo "Prevent overwriting an existing local override setup"
if [ -d "local/compose" ] && [ "$(ls -A local/compose 2>/dev/null)" ]; then
    echo "local/compose already exists and contains files."
    echo "Aborting to avoid overwriting an existing configuration."
    exit 1
fi

echo "Create volume directories"
mkdir -p volumes/{mqdata,pgdata,solrdata,dbdump,solrdump,lmdconfig}

echo "Clone bootstrap repo into temporary folder"
rm -rf "$BOOTSTRAP_TMP"
git clone "$BOOTSTRAP_REPO" "$BOOTSTRAP_TMP"

echo "Copy local overrides into place"
mkdir -p local/compose
cp -r "$BOOTSTRAP_TMP/local/compose/"* local/compose/

echo "Generate secure backend key"
KEY=$(openssl rand -hex 32)
echo "Generated backend key"

NGINX_FILE="local/compose/brainzmash/nginx.conf"

if [ ! -f "$NGINX_FILE" ]; then
    echo "nginx.conf not found at $NGINX_FILE"
    exit 1
fi

echo "Inject key into nginx config"

if grep -q "__BRAINZMASH_KEY__" "$NGINX_FILE"; then
    sed -i "s/__BRAINZMASH_KEY__/$KEY/" "$NGINX_FILE"
else
    echo "API key placeholder not found in nginx.conf. Aborting."
    exit 1
fi

echo "Register compose overrides"
admin/configure add local/compose/*.yml

echo "Clean up temp clone"
rm -rf "$BOOTSTRAP_TMP"

echo
echo "BrainzMash backend API key:"
echo
echo "$KEY"
echo
echo "Send this key to the BrainzMash operator via private message."
echo "Do not share it publicly."
echo
echo
echo "Continue to next step"
echo
