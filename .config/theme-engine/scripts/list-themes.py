#!/usr/bin/env python3
"""
List Themes Script - Display available themes with metadata and statistics

This script provides an enhanced way to discover and inspect available themes.
It shows theme metadata, color preview (if terminal supports colors),
and statistics about each theme.

Usage:
    list-themes.py
    list-themes.py --detailed
    list-themes.py --colors
    list-themes.py --stats
    list-themes.py --compare <theme1> <theme2>
    list-themes.py --help

Dependencies:
    - PyYAML (theme loading)
    - colorama (colored output)
"""

import os
import sys
import argparse
import yaml
import logging
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple

try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
    HAS_COLORAMA = True
except ImportError:
    HAS_COLORAMA = False


# Configuration
_script_dir = Path(__file__).parent
_theme_engine_repo = _script_dir.parent
_theme_engine_home = Path.home() / ".config" / "theme-engine"

if _theme_engine_repo.exists() and (_theme_engine_repo / "themes").exists():
    THEME_ENGINE_DIR = _theme_engine_repo
else:
    THEME_ENGINE_DIR = _theme_engine_home

THEMES_DIR = THEME_ENGINE_DIR / "themes"


def colorize(text: str, color: str) -> str:
    """Colorize text if colorama is available"""
    if not HAS_COLORAMA:
        return text
    
    color_map = {
        "green": Fore.GREEN,
        "red": Fore.RED,
        "yellow": Fore.YELLOW,
        "blue": Fore.BLUE,
        "cyan": Fore.CYAN,
        "magenta": Fore.MAGENTA,
        "white": Fore.WHITE,
        "black": Fore.BLACK,
        "dark_gray": Fore.BLACK,
    }
    
    return f"{color_map.get(color, '')}{text}{Style.RESET_ALL}"


def print_colored(text: str, color: str = "white"):
    """Print colored text"""
    print(colorize(text, color))


def load_theme(theme_name: str) -> Optional[Dict[str, Any]]:
    """Load theme from YAML file"""
    theme_path = THEMES_DIR / f"{theme_name}.yaml"
    
    if not theme_path.exists():
        return None
    
    try:
        with open(theme_path, 'r') as f:
            return yaml.safe_load(f)
    except Exception:
        return None


def get_available_themes() -> List[str]:
    """Get list of available theme names"""
    if not THEMES_DIR.exists():
        return []
    
    themes = [f.stem for f in THEMES_DIR.glob("*.yaml")]
    return sorted(themes)


def count_colors(theme_data: Dict[str, Any]) -> int:
    """Count total number of colors in theme"""
    count = 0
    colors = theme_data.get('colors', {})
    
    def count_dict(d):
        total = 0
        for v in d.values():
            if isinstance(v, dict):
                total += count_dict(v)
            elif isinstance(v, str) and v.startswith('#'):
                total += 1
        return total
    
    return count_dict(colors)


def get_color_sample(theme_data: Dict[str, Any], limit: int = 5) -> List[Tuple[str, str]]:
    """Get sample colors from theme"""
    colors = theme_data.get('colors', {})
    samples = []
    
    # Try to get primary colors first
    if 'background' in colors and isinstance(colors['background'], dict):
        if 'primary' in colors['background']:
            samples.append(('bg_primary', colors['background']['primary']))
    
    if 'foreground' in colors and isinstance(colors['foreground'], dict):
        if 'primary' in colors['foreground']:
            samples.append(('fg_primary', colors['foreground']['primary']))
    
    if 'accent' in colors and isinstance(colors['accent'], dict):
        if 'primary' in colors['accent']:
            samples.append(('accent', colors['accent']['primary']))
    
    # Fill remaining from any colors found
    def get_flat_colors(d, prefix=''):
        result = []
        for k, v in d.items():
            if isinstance(v, dict):
                result.extend(get_flat_colors(v, f"{prefix}{k}_"))
            elif isinstance(v, str) and v.startswith('#'):
                result.append((f"{prefix}{k}", v))
        return result
    
    all_colors = get_flat_colors(colors)
    
    # Add more samples if needed
    for name, hex_color in all_colors:
        if len(samples) >= limit:
            break
        if (name, hex_color) not in samples:
            samples.append((name, hex_color))
    
    return samples[:limit]


