# rofi -dmenu stand-in: rows on stdin, the choice on stdout, rofi's exit codes
# (0 picked, 1 cancelled, 10 + N - 1 for -kb-custom-N). Rows may carry rofi's
# "\0icon\x1f<path>" option, or "\0colors\x1f<palette file>" for -theme themes.
# -theme takes power, wallpaper, emoji or themes.
prompt=""
mesg=""
theme=""
font=""
keys=""

while [ $# -gt 0 ]; do
  case "$1" in
    -p) prompt="$2"; shift 2 ;;
    -mesg) mesg="$2"; shift 2 ;;
    -theme) theme="$2"; shift 2 ;;
    -kb-custom-*) keys="$keys${1#-kb-custom-} $2"$'\n'; shift 2 ;;
    -dmenu | -i | -show-icons) shift ;;
    *) echo "amane-dmenu: unknown option $1" >&2; exit 2 ;;
  esac
done

if [ "$theme" = emoji ]; then
  font="Noto Emoji"
fi

dir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/amane-dmenu.XXXXXX")"
trap 'rm -rf "$dir"' EXIT

cat > "$dir/items"
printf '%s' "$prompt" > "$dir/prompt"
printf '%s' "$mesg" > "$dir/mesg"
printf '%s' "$theme" > "$dir/theme"
printf '%s' "$font" > "$dir/font"
printf '%s' "$keys" > "$dir/keys"
mkfifo "$dir/result"

# held open for reading before the shell is asked, so its answer can't be lost
exec 3<>"$dir/result"

amane ipc call menu "$dir" > /dev/null || exit 1

IFS= read -r code <&3
IFS= read -r choice <&3

if [ "$code" -ne 1 ]; then
  printf '%s\n' "$choice"
fi

exit "$code"
