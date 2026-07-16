#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v4.2.2}"
ARCH="amd64"
OS="linux"
TARBALL="helm-${VERSION}-${OS}-${ARCH}.tar.gz"
BASE_URL="https://get.helm.sh"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

curl -fsSLO "${BASE_URL}/${TARBALL}"
curl -fsSLO "${BASE_URL}/${TARBALL}.sha256sum"
sha256sum -c "${TARBALL}.sha256sum"
tar -xzf "$TARBALL"
install -m 0755 "${OS}-${ARCH}/helm" /usr/local/bin/helm
helm version
