#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.6.7}"
ARCH="amd64"
OS="linux"
TARBALL="kubeconform-${OS}-${ARCH}.tar.gz"
URL="https://github.com/yannh/kubeconform/releases/download/${VERSION}/${TARBALL}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

curl -fsSL "$URL" -o "$TARBALL"
tar -xzf "$TARBALL"
install -m 0755 kubeconform /usr/local/bin/kubeconform
kubeconform -v