def print_color_block(hex_color: str, size: int = 2) -> str:
    """Return colored block string"""
    if not HAS_COLORAMA:
        return hex_color
    
    # Remove # if present
    hex_color = hex_color.lstrip('#')
    
    # Convert hex to RGB
    try:
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)
        
        # Create a colored block
        block = "█" * size
        return f"\033[38;2;{r};{g};{b}m{block}\033[0m"
    except (ValueError, IndexError):
        return hex_color


def list_themes_basic():
    """List themes in basic format"""
    themes = get_available_themes()
    
    if not themes:
        print_colored("No themes found", "red")
        return False
    
    print_colored(f"\nAvailable themes ({len(themes)}):\n", "cyan")
    
    for theme_name in themes:
        theme_data = load_theme(theme_name)
        if not theme_data:
            continue
        
        meta = theme_data.get('meta', {})
        description = meta.get('description', 'No description')
        author = meta.get('author', 'Unknown')
        
        print_colored(f"  • {theme_name}", "green")
        print(f"    {description}")
        print(f"    by {author}\n")
    
    return True


def list_themes_detailed():
    """List themes in detailed format"""
    themes = get_available_themes()
    
    if not themes:
        print_colored("No themes found", "red")
        return False
    
    print_colored(f"\nDetailed Theme List ({len(themes)}):\n", "cyan")
    print_colored("=" * 80, "cyan")
    
    for i, theme_name in enumerate(themes, 1):
        theme_data = load_theme(theme_name)
        if not theme_data:
            continue
        
        meta = theme_data.get('meta', {})
        
        # Header
        print_colored(f"\n{i}. {theme_name}", "green")
        print_colored("-" * 70, "cyan")
        
        # Metadata
        print(f"  Description: {meta.get('description', 'N/A')}")
        print(f"  Author:      {meta.get('author', 'N/A')}")
        print(f"  Version:     {meta.get('version', 'N/A')}")
        
        # Statistics
        color_count = count_colors(theme_data)
        colors_section = theme_data.get('colors', {})
        apps = colors_section.get('app_overrides', {})
        terminal_colors = len(colors_section.get('terminal', {}))
        
        print(f"\n  Statistics:")
        print(f"    • Total colors: {color_count}")
        print(f"    • Terminal colors: {terminal_colors}/16")
        print(f"    • Apps with overrides: {len(apps)}")
        
        if apps:
            print(f"    • Apps: {', '.join(sorted(apps.keys()))}")
    
    print_colored("\n" + "=" * 80 + "\n", "cyan")
    return True


def list_themes_with_colors():
    """List themes with color preview"""
    themes = get_available_themes()
    
    if not themes:
        print_colored("No themes found", "red")
        return False
    
    print_colored(f"\nThemes with Color Preview ({len(themes)}):\n", "cyan")
    
    for theme_name in themes:
        theme_data = load_theme(theme_name)
        if not theme_data:
            continue
        
        meta = theme_data.get('meta', {})
        
        print_colored(f"  {theme_name}", "green")
        print(f"    {meta.get('description', 'No description')}")
        
        # Color samples
        samples = get_color_sample(theme_data, limit=6)
        print("    Colors: ", end="")
        
        for name, hex_color in samples:
            block = print_color_block(hex_color, size=1)
            print(f"{block} ", end="")
        
        print(f"\n")
    
    return True


def list_themes_stats():
    """List themes with statistics"""
    themes = get_available_themes()
    
    if not themes:
        print_colored("No themes found", "red")
        return False
    
    print_colored(f"\nTheme Statistics ({len(themes)}):\n", "cyan")
    print_colored("=" * 80, "cyan")
    
    # Header
    header = f"{'Theme':<25} {'Colors':<10} {'Terminal':<12} {'Apps':<15}"
    print_colored(header, "cyan")
    print_colored("-" * 80, "cyan")
    
    # Data rows
    for theme_name in themes:
        theme_data = load_theme(theme_name)
        if not theme_data:
            continue
        
        color_count = count_colors(theme_data)
        colors_section = theme_data.get('colors', {})
        terminal_count = len(colors_section.get('terminal', {}))
        apps_count = len(colors_section.get('app_overrides', {}))
        
        row = f"{theme_name:<25} {color_count:<10} {terminal_count}/16{'':<6} {apps_count:<15}"
        print(row)
    
    print_colored("=" * 80 + "\n", "cyan")
    return True


