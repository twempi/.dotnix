# token_file and cache_name are set by default.nix.
if [ ! -s "$token_file" ]; then
  echo "Missing Cachix token secret at $token_file" >&2
  echo "Create secrets/cachix.yaml with cachix_twempi_token encrypted by sops-nix." >&2
  exit 1
fi

export CACHIX_AUTH_TOKEN
CACHIX_AUTH_TOKEN="$(tr -d '\n' < "$token_file")"

exec cachix daemon run \
  --no-remote-stop \
  --socket /run/cachix-daemon/socket \
  --omit-deriver \
  "$cache_name"
