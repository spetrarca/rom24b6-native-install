#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cp "$ROOT/install-rom24b6.sh" "$TMPDIR/install-rom24b6.sh"
mkdir -p "$TMPDIR/bin"

printf '#!/usr/bin/env bash\nexit 0\n' > "$TMPDIR/bin/gcc"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMPDIR/bin/make"
chmod +x "$TMPDIR/bin/gcc" "$TMPDIR/bin/make"

PATH="$TMPDIR/bin:$PATH" "$TMPDIR/install-rom24b6.sh" >/dev/null

for dir in log player gods; do
  if [[ ! -d "$TMPDIR/$dir" ]]; then
    echo "missing runtime directory: $dir" >&2
    exit 1
  fi
done
