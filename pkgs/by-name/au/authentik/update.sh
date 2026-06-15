#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils curl jq nix nix-prefetch-github ripgrep
# shellcheck shell=bash

set -euo pipefail
[[ -z "${XTRACE:-}" ]] || set -x

# using UPDATE_NIX_ATTR_PATH to detect if this is being called from update.nix
[[ -n "${UPDATE_NIX_ATTR_PATH:-}" ]] && inUpdateNix=1 || inUpdateNix=0

show_help() {
  cat <<"EOF"
Usage: update.sh [-?h] [-a authentikVersion] [-- <nix-build args>...]

Create and update the `source.json` file for the `authentik` package.

The script tries to only update missing dependency hashes if possible.
If the `authentikVersion` changes, all hashes are considered missing.

To assist with building dependencies for different architectures (aarch64-linux and x86_64-linux at the moment),
all remaining arguments after the first `--` will be passed to the `nix-build` commands.

For example: --builders "buildhost aarch64-linux - 2"

  -?|-h                Display this help and exit
  -a authentikVersion  Specify the authentik source version (default: fetch latest tag)
EOF
}

authentikVersion=
while getopts "?ha:" opt; do
  case "$opt" in
  a) authentikVersion=$OPTARG;;
  h|?) show_help; exit 0;;
  *) show_help; exit 1;;
  esac
done

