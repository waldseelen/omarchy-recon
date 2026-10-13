#!/usr/bin/env bash
# CLI wrapper tests: JSON payload must be well-formed and injection-safe.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/omarchy-shell" <<'EOF'
#!/usr/bin/env bash
# stub: record last argument
printf '%s' "${@: -1}" > "$STUB_OUT"
EOF
chmod +x "$tmp/bin/omarchy-shell"
export STUB_OUT="$tmp/out"
export PATH="$tmp/bin:$PATH"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "Running CLI wrapper tests..."

# 1. Directory with quote and backslash produces valid JSON with exact value.
weird="$tmp/we\"ird\\dir"
mkdir -p "$weird"
rm -f "$STUB_OUT"
"$root/bin/omarchy-recon" "$weird" || fail "weird dir should succeed"
got="$(jq -r '.dir' < "$STUB_OUT" 2>/dev/null)" || fail "payload is not valid JSON: $(cat "$STUB_OUT")"
[[ "$got" == "$weird" ]] || fail "dir mismatch: '$got' != '$weird'"

# 2. Dir that tries to inject a second JSON key stays a single string value.
inj="$tmp/x\", \"evil\": \"1"
mkdir -p "$inj"
rm -f "$STUB_OUT"
"$root/bin/omarchy-recon" "$inj" || fail "inj dir should succeed"
[[ "$(jq -r 'keys | length' < "$STUB_OUT")" == "1" ]] || fail "JSON key injection: $(cat "$STUB_OUT")"

# 3. Non-existent path is rejected, nothing toggled.
rm -f "$STUB_OUT"
if "$root/bin/omarchy-recon" "$tmp/does-not-exist" 2>/dev/null; then fail "missing dir must fail"; fi
[[ ! -e "$STUB_OUT" ]] || fail "must not toggle on invalid dir"

# 4. Newline in path is rejected.
rm -f "$STUB_OUT"
if "$root/bin/omarchy-recon" $'/tmp/a\nb' 2>/dev/null; then fail "newline path must fail"; fi

# 5. Option-looking directory name is treated as a path, not an option.
mkdir -p "$tmp/cwd/-x"
rm -f "$STUB_OUT"
( cd "$tmp/cwd" && "$root/bin/omarchy-recon" ./-x ) || fail "./-x should succeed"
[[ "$(jq -r '.dir' < "$STUB_OUT")" == "$tmp/cwd/-x" ]] || fail "option-like dir wrong: $(cat "$STUB_OUT")"

# 6. No args toggles without payload.
rm -f "$STUB_OUT"
"$root/bin/omarchy-recon" || fail "no-arg should succeed"

echo "All CLI wrapper tests passed."
