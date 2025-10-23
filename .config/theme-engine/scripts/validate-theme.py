#!/usr/bin/env python3
"""
Validate Theme Script - Validate and verify theme YAML files

This script validates theme YAML files for correct syntax, required fields,
and proper color format. It reports any errors or issues found.

Usage:
    validate-theme.py
    validate-theme.py <theme_name>
    validate-theme.py --all
    validate-theme.py --fix <theme_name>
    validate-theme.py --help

Dependencies:
    - PyYAML (theme validation)
    - colorama (colored output)
"""

import os
import sys
import argparse
import yaml
import re
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

# Required fields in theme
REQUIRED_META_FIELDS = ['name', 'description', 'author', 'version']
REQUIRED_COLOR_SECTIONS = ['background', 'foreground', 'accent', 'semantic', 'ui', 'terminal']


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
    }
    
    return f"{color_map.get(color, '')}{text}{Style.RESET_ALL}"


def print_status(message: str, status: str = "info"):
    """Print status message"""
    symbols = {
        "ok": "✓",
        "error": "✗",
        "warning": "⚠",
        "info": "ℹ"
    }
    colors = {
        "ok": "green",
        "error": "red",
        "warning": "yellow",
        "info": "cyan"
    }
    
    symbol = symbols.get(status, "•")
    color = colors.get(status, "white")
    
    print(colorize(f"{symbol} {message}", color))


def is_valid_hex_color(value: str) -> bool:
    """Check if value is valid hex color"""
    if not isinstance(value, str):
        return False
    return re.match(r'^#[0-9a-fA-F]{6}$', value) is not None


def count_colors(colors_dict: Dict[str, Any]) -> int:
    """Count colors in dictionary recursively"""
    count = 0
    for v in colors_dict.values():
        if isinstance(v, dict):
            count += count_colors(v)
        elif isinstance(v, str) and is_valid_hex_color(v):
            count += 1
    return count


def validate_hex_colors(colors_dict: Dict[str, Any], path: str = "colors") -> List[str]:
    """Validate hex colors in dictionary"""
    errors = []
    for k, v in colors_dict.items():
        current_path = f"{path}.{k}"
        if isinstance(v, dict):
            errors.extend(validate_hex_colors(v, current_path))
        elif isinstance(v, str):
            if not is_valid_hex_color(v):
                errors.append(f"Invalid color format at {current_path}: '{v}' (expected #RRGGBB)")
        elif v is not None:
            errors.append(f"Invalid type at {current_path}: {type(v).__name__} (expected string)")
    return errors


def get_available_themes() -> List[str]:
    """Get list of available theme names"""
    if not THEMES_DIR.exists():
        return []
    themes = [f.stem for f in THEMES_DIR.glob("*.yaml")]
    return sorted(themes)


def load_theme_file(theme_name: str) -> Tuple[Optional[Dict[str, Any]], List[str]]:
    """Load and parse theme file"""
    theme_path = THEMES_DIR / f"{theme_name}.yaml"
    errors = []
    
    if not theme_path.exists():
        errors.append(f"Theme file not found: {theme_path}")
        return None, errors
    
    try:
        with open(theme_path, 'r') as f:
            theme_data = yaml.safe_load(f)
        
        if not isinstance(theme_data, dict):
            errors.append("Invalid YAML structure: expected dictionary at root level")
            return None, errors
        
        return theme_data, errors
    
    except yaml.YAMLError as e:
        errors.append(f"YAML parse error: {e}")
        return None, errors
    except Exception as e:
        errors.append(f"Error reading file: {e}")
        return None, errors


def validate_metadata(theme_data: Dict[str, Any]) -> List[str]:
    """Validate theme metadata"""
    errors = []
    meta = theme_data.get('meta', {})
    
    if not isinstance(meta, dict):
        errors.append("Invalid meta: expected dictionary")
        return errors
    
    for field in REQUIRED_META_FIELDS:
        if field not in meta:
            errors.append(f"Missing required field: meta.{field}")
        elif not isinstance(meta[field], str):
            errors.append(f"Invalid type for meta.{field}: {type(meta[field]).__name__} (expected string)")
        elif not meta[field].strip():
            errors.append(f"Empty value for meta.{field}")
    
    return errors


def validate_colors_structure(theme_data: Dict[str, Any]) -> List[str]:
    """Validate colors structure"""
    errors = []
    colors = theme_data.get('colors', {})
    
    if not isinstance(colors, dict):
        errors.append("Invalid colors: expected dictionary")
        return errors
    
    if not colors:
        errors.append("Empty colors section")
        return errors
    
    # Check required sections
    for section in REQUIRED_COLOR_SECTIONS:
        if section not in colors:
            errors.append(f"Missing required color section: colors.{section}")
    
    return errors


def validate_color_formats(theme_data: Dict[str, Any]) -> List[str]:
    """Validate all color formats in theme"""
    errors = []
    colors = theme_data.get('colors', {})
    
    # Validate all colors (but skip app_overrides nested in colors)
    for k, v in colors.items():
        if k != 'app_overrides':
            if isinstance(v, dict):
                color_errors = validate_hex_colors({k: v}, "colors")
                errors.extend(color_errors)
    
    # Validate app overrides if present (nested in colors)
    if 'app_overrides' in colors:
        app_overrides = colors['app_overrides']
        if isinstance(app_overrides, dict):
            for app_name, app_colors in app_overrides.items():
                if isinstance(app_colors, dict):
                    override_errors = validate_hex_colors(app_colors, f"colors.app_overrides.{app_name}")
                    errors.extend(override_errors)
    
    return errors


