#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.10.5}"
ARCH="amd64"
OS="linux"
BASE_URL="https://releases.hashicorp.com/terraform/${VERSION}"
ZIP="terraform_${VERSION}_${OS}_${ARCH}.zip"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
cd "$workdir"

curl -fsSLO "${BASE_URL}/${ZIP}"
curl -fsSLO "${BASE_URL}/terraform_${VERSION}_SHA256SUMS"
grep " ${ZIP}$" "terraform_${VERSION}_SHA256SUMS" | sha256sum -c -
unzip -oq "$ZIP"
install -m 0755 terraform /usr/local/bin/terraform
terraform version