def compare_themes(theme1_name: str, theme2_name: str) -> bool:
    """Compare two themes"""
    theme1 = load_theme(theme1_name)
    theme2 = load_theme(theme2_name)
    
    if not theme1:
        print_colored(f"Theme not found: {theme1_name}", "red")
        return False
    
    if not theme2:
        print_colored(f"Theme not found: {theme2_name}", "red")
        return False
    
    print_colored(f"\nComparing: {theme1_name} vs {theme2_name}\n", "cyan")
    print_colored("=" * 70, "cyan")
    
    # Metadata comparison
    meta1 = theme1.get('meta', {})
    meta2 = theme2.get('meta', {})
    
    print_colored("\nMetadata:", "blue")
    print(f"  Description:")
    print(f"    {theme1_name}: {meta1.get('description', 'N/A')}")
    print(f"    {theme2_name}: {meta2.get('description', 'N/A')}")
    
    print(f"\n  Author:")
    print(f"    {theme1_name}: {meta1.get('author', 'N/A')}")
    print(f"    {theme2_name}: {meta2.get('author', 'N/A')}")
    
    # Statistics comparison
    colors1 = count_colors(theme1)
    colors2 = count_colors(theme2)
    terminal1 = len(theme1.get('colors', {}).get('terminal', {}))
    terminal2 = len(theme2.get('colors', {}).get('terminal', {}))
    apps1 = len(theme1.get('app_overrides', {}))
    apps2 = len(theme2.get('app_overrides', {}))
    
    print_colored("\nStatistics:", "blue")
    print(f"  Total colors:      {colors1:<10} {colors2:<10}")
    print(f"  Terminal colors:   {terminal1:<10} {terminal2:<10}")
    print(f"  App overrides:     {apps1:<10} {apps2:<10}")
    
    # Color samples
    print_colored("\nColor Samples:", "blue")
    
    samples1 = get_color_sample(theme1, limit=4)
    samples2 = get_color_sample(theme2, limit=4)
    
    print(f"  {theme1_name:20}", end="")
    for name, hex_color in samples1:
        block = print_color_block(hex_color, size=1)
        print(f"{block} ", end="")
    print()
    
    print(f"  {theme2_name:20}", end="")
    for name, hex_color in samples2:
        block = print_color_block(hex_color, size=1)
        print(f"{block} ", end="")
    print()
    
    print_colored("\n" + "=" * 70 + "\n", "cyan")
    return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="List and inspect available color themes",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # List all themes
  %(prog)s
  
  # Show detailed information
  %(prog)s --detailed
  
  # Show color previews
  %(prog)s --colors
  
  # Show statistics
  %(prog)s --stats
  
  # Compare two themes
  %(prog)s --compare myoriginal nonchalant-purp
        """
    )
    
    parser.add_argument(
        '--detailed',
        action='store_true',
        help='Show detailed theme information'
    )
    
    parser.add_argument(
        '--colors',
        action='store_true',
        help='Show color previews (if terminal supports colors)'
    )
    
    parser.add_argument(
        '--stats',
        action='store_true',
        help='Show theme statistics'
    )
    
    parser.add_argument(
        '--compare',
        nargs=2,
        metavar=('THEME1', 'THEME2'),
        help='Compare two themes'
    )
    
    args = parser.parse_args()
    
    # Validate themes directory
    if not THEMES_DIR.exists():
        print_colored(f"Themes directory not found: {THEMES_DIR}", "red")
        return False
    
    # Execute appropriate command
    if args.compare:
        return compare_themes(args.compare[0], args.compare[1])
    elif args.detailed:
        return list_themes_detailed()
    elif args.colors:
        return list_themes_with_colors()
    elif args.stats:
        return list_themes_stats()
    else:
        return list_themes_basic()


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