def validate_theme(theme_name: str) -> Tuple[bool, List[str], Dict[str, Any]]:
    """Validate complete theme"""
    all_errors = []
    
    # Load file
    theme_data, load_errors = load_theme_file(theme_name)
    all_errors.extend(load_errors)
    
    if theme_data is None:
        return False, all_errors, {}
    
    # Validate metadata
    meta_errors = validate_metadata(theme_data)
    all_errors.extend(meta_errors)
    
    # Validate colors structure
    structure_errors = validate_colors_structure(theme_data)
    all_errors.extend(structure_errors)
    
    # Validate color formats
    format_errors = validate_color_formats(theme_data)
    all_errors.extend(format_errors)
    
    return len(all_errors) == 0, all_errors, theme_data


def validate_single_theme(theme_name: str) -> bool:
    """Validate and report on a single theme"""
    print(colorize(f"\nValidating theme: {theme_name}", "cyan"))
    print(colorize("-" * 70, "cyan"))
    
    is_valid, errors, theme_data = validate_theme(theme_name)
    
    if is_valid:
        print_status("Theme is valid", "ok")
        
        # Show stats
        colors = theme_data.get('colors', {})
        color_count = count_colors(colors)
        # Count colors excluding app_overrides from total
        colors_no_overrides = {k: v for k, v in colors.items() if k != 'app_overrides'}
        color_count_actual = count_colors(colors_no_overrides)
        terminal_colors = len(colors.get('terminal', {}))
        apps = len(colors.get('app_overrides', {}))
        
        print(f"\n  Statistics:")
        print(f"    • Total colors: {color_count_actual}")
        print(f"    • Terminal colors: {terminal_colors}/16")
        print(f"    • App overrides: {apps} apps")
        
        return True
    else:
        print_status("Theme validation failed", "error")
        
        if errors:
            print(f"\n  Errors ({len(errors)}):")
            for i, error in enumerate(errors, 1):
                print(colorize(f"    {i}. {error}", "red"))
        
        return False


def validate_all_themes() -> bool:
    """Validate all themes"""
    themes = get_available_themes()
    
    if not themes:
        print_status("No themes found", "warning")
        return False
    
    print(colorize(f"\nValidating all themes ({len(themes)}):", "cyan"))
    print(colorize("=" * 70, "cyan"))
    
    results = {}
    for theme_name in themes:
        is_valid, errors, _ = validate_theme(theme_name)
        results[theme_name] = (is_valid, len(errors))
        
        symbol = "✓" if is_valid else "✗"
        color = "green" if is_valid else "red"
        error_info = f" ({len(errors)} errors)" if errors else ""
        print(colorize(f"{symbol} {theme_name}{error_info}", color))
    
    print(colorize("=" * 70, "cyan"))
    
    # Summary
    valid_count = sum(1 for is_valid, _ in results.values() if is_valid)
    total_count = len(results)
    
    if valid_count == total_count:
        print_status(f"All {total_count} themes are valid", "ok")
        return True
    else:
        print_status(f"{valid_count}/{total_count} themes are valid", "warning")
        return False


def fix_theme_suggestions(theme_name: str) -> bool:
    """Show suggestions to fix a theme"""
    print(colorize(f"\nFix Suggestions for: {theme_name}", "cyan"))
    print(colorize("-" * 70, "cyan"))
    
    is_valid, errors, theme_data = validate_theme(theme_name)
    
    if is_valid:
        print_status("No issues found - theme is already valid", "ok")
        return True
    
    print_status(f"Found {len(errors)} issue(s)", "warning")
    print("\nSuggested Fixes:")
    
    fixes = []
    for error in errors:
        if "Missing required field" in error:
            field = error.split(": ")[-1]
            fixes.append(f"• Add missing field: {field}")
        elif "Empty value" in error:
            field = error.split(": ")[-1]
            fixes.append(f"• Fill in empty value for: {field}")
        elif "Invalid color format" in error:
            fixes.append(f"• Use hex color format #RRGGBB")
        elif "Invalid type" in error:
            fixes.append(f"• Ensure value is a string (in quotes)")
        elif "Missing required color section" in error:
            section = error.split(": ")[-1]
            fixes.append(f"• Add color section: {section}")
    
    # Remove duplicates
    fixes = list(dict.fromkeys(fixes))
    
    for fix in fixes:
        print(colorize(fix, "yellow"))
    
    return False


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Validate theme YAML files for correctness",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Validate all themes
  %(prog)s --all
  
  # Validate specific theme
  %(prog)s myoriginal
  
  # Show fix suggestions
  %(prog)s --fix myoriginal
  
  # List themes and validate each one
  %(prog)s
        """
    )
    
    parser.add_argument(
        'theme',
        nargs='?',
        help='Theme name to validate'
    )
    
    parser.add_argument(
        '--all',
        action='store_true',
        help='Validate all themes'
    )
    
    parser.add_argument(
        '--fix',
        metavar='THEME',
        help='Show suggestions to fix a theme'
    )
    
    args = parser.parse_args()
    
    # Validate directory exists
    if not THEMES_DIR.exists():
        print_status(f"Themes directory not found: {THEMES_DIR}", "error")
        return False
    
    # Execute appropriate command
    if args.fix:
        return fix_theme_suggestions(args.fix)
    elif args.all:
        return validate_all_themes()
    elif args.theme:
        return validate_single_theme(args.theme)
    else:
        return validate_all_themes()


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
