#!/bin/bash

fzf_args=(
  --multi
  --preview 'pacman -Qi {1} 2>/dev/null || echo "Package not installed"'
  --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select, F11: maximize'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:red,marker:red'
)

# List all explicitly installed packages
pkg_names=$(pacman -Qe | awk '{print $1}' | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "Selected packages for removal:"
  echo "$pkg_names"
  echo ""
  
  # Show confirmation
  read -p "Do you want to uninstall these packages? (y/N) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Convert newline-separated selections to space-separated for pacman
    echo "$pkg_names" | tr '\n' ' ' | xargs sudo pacman -Rns --noconfirm
    
    if [[ $? -eq 0 ]]; then
      echo ""
      echo "✓ Packages uninstalled successfully"
    else
      echo ""
      echo "✗ Failed to uninstall some packages"
    fi
  else
    echo "Uninstall cancelled"
  fi
else
  echo "No packages selected"
fi
