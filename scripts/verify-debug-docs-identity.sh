#!/bin/sh

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ORG="withpointbreak"
PRODUCT="pointbreak"
BASE_REPO="$ORG/$PRODUCT"
DEBUG_REPO="${BASE_REPO}-debug"
DOCS_REPO="${DEBUG_REPO}-docs"
failures=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

require_literal() {
    file=$1
    literal=$2
    description=$3

    if ! rg -Fq -- "$literal" "$ROOT/$file"; then
        fail "$description ($file)"
    fi
}

if [ "$(jq -r '.name' "$ROOT/docs.json")" != "Pointbreak Debug" ]; then
    fail 'docs.json must identify the archived Debug documentation'
fi

require_literal README.md '# Pointbreak Debug Documentation' \
    'README must identify the Debug product'
require_literal README.md "$DOCS_REPO" \
    'README must identify the renamed docs repository'
require_literal README.md 'unpublished from Mintlify' \
    'README must record the retired publication state'
require_literal README.md 'reserved for new Pointbreak documentation' \
    'README must reserve the canonical documentation identity'

if git -C "$ROOT" grep -Pn "${BASE_REPO}(?!-debug)" -- . >/dev/null; then
    fail 'tracked docs still route Debug source or support through the unsuffixed repository'
fi

if ! git -C "$ROOT" grep -Fq -- "https://github.com/$DEBUG_REPO" -- docs.json '*.md' '*.mdx'; then
    fail 'tracked docs must route source and support to the Debug repository'
fi

if git -C "$ROOT" grep -Fq -- 'The live documentation is available' -- README.md; then
    fail 'README must not claim the retired Mintlify publication is live'
fi

if [ "$failures" -ne 0 ]; then
    printf '%s Debug docs identity assertion(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'Pointbreak Debug docs identity assertions passed\n'
