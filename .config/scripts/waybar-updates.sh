#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

get_official_updates() {
	if command -v checkupdates >/dev/null 2>&1; then
		checkupdates 2>/dev/null || true
	fi
}

get_aur_updates() {
	if command -v paru >/dev/null 2>&1; then
		paru -Qua 2>/dev/null || true
	fi
}

emit_json() {
	python3 - "$1" "$2" "$3" <<'PY'
import json
import sys
print(json.dumps({
	"text": sys.argv[1],
	"alt": sys.argv[2],
	"percentage": int(sys.argv[3]),
}))
PY
}

main() {
	local mode=${1:-print}
	local official aur total
	official=$(get_official_updates | awk 'END { print NR + 0 }')
	aur=$(get_aur_updates | awk 'END { print NR + 0 }')
	total=$((official + aur))

	case $mode in
		has-updates)
			(( total > 0 ))
			;;
		print)
			if (( total == 0 )); then
				emit_json "" "0" "0"
				return 0
			fi
			emit_json "$total" "$aur" "$official"
			;;
		*)
			printf 'Usage: %s [print|has-updates]\n' "$0" >&2
			exit 1
			;;
	esac
}

main "$@"
