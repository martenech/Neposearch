#!/bin/bash
# Vytvorí lokálny self-signed certifikát „Neposearch Dev“ na podpisovanie appky.
# Stabilný podpis = macOS si pamätá povolenia (Dokumenty, Accessibility…) aj po novom zostavení.
set -euo pipefail
NAME="Neposearch Dev"
if security find-certificate -c "$NAME" >/dev/null 2>&1; then
    echo "Certifikát „${NAME}“ už existuje."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/cert.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF

/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$TMP/cert.cnf" \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2>/dev/null
PASS="neposearch-$RANDOM"
/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -name "$NAME" \
    -out "$TMP/cert.p12" -passout "pass:$PASS" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 2>/dev/null
# -T povolí nástroju codesign používať kľúč bez opakovaných dialógov
security import "$TMP/cert.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P "$PASS" -T /usr/bin/codesign
echo "Vytvorený certifikát „${NAME}“."
