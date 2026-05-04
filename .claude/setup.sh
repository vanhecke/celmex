#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq jq curl gzip > /dev/null

echo "==> Installing Elm 0.19.1..."
if ! command -v elm &> /dev/null; then
    curl -fsSL https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
        | gunzip > /usr/local/bin/elm
    chmod +x /usr/local/bin/elm
fi
elm --version

echo "==> Installing elm-format..."
if ! command -v elm-format &> /dev/null; then
    npm install -g elm-format@0.8.7
fi
elm-format --help | head -1

echo "==> Installing just..."
if ! command -v just &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
        | bash -s -- --to /usr/local/bin
fi
just --version

echo "==> Installing bats..."
if ! command -v bats &> /dev/null; then
    npm install -g bats
fi
bats --version

echo "==> Installing npm dependencies..."
npm ci

echo "==> Pre-building CLI..."
just build

echo "==> Setup complete."
