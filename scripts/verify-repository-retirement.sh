#!/bin/sh

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
EXPECTED_README_BLOB='4b0ce5a48e13d2a4b6fd738cf3cf462a3530e2f5'
DOCS_HOST="$(printf '%s.%s.%s' \
    'docs' \
    'withpointbreak' \
    'com')"
VS_MARKETPLACE="$(printf '%s.%s.%s' \
    'marketplace' \
    'visualstudio' \
    'com')"
OPEN_VSX="$(printf '%s.%s' \
    'open-vsx' \
    'org')"
INSTALL_SHELL="$(printf '%s%s' \
    '/install' \
    '.sh')"
INSTALL_POWERSHELL="$(printf '%s%s' \
    '/install' \
    '.ps1')"
EXTENSION_INSTALL="$(printf '%s%s' \
    '--install' \
    '-extension')"
MINT_PREVIEW="$(printf '%s %s' \
    'mint' \
    'dev')"
MINT_INSTALL="$(printf '%s %s %s' \
    'npm' \
    'install' \
    '-g mint')"
GETTING_STARTED="$(printf '%s%s' \
    'quick' \
    'start')"
SPACED_START="$(printf '%s %s' \
    'quick' \
    'start')"
DEBUG_SOURCE="$(printf '%s%s' \
    'https://github.com/withpointbreak/pointbreak-' \
    'debug')"
INSTALL_FRAGMENT="$(printf '%s%s' \
    '#' \
    'install')"
EMAIL_LINK="$(printf '%s%s' \
    'mail' \
    'to:')"
ISSUES_PATH="/$(printf '%s%s' 'iss' 'ues')"
DISCUSSIONS_PATH="/$(printf '%s%s' 'discuss' 'ions')"
PRIVACY_PATH="/$(printf '%s%s' 'priv' 'acy')"
TERMS_PATH="/$(printf '%s%s' 'ter' 'ms')"
failures=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

actual_files=$(
    cd "$ROOT"
    find . -path './.git' -prune -o -type f -print | LC_ALL=C sort
)
expected_files=$(printf '%s\n' \
    './LICENSE' \
    './README.md' \
    './scripts/verify-repository-retirement.sh')

if [ "$actual_files" != "$expected_files" ]; then
    fail 'default tree must contain only the historical README, license, and retirement verifier'
fi

for removed_path in docs.json favicon.svg images logo reference snippets
do
    if [ -e "$ROOT/$removed_path" ]; then
        fail "$removed_path must be absent from the default tree"
    fi
done

if find "$ROOT" -name '*.mdx' -print -quit | grep -q .; then
    fail 'instructional and legal MDX pages must be absent from the default tree'
fi

if ! rg -qi 'historical source' "$ROOT/README.md" || ! rg -qi 'retired' "$ROOT/README.md"; then
    fail 'README must identify the repository as historical and retired'
fi

if ! rg -Fq '](https://github.com/withpointbreak/pointbreak)' "$ROOT/README.md"; then
    fail 'README must link to the canonical current Pointbreak repository'
fi

if ! rg -Fq 'not current product documentation or a legal or support authority' "$ROOT/README.md"; then
    fail 'README must reject current product, legal, and support authority'
fi

if [ "$(git -C "$ROOT" hash-object README.md)" != "$EXPECTED_README_BLOB" ]; then
    fail 'README must match the reviewed historical tombstone exactly'
fi

actual_headings=$(rg '^#{1,6} ' "$ROOT/README.md" || true)
expected_headings='# Pointbreak Debug Documentation'

if [ "$actual_headings" != "$expected_headings" ]; then
    fail 'README must contain only the historical tombstone heading'
fi

actual_links=$(
    rg -o '\]\([^)]+\)' "$ROOT/README.md" | \
        sed -E 's/^\]\((.*)\)$/\1/' | \
        LC_ALL=C sort
)
expected_links=$(printf '%s\n' \
    'LICENSE' \
    'https://github.com/withpointbreak/pointbreak')

if [ "$actual_links" != "$expected_links" ]; then
    fail 'README links must be limited to the license and canonical current Pointbreak repository'
fi

for forbidden_text in \
    "$DOCS_HOST" \
    "$VS_MARKETPLACE" \
    "$OPEN_VSX" \
    "$INSTALL_SHELL" \
    "$INSTALL_POWERSHELL" \
    "$EXTENSION_INSTALL" \
    "$MINT_PREVIEW" \
    "$MINT_INSTALL" \
    "$GETTING_STARTED" \
    "$SPACED_START" \
    "$DEBUG_SOURCE" \
    "$INSTALL_FRAGMENT" \
    "$EMAIL_LINK" \
    "$ISSUES_PATH" \
    "$DISCUSSIONS_PATH" \
    "$PRIVACY_PATH" \
    "$TERMS_PATH"
do
    if rg -Fiq --hidden --glob '!.git' -- "$forbidden_text" "$ROOT"; then
        fail "default tree must not expose retired publication or authority text: $forbidden_text"
    fi
done

if ! git -C "$ROOT" log --all --format=%H -- docs.json | grep -q . || \
    ! git -C "$ROOT" log --all --format=%H -- privacy.mdx | grep -q .
then
    fail 'removed publication and legal content must remain available in Git history'
fi

if [ "$failures" -ne 0 ]; then
    printf '%s docs repository retirement assertion(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'Pointbreak Debug docs repository retirement assertions passed\n'
