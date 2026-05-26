#!/usr/bin/env bash
set -euo pipefail

STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
WEATHER_DIR="$STATE_HOME/waybar"
LOCATION_FILE="$WEATHER_DIR/weather-location"
CACHE_FILE="$WEATHER_DIR/center-weather-cache-v5"
DEFAULT_LOCATION="London"
CACHE_TTL=1800

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

cache_is_fresh() {
	[[ -s "$CACHE_FILE" ]] || return 1
	local now modified
	now=$(date +%s)
	modified=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || printf 0)
	(( now - modified < CACHE_TTL ))
}

weather_summary() {
	ensure_state_dir

	if cache_is_fresh; then
		cat "$CACHE_FILE"
		return
	fi

	local location current condition temperature icon
	location=$(load_location)
	current=$(curl -sfG --data-urlencode 'format=%C|%t|%f|%h|%w|%l' "https://wttr.in/$location" 2>/dev/null || true)

	if [[ -z $current ]]; then
		printf 'unavailable||||||󰖐' | tee "$CACHE_FILE"
		return
	fi

	IFS='|' read -r condition temperature feels humidity wind resolved_location <<< "$current"
	temperature=$(normalize_temperature "$temperature")
	feels=$(normalize_temperature "$feels")
	icon=$(weather_icon "$condition")

	printf '%s|%s|%s|%s|%s|%s|%s' \
		"$condition" "$temperature" "$feels" "$humidity" "$wind" "$resolved_location" "$icon" | tee "$CACHE_FILE"
}

print_info() {
	local text weather tooltip
	text=$(date '+%-d %b, %H:%M')
	weather=$(weather_summary)
	tooltip=$(python3 - "$weather" <<'PY'
import calendar
import html
import sys
from datetime import datetime

weather = sys.argv[1].split("|", 6)
now = datetime.now()
cal = calendar.Calendar(firstweekday=0)
calendar_width = 20
weather_width = 20
gap = "     "

def escape(value):
    return html.escape(value.strip())

def center(value, width):
    return value.center(width)

def bold_center(value, width):
    return f"<b>{html.escape(value.center(width))}</b>"

def field(label, value):
    label_width = 8
    value_width = weather_width - label_width - 1
    return f"{html.escape(label):<{label_width}} {html.escape(value):>{value_width}}"

calendar_lines = [
    bold_center(now.strftime("%B %Y"), calendar_width),
    "Mo Tu We Th Fr Sa Su",
]

for week in cal.monthdayscalendar(now.year, now.month):
    cells = []
    for day in week:
        if day == 0:
            cells.append("  ")
        elif day == now.day:
            cells.append(
                f"<span foreground='#1d1a20' background='#c3fb5b'><b>{day:2d}</b></span>"
            )
        else:
            cells.append(f"{day:2d}")
    calendar_lines.append(" ".join(cells))

condition, temperature, feels, humidity, wind, place, icon = (weather + [""] * 7)[:7]
summary = f"{escape(icon)} {escape(temperature)} {escape(condition).title()}".strip()
weather_lines = [
    bold_center("Weather", weather_width),
    center(summary, weather_width),
    " " * weather_width,
    field("Feels", escape(feels)),
    field("Humidity", escape(humidity)),
    field("Wind", escape(wind)),
    field("Place", escape(place)),
]

height = max(len(calendar_lines), len(weather_lines))
rows = []
for index in range(height):
    left = calendar_lines[index] if index < len(calendar_lines) else " " * calendar_width
    right = weather_lines[index] if index < len(weather_lines) else " " * weather_width
    rows.append(f"{left}{gap}{right}")

print("<tt>" + "\n".join(rows) + "</tt>")
PY
)

	python3 - "$text" "$tooltip" <<'PY'
import json
import sys

print(json.dumps({"text": sys.argv[1], "tooltip": sys.argv[2]}))
PY
}

case ${1:-print} in
	print) print_info ;;
	open-weather) "$HOME/.config/scripts/waybar-weather.sh" open ;;
	set-location)
		rm -f "$CACHE_FILE"
		"$HOME/.config/scripts/waybar-weather.sh" set-location
		;;
	*)
		printf 'Usage: %s [print|open-weather|set-location]\n' "$0" >&2
		exit 1
		;;
esac
