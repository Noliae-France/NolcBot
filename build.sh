#!/bin/sh
set -eu

nolc pkg install

systeme="$(uname -s)"
OPENSSL_PREFIX="${OPENSSL_PREFIX:-}"
SODIUM_PREFIX="${SODIUM_PREFIX:-}"

if [ "$systeme" = "Darwin" ]; then
    if [ -z "$OPENSSL_PREFIX" ] && command -v brew >/dev/null 2>&1; then
        OPENSSL_PREFIX="$(brew --prefix openssl@3 2>/dev/null || true)"
    fi
    if [ -z "$SODIUM_PREFIX" ] && command -v brew >/dev/null 2>&1; then
        SODIUM_PREFIX="$(brew --prefix libsodium 2>/dev/null || true)"
    fi
elif [ "$systeme" = "Linux" ]; then
    # Les distributions placent généralement les bibliothèques dans les
    # chemins standards. pkg-config couvre les installations non standard.
    if command -v pkg-config >/dev/null 2>&1; then
        if [ -z "$OPENSSL_PREFIX" ]; then OPENSSL_PREFIX="$(pkg-config --variable=prefix openssl 2>/dev/null || true)"; fi
        if [ -z "$SODIUM_PREFIX" ]; then SODIUM_PREFIX="$(pkg-config --variable=prefix libsodium 2>/dev/null || true)"; fi
    fi
else
    echo "Système non pris en charge : $systeme (macOS et Linux uniquement)" >&2
    exit 1
fi

set -- nolc build . -o bot --lien sodium --lien ssl --lien crypto --lien sqlite3
if [ -n "$OPENSSL_PREFIX" ] && [ "$OPENSSL_PREFIX" != "/usr" ]; then
    set -- "$@" --chemin-include "$OPENSSL_PREFIX/include" --chemin-lib "$OPENSSL_PREFIX/lib"
fi
if [ -n "$SODIUM_PREFIX" ] && [ "$SODIUM_PREFIX" != "/usr" ]; then
    set -- "$@" --chemin-include "$SODIUM_PREFIX/include" --chemin-lib "$SODIUM_PREFIX/lib"
fi
"$@"
