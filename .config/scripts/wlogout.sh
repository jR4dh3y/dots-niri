#!/usr/bin/env bash
A_1080=400
B_1080=400

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect monitor resolution and scaling factor
get_output_dimensions() {
    local info

    if command -v niri >/dev/null 2>&1; then
        info=$(niri msg -j outputs 2>/dev/null | jq -r '
            first([.[] | select((.focused // false) == true), .[]][]) as $o |
            [
                (
                    ($o.current_mode.size.height // $o.current_mode.height // $o.size.height // $o.height // 0)
                ),
                ($o.scale // 1)
            ] | @tsv
        ' 2>/dev/null)
        if [[ -n "$info" ]]; then
            printf '%s\n' "$info"
            return 0
        fi
    fi

    return 1
}

resolution=""
display_scale=""

if output_info=$(get_output_dimensions); then
    IFS=$'\t' read -r dim scale <<<"$output_info"
    if [[ -n "$dim" && "$dim" != "0" ]]; then
        resolution="$dim"
    fi
    if [[ -n "$scale" && "$scale" != "0" ]]; then
        display_scale="$scale"
    fi
    unset dim scale
fi

if [[ -z "$resolution" || "$resolution" == "0" ]]; then
    resolution=1080
fi

if [[ -z "$display_scale" || "$display_scale" == "0" ]]; then
    display_scale=1
fi

top_margin=$(awk -v base="$A_1080" -v scale="$display_scale" -v res="$resolution" 'BEGIN { if (res > 0) printf "%.0f", base * 1080 * scale / res; else print 0 }')
bottom_margin=$(awk -v base="$B_1080" -v scale="$display_scale" -v res="$resolution" 'BEGIN { if (res > 0) printf "%.0f", base * 1080 * scale / res; else print 0 }')

wlogout -C "$HOME/.config/wlogout/nova.css" -l "$HOME/.config/wlogout/layout" --protocol layer-shell -b 5 -T "$top_margin" -B "$bottom_margin" &
