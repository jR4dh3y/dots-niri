#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
WEATHER_DIR="$STATE_HOME/waybar"
LOCATION_FILE="$WEATHER_DIR/weather-location"
DEFAULT_LOCATION="180004"
SIGNAL_NUM=8

ensure_state_dir() {
	mkdir -p "$WEATHER_DIR"
}

load_location() {
	if [[ -f "$LOCATION_FILE" ]]; then
		local location
		location=$(sed -n '1p' "$LOCATION_FILE" | tr -d '\r')
		if [[ -n $location ]]; then
			printf '%s\n' "$location"
			return
		fi
	fi
	printf '%s\n' "$DEFAULT_LOCATION"
}

urlencode_location() {
	python3 - "$1" <<'PY'
import sys
from urllib.parse import quote
print(quote(sys.argv[1], safe=''))
PY
}

emit_json() {
	python3 - "$1" "$2" <<'PY'
import json
import sys
print(json.dumps({"text": sys.argv[1], "tooltip": sys.argv[2]}))
PY
}

normalize_temperature() {
	printf '%s' "$1" | sed 's/^+//'
}

weather_icon() {
	local condition
	condition=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
	case $condition in
		*sun*|*clear*) printf '󰖙' ;;
		*partly*cloud*|*cloudy*) printf '󰖐' ;;
		*overcast*) printf '󰖐' ;;
		*mist*|*fog*) printf '󰖑' ;;
		*rain*|*drizzle*|*shower*) printf '󰖗' ;;
		*snow*|*sleet*|*ice*) printf '󰖘' ;;
		*thunder*) printf '󰙾' ;;
		*wind*) printf '󰖝' ;;
		*) printf '󰖐' ;;
	esac
}

refresh_waybar() {
	pkill -RTMIN+"$SIGNAL_NUM" waybar >/dev/null 2>&1 || true
}

set_location() {
	ensure_state_dir
	local current new_location
	current=$(load_location)

	if command -v fuzzel >/dev/null 2>&1; then
		new_location=$(printf '%s\n' "$current" | fuzzel --dmenu --prompt "Weather location: ") || exit 0
	else
		printf 'Current weather location: %s\n' "$current" >&2
		read -r -p 'New weather location: ' new_location || exit 0
	fi

	new_location=$(printf '%s' "$new_location" | sed 's/^ *//; s/ *$//')
	[[ -n $new_location ]] || exit 0

	printf '%s\n' "$new_location" > "$LOCATION_FILE"
	refresh_waybar
}

open_weather() {
	local location encoded
	location=$(load_location)
	encoded=$(urlencode_location "$location")
	xdg-open "https://wttr.in/$encoded" >/dev/null 2>&1 &
}

print_weather() {
	ensure_state_dir
	local location encoded tooltip current condition temperature icon
	location=$(load_location)
	encoded=$(urlencode_location "$location")

	current=$(curl -sfG --data-urlencode 'format=%C|%t' "https://wttr.in/$encoded" 2>/dev/null || true)
	tooltip=$(curl -sfG \
		--data-urlencode 'format=Location: %l\nCondition: %C\nTemperature: %t\nFeels like: %f\nHumidity: %h\nWind: %w' \
		"https://wttr.in/$encoded" 2>/dev/null || true)

	if [[ -z $current ]]; then
		emit_json "󰖐 N/A" "Unable to fetch weather for $location\nRight-click to set location"
		return
	fi

	condition=${current%%|*}
	temperature=${current#*|}
	temperature=$(normalize_temperature "$temperature")
	icon=$(weather_icon "$condition")

	emit_json "$icon $temperature" "$tooltip"
}

case ${1:-print} in
	print) print_weather ;;
	set-location) set_location ;;
	open) open_weather ;;
	*)
		printf 'Usage: %s [print|set-location|open]\n' "$0" >&2
		exit 1
		;;
esac
