#!/bin/bash

fzf_args=(
  --multi
  --preview 'paru -Si {1}'
  --preview-label='alt-p: toggle description, alt-b/B: toggle PKGBUILD, alt-j/k: scroll, tab: multi-select, F11: maximize'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --bind 'alt-b:change-preview(paru -Gp {1})'
  --bind 'alt-B:change-preview(paru -Si {1})'
  --color 'pointer:green,marker:green'
)

pkg_names=$(curl -fsSL https://aur.archlinux.org/packages.gz | gzip -dc | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "$pkg_names" | tr '\n' ' ' | xargs paru -S --noconfirm
  sudo updatedb
fi