shift $((OPTIND-1))
if [[ $# -gt 0 && "$1" = "--" ]]; then
  shift
fi

root="$(dirname "${BASH_SOURCE[0]}")"
json="$root/source.json"
fake="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

if [[ -n "$authentikVersion" ]]; then
  authentikTag="version/$authentikVersion"
else
  # fetch all recent releases, filter out rc's and other possibly unstable tags and use the highest version
  authentikTag="$(curl -fsS https://api.github.com/repos/goauthentik/authentik/releases \
    | jq -r '.[] | .tag_name' \
    | rg '[0-9]{4}\.[0-9]{1,2}\.[0-9]+$' \
    | sort -V | tail -n1)"
  authentikVersion="${authentikTag#version/}"
fi

# if the version has not changed, try to restore the previous hashes, otherwise start fresh
prevAuthentikVersion=
if [[ -f "$json" ]]; then
  prevAuthentikVersion="$(jq -r .authentik.version "$json" || true)"
fi

if [[ "$prevAuthentikVersion" == "$authentikVersion" ]]; then
  authentikHash="$(jq -r .authentik.hash "$json" || true)"
  coreCargoHash="$(jq -r .coreCargoHash "$json" || true)"
  serverVendorHash="$(jq -r .serverVendorHash "$json" || true)"
  website_aarch64="$(jq -r '.websiteHashes["aarch64-linux"]' "$json" || true)"
  website_x86_64="$(jq -r '.websiteHashes["x86_64-linux"]' "$json" || true)"
  webui_aarch64="$(jq -r '.webuiHashes["aarch64-linux"]' "$json" || true)"
  webui_x86_64="$(jq -r '.webuiHashes["x86_64-linux"]' "$json" || true)"
else
  authentikHash=
  coreCargoHash=
  serverVendorHash=
  website_aarch64=
  website_x86_64=
  webui_aarch64=
  webui_x86_64=
fi

# use the fake hash for everything, that does not look like an SRI hash
[[ "$authentikHash" == sha256-* ]] || authentikHash="$fake"
[[ "$coreCargoHash" == sha256-* ]] || coreCargoHash="$fake"
[[ "$serverVendorHash" == sha256-* ]] || serverVendorHash="$fake"
[[ "$website_aarch64" == sha256-* ]] || website_aarch64="$fake"
[[ "$website_x86_64" == sha256-* ]] || website_x86_64="$fake"
[[ "$webui_aarch64" == sha256-* ]] || webui_aarch64="$fake"
[[ "$webui_x86_64" == sha256-* ]] || webui_x86_64="$fake"

# first, update the source hashes (must succeed)
[[ "$authentikHash" != "$fake" ]] || authentikHash="$(nix-prefetch-github goauthentik authentik --rev "$authentikTag" -v | jq -r .hash)"

function writeJson() {
  jq -n \
    --arg authentikVersion "$authentikVersion" --arg authentikHash "$authentikHash" \
    --arg coreCargoHash "$coreCargoHash" --arg serverVendorHash "$serverVendorHash" \
    --arg website_aarch64 "$website_aarch64" --arg website_x86_64 "$website_x86_64" \
    --arg webui_aarch64 "$webui_aarch64" --arg webui_x86_64 "$webui_x86_64" \
    '{
      "authentik": {"version": $authentikVersion, "hash": $authentikHash},
      $coreCargoHash, $serverVendorHash,
      "websiteHashes": {"aarch64-linux": $website_aarch64, "x86_64-linux": $website_x86_64},
      "webuiHashes": {"aarch64-linux": $webui_aarch64, "x86_64-linux": $webui_x86_64}
    }' >"$json"
}

writeJson

# second, build the dependencies (may succeed)
function getHash() {
  local prefix=$1
  shift
  nix-build --keep-going --no-link -A "$@" 2>&1 \
    | rg --line-buffered -ar "$prefix: "'$1' '^(.*)$' \
    | tee /dev/stderr | rg -aor '$1' '\bgot:\s+(\S+)'
}

# run all the required build processes in parallel
# copy the resulting stdout descriptors for reading later
[[ "$coreCargoHash" != "$fake" ]] || {
  coproc coreCargoHashC { getHash core.cargoDeps authentik.components.core.cargoDeps "$@"; }
  exec {coreCargoHashFd}<&"${coreCargoHashC[0]}"
}
[[ "$serverVendorHash" != "$fake" ]] || {
  coproc serverVendorHashC { getHash server.goModules authentik.components.server.goModules "$@"; }
  exec {serverVendorHashFd}<&"${serverVendorHashC[0]}"
}
[[ "$website_aarch64" != "$fake" ]] || {
  coproc website_aarch64C { getHash 'website-deps(aarch64-linux)' authentik.components.website-deps --argstr system aarch64-linux "$@"; }
  exec {website_aarch64Fd}<&"${website_aarch64C[0]}"
}
[[ "$website_x86_64" != "$fake" ]] || {
  coproc website_x86_64C { getHash 'website-deps(x86_64-linux)' authentik.components.website-deps --argstr system x86_64-linux "$@"; }
  exec {website_x86_64Fd}<&"${website_x86_64C[0]}"
}
[[ "$webui_aarch64" != "$fake" ]] || {
  coproc webui_aarch64C { getHash 'webui-deps(aarch64-linux)' authentik.components.webui-deps --argstr system aarch64-linux "$@"; }
  exec {webui_aarch64Fd}<&"${webui_aarch64C[0]}"
}
[[ "$webui_x86_64" != "$fake" ]] || {
  coproc webui_x86_64C { getHash 'webui-deps(x86_64-linux)' authentik.components.webui-deps --argstr system x86_64-linux "$@"; }
  exec {webui_x86_64Fd}<&"${webui_x86_64C[0]}"
}
wait || true

[[ -z "${coreCargoHashFd:-}" ]] || read -r -u "$coreCargoHashFd" coreCargoHash || true
[[ -z "${serverVendorHashFd:-}" ]] || read -r -u "$serverVendorHashFd" serverVendorHash || true
[[ -z "${website_aarch64Fd:-}" ]] || read -r -u "$website_aarch64Fd" website_aarch64 || true
[[ -z "${website_x86_64Fd:-}" ]] || read -r -u "$website_x86_64Fd" website_x86_64 || true
[[ -z "${webui_aarch64Fd:-}" ]] || read -r -u "$webui_aarch64Fd" webui_aarch64 || true
[[ -z "${webui_x86_64Fd:-}" ]] || read -r -u "$webui_x86_64Fd" webui_x86_64 || true

# even if a command failed, ensure the output is an SRI hash
[[ "$authentikHash" == sha256-* ]] || authentikHash="$fake"
[[ "$coreCargoHash" == sha256-* ]] || coreCargoHash="$fake"
[[ "$serverVendorHash" == sha256-* ]] || serverVendorHash="$fake"
[[ "$website_aarch64" == sha256-* ]] || website_aarch64="$fake"
[[ "$website_x86_64" == sha256-* ]] || website_x86_64="$fake"
[[ "$webui_aarch64" == sha256-* ]] || webui_aarch64="$fake"
[[ "$webui_x86_64" == sha256-* ]] || webui_x86_64="$fake"

writeJson

# if any hash is unknown, ensure update.nix doesn't commit the changes
if [[ "$authentikHash" == "$fake" ||
      "$coreCargoHash" == "$fake" || "$serverVendorHash" == "$fake" ||
      "$website_aarch64" == "$fake" || "$website_x86_64" == "$fake" ||
      "$webui_aarch64" == "$fake" || "$webui_x86_64" == "$fake" ]]; then

  # dump the json content if we might run in a git worktree
  if (( inUpdateNix )); then
    echo -e "\n$json content:" >&2
    cat "$json" >&2
  fi

  echo -e "\nCould not determine all hashes. Automatic update failed." >&2
  exit 1
fi

if (( inUpdateNix )); then
  jq -n \
    --arg attrPath "authentik,authentik-outposts" \
    --arg newVersion "$authentikVersion" \
    '[{ $attrPath, $newVersion }]'
fi
