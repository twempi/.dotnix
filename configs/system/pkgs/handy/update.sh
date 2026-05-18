#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "error: run this from inside the dotnix git repository" >&2
  exit 1
fi

pkg_file="$repo_root/configs/system/pkgs/handy/default.nix"
api_url="https://api.github.com/repos/cjpais/Handy/releases/latest"

if [[ ! -f "$pkg_file" ]]; then
  echo "error: package file not found: $pkg_file" >&2
  exit 1
fi

release_json="$(mktemp)"
prefetch_json="$(mktemp)"
cleanup() {
  rm -f "$release_json" "$prefetch_json"
}
trap cleanup EXIT

curl_args=(
  -fsSL
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
)

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

curl "${curl_args[@]}" "$api_url" >"$release_json"

tag_name="$(jq -r '.tag_name // empty' "$release_json")"
version="${tag_name#v}"
if [[ -z "$tag_name" || "$version" == "$tag_name" || -z "$version" ]]; then
  echo "error: latest release tag is missing or does not start with v: $tag_name" >&2
  exit 1
fi

asset_name="Handy_${version}_amd64.AppImage"
asset_url="$(
  jq -r --arg name "$asset_name" \
    '.assets[]? | select(.name == $name) | .browser_download_url' \
    "$release_json" \
    | head -n 1
)"
if [[ -z "$asset_url" ]]; then
  echo "error: release $tag_name does not include asset $asset_name" >&2
  exit 1
fi

nix --extra-experimental-features nix-command \
  store prefetch-file --json --hash-type sha256 "$asset_url" >"$prefetch_json"

hash="$(jq -r '.hash // empty' "$prefetch_json")"
if [[ ! "$hash" =~ ^sha256- ]]; then
  echo "error: prefetch did not return a sha256 SRI hash" >&2
  exit 1
fi

version_count="$(grep -Ec '^[[:space:]]*version = "[^"]+";' "$pkg_file" || true)"
hash_count="$(grep -Ec '^[[:space:]]*hash = "sha256-[^"]+";' "$pkg_file" || true)"
if [[ "$version_count" -ne 1 || "$hash_count" -ne 1 ]]; then
  echo "error: expected exactly one version line and one sha256 hash line in $pkg_file" >&2
  exit 1
fi

export HANDY_VERSION="$version"
export HANDY_HASH="$hash"
perl -0pi -e 's/(version = ")[^"]+(";\n)/$1$ENV{HANDY_VERSION}$2/' "$pkg_file"
perl -0pi -e 's/(hash = ")[^"]+(";\n)/$1$ENV{HANDY_HASH}$2/' "$pkg_file"

echo "Updated Handy to $version"
echo "Asset: $asset_url"
echo "Hash: $hash"
