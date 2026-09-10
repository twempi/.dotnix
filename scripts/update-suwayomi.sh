#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repository_root

config_file="${repository_root}/configs/hosts/t480s/system/modules/suwayomi.nix"
readonly config_file

release_api_url="https://api.github.com/repos/Suwayomi/Suwayomi-Server/releases/latest"
readonly release_api_url

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

get_configured_version() {
  local versions

  versions="$(
    perl -ne '
      if (/^\s*suwayomiVersion\s*=\s*"([^"]+)"\s*;/) {
        print "$1\n";
        ++$count;
      }
      END { exit($count == 1 ? 0 : 1); }
    ' "$config_file"
  )" || die "expected exactly one suwayomiVersion assignment in $config_file"

  printf '%s\n' "$versions"
}

for command in curl jq nix perl sort mktemp cmp chmod mv; do
  require_command "$command"
done

[[ -f "$config_file" ]] || die "configuration file not found: $config_file"

temporary_directory="$(mktemp -d)"
temporary_config=""

cleanup() {
  rm -rf -- "$temporary_directory"

  if [[ -n "$temporary_config" && -e "$temporary_config" ]]; then
    rm -f -- "$temporary_config"
  fi
}

trap cleanup EXIT

release_metadata="${temporary_directory}/release.json"
request_headers=()
github_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [[ -n "$github_token" ]]; then
  request_headers=(-H "Authorization: Bearer ${github_token}")
fi

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 3 \
  --retry-all-errors \
  --connect-timeout 20 \
  "${request_headers[@]}" \
  --output "$release_metadata" \
  "$release_api_url"

jq -e '.draft == false and .prerelease == false' "$release_metadata" >/dev/null \
  || die "latest Suwayomi release is draft or prerelease"

tag_name="$(jq -er '.tag_name' "$release_metadata")" \
  || die "latest Suwayomi release does not have a tag"

[[ "$tag_name" =~ ^v[0-9]+(\.[0-9]+)+$ ]] \
  || die "latest Suwayomi tag has an unsupported format: $tag_name"

latest_version="${tag_name#v}"
asset_name="Suwayomi-Server-v${latest_version}.jar"
asset_url="$(
  jq -er --arg asset_name "$asset_name" '
    [
      .assets[]
      | select(.name == $asset_name and .state == "uploaded")
      | .browser_download_url
    ]
    | if length == 1 then .[0] else error("expected one uploaded server JAR") end
  ' "$release_metadata"
)" || die "latest Suwayomi release does not provide $asset_name"

configured_version="$(get_configured_version)"

if [[ "$configured_version" == "$latest_version" ]]; then
  printf 'Suwayomi is already at v%s.\n' "$configured_version"
  exit 0
fi

newest_version="$(printf '%s\n%s\n' "$configured_version" "$latest_version" | sort -V | tail -n 1)"
[[ "$newest_version" == "$latest_version" ]] \
  || die "latest release v${latest_version} is not newer than configured v${configured_version}"

asset_file="${temporary_directory}/${asset_name}"

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 3 \
  --retry-all-errors \
  --connect-timeout 20 \
  "${request_headers[@]}" \
  --output "$asset_file" \
  "$asset_url"

asset_hash="$(nix hash file --sri --type sha256 "$asset_file")"
[[ "$asset_hash" =~ ^sha256-[A-Za-z0-9+/=]+$ ]] \
  || die "failed to calculate an SRI SHA-256 hash for $asset_name"

temporary_config="$(mktemp "${config_file}.tmp.XXXXXX")"

SUWAYOMI_VERSION="$latest_version" SUWAYOMI_HASH="$asset_hash" perl -0pe '
  my $version = $ENV{SUWAYOMI_VERSION};
  my $hash = $ENV{SUWAYOMI_HASH};

  my $replacements = s{
    (suwayomiVersion\s*=\s*")[^"]+(";\n\n\s*suwayomiLatest\s*=\s*pkgs\.suwayomi-server\.overrideAttrs\s*\(old:\s*\{.*?\n\s*src\s*=\s*pkgs\.fetchurl\s*\{.*?\n\s*hash\s*=\s*")[^"]+(";)
  }{$replacements++; "${1}${version}${2}${hash}${3}"}sex;

  die "expected exactly one Suwayomi version/hash block\n" unless $replacements == 1;
' "$config_file" >"$temporary_config"

cmp --silent "$config_file" "$temporary_config" \
  && die "Suwayomi update did not change the configuration"

chmod --reference="$config_file" "$temporary_config"
mv -- "$temporary_config" "$config_file"
temporary_config=""

printf 'Updated Suwayomi from v%s to v%s.\n' "$configured_version" "$latest_version"
