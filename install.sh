#!/usr/bin/env bash
#
# Install ck-dev-tools scripts to ~/.local/bin/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"

mkdir -p "${INSTALL_DIR}"

for script in "${SCRIPT_DIR}"/bin/ck-*; do
    name="$(basename "${script}")"
    cp "${script}" "${INSTALL_DIR}/${name}"
    chmod +x "${INSTALL_DIR}/${name}"
    echo "Installed ${name} -> ${INSTALL_DIR}/${name}"
done

echo ""
echo "Make sure ${INSTALL_DIR} is on your PATH:"
echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
