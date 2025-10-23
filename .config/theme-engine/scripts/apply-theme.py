#!/usr/bin/env python3
"""
Apply Theme Engine - Main theme application script

This script loads a theme from YAML, renders Jinja2 templates, and applies
the theme across all configured applications.

Usage:
    apply-theme.py <theme_name> [--dry-run]
    apply-theme.py --list
    apply-theme.py --help

Dependencies:
    - Jinja2 (template rendering)
    - PyYAML (theme loading)
    - colorama (colored terminal output)
"""

import os
import sys
import argparse
import yaml
import logging
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, TemplateNotFound, UndefinedError
from datetime import datetime
from typing import Dict, Any, Optional

try:
    from colorama import Fore, Back, Style, init
    init(autoreset=True)
    HAS_COLORAMA = True
except ImportError:
    HAS_COLORAMA = False


# Configuration
# Try to find theme-engine directory (check both repo and home)
_script_dir = Path(__file__).parent
_theme_engine_repo = _script_dir.parent  # Go up from scripts/ to theme-engine/
_theme_engine_home = Path.home() / ".config" / "theme-engine"

if _theme_engine_repo.exists() and (_theme_engine_repo / "themes").exists():
    THEME_ENGINE_DIR = _theme_engine_repo
else:
    THEME_ENGINE_DIR = _theme_engine_home

THEMES_DIR = THEME_ENGINE_DIR / "themes"
TEMPLATES_DIR = THEME_ENGINE_DIR / "templates"
GENERATED_DIR = THEME_ENGINE_DIR / "generated"
LOG_FILE = THEME_ENGINE_DIR / "apply-theme.log"

# App configuration: app_name -> (template_dir, output_file)
# Output files are written to theme-engine/generated/, then symlinked from app directories
APPS = {
    "waybar": (TEMPLATES_DIR / "waybar", GENERATED_DIR / "waybar" / "theme.css"),
    "kitty": (TEMPLATES_DIR / "kitty", GENERATED_DIR / "kitty" / "theme.conf"),
    "fuzzel": (TEMPLATES_DIR / "fuzzel", GENERATED_DIR / "fuzzel" / "theme.ini"),
    "wlogout": (TEMPLATES_DIR / "wlogout", GENERATED_DIR / "wlogout" / "theme.css"),
    "niri": (TEMPLATES_DIR / "niri", GENERATED_DIR / "niri" / "theme.kdl"),
    "hyprlock": (TEMPLATES_DIR / "hyprlock", GENERATED_DIR / "hypr" / "theme.conf"),
    "dunst": (TEMPLATES_DIR / "dunst", GENERATED_DIR / "dunst" / "theme.ini"),
}


def setup_logging(verbose: bool = False) -> logging.Logger:
    """Set up logging configuration"""
    level = logging.DEBUG if verbose else logging.INFO
    
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    return logging.getLogger(__name__)


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


def log_info(msg: str, color: str = "white"):
    """Log info message with optional color"""
    if HAS_COLORAMA:
        print(colorize(msg, color))
    else:
        print(msg)


def log_error(msg: str):
    """Log error message"""
    logger = logging.getLogger(__name__)
    logger.error(msg)
    if HAS_COLORAMA:
        print(colorize(f"ERROR: {msg}", "red"))
    else:
        print(f"ERROR: {msg}")


def log_success(msg: str):
    """Log success message"""
    logger = logging.getLogger(__name__)
    logger.info(msg)
    log_info(f"✓ {msg}", "green")


def log_warning(msg: str):
    """Log warning message"""
    logger = logging.getLogger(__name__)
    logger.warning(msg)
    log_info(f"⚠ {msg}", "yellow")


def validate_directories() -> bool:
    """Validate that all required directories exist"""
    required_dirs = [THEME_ENGINE_DIR, THEMES_DIR, TEMPLATES_DIR, GENERATED_DIR]
    
    for dir_path in required_dirs:
        if not dir_path.exists():
            log_error(f"Directory not found: {dir_path}")
            log_error("Run setup script to initialize theme engine")
            return False
    
    return True


def load_theme(theme_name: str) -> Optional[Dict[str, Any]]:
    """Load theme from YAML file"""
    theme_path = THEMES_DIR / f"{theme_name}.yaml"
    
    if not theme_path.exists():
        log_error(f"Theme file not found: {theme_path}")
        return None
    
    try:
        with open(theme_path, 'r') as f:
            theme_data = yaml.safe_load(f)
        
        if not isinstance(theme_data, dict):
            log_error(f"Invalid theme format in {theme_path}")
            return None
        
        log_info(f"✓ Loaded theme: {theme_name}", "cyan")
        return theme_data
    
    except yaml.YAMLError as e:
        log_error(f"YAML parse error in {theme_path}: {e}")
        return None
    except Exception as e:
        log_error(f"Error loading theme {theme_path}: {e}")
        return None


def create_jinja_environment() -> Environment:
    """Create and configure Jinja2 environment"""
    env = Environment(
        loader=FileSystemLoader(TEMPLATES_DIR),
        trim_blocks=True,
        lstrip_blocks=True
    )
    
    # Register custom filters
    env.filters['strip_hash'] = lambda x: x.lstrip('#')
    env.filters['add_alpha'] = lambda x: x + 'ff' if len(x) == 6 else x
    
    return env


def render_template(env: Environment, app_name: str, theme_data: Dict[str, Any]) -> Optional[str]:
    """Render template for a specific app"""
    template_dir = APPS.get(app_name, (None, None))[0]
    
    if not template_dir:
        log_error(f"Unknown app: {app_name}")
        return None
    
    # Determine template filename based on app
    if app_name in ["waybar", "wlogout"]:
        template_file = "theme.css.j2"
    elif app_name == "kitty":
        template_file = "theme.conf.j2"
    elif app_name == "niri":
        template_file = "theme.kdl.j2"
    elif app_name == "hyprlock":
        template_file = "theme.conf.j2"
    elif app_name in ["fuzzel", "dunst"]:
        template_file = "theme.ini.j2"
    else:
        template_file = "theme.j2"
    
    template_path = f"{app_name}/{template_file}"
    
    try:
        template = env.get_template(template_path)
        
        # Get app_overrides from nested colors.app_overrides location
        colors = theme_data.get('colors', {})
        app_overrides = colors.get('app_overrides', {}).get(app_name, {})
        
        rendered = template.render(
            colors=colors,
            app_overrides=app_overrides,
            meta=theme_data.get('meta', {}),
            generated_date=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
        
        log_info(f"  ✓ Rendered {app_name} template", "cyan")
        return rendered
    
    except TemplateNotFound as e:
        log_error(f"Template not found for {app_name}: {e}")
        return None
    except UndefinedError as e:
        log_error(f"Template error in {app_name}: {e}")
        return None
    except Exception as e:
        log_error(f"Error rendering {app_name} template: {e}")
        return None


def write_output(app_name: str, content: str, dry_run: bool = False) -> bool:
    """Write rendered template to output file"""
    output_path = APPS.get(app_name, (None, None))[1]
    
    if not output_path:
        log_error(f"No output path for app: {app_name}")
        return False
    
    # Create parent directory if it doesn't exist
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if dry_run:
        log_info(f"  [DRY-RUN] Would write to: {output_path}", "yellow")
        return True
    
    try:
        with open(output_path, 'w') as f:
            f.write(content)
        
        log_success(f"Wrote {app_name} config to {output_path}")
        return True
    
    except IOError as e:
        log_error(f"Error writing to {output_path}: {e}")
        return False
    except Exception as e:
        log_error(f"Unexpected error writing {app_name} output: {e}")
        return False


def apply_theme(theme_name: str, dry_run: bool = False, verbose: bool = False) -> bool:
    """Main function to apply theme"""
    logger = setup_logging(verbose)
    
    log_info(f"\n{'='*60}", "cyan")
    log_info(f"Applying theme: {theme_name}", "cyan")
    if dry_run:
        log_info("[DRY-RUN MODE]", "yellow")
    log_info(f"{'='*60}\n", "cyan")
    
    # Validate directories
    if not validate_directories():
        return False
    
    # Load theme
    theme_data = load_theme(theme_name)
    if not theme_data:
        return False
    
    # Create Jinja environment
    env = create_jinja_environment()
    
    # Render and write for each app
    success_count = 0
    total_apps = len(APPS)
    
    for app_name in sorted(APPS.keys()):
        log_info(f"\nProcessing {app_name}...", "blue")
        
        # Render template
        rendered = render_template(env, app_name, theme_data)
        if not rendered:
            continue
        
        # Write output
        if write_output(app_name, rendered, dry_run):
            success_count += 1
    
    # Summary
    log_info(f"\n{'='*60}", "cyan")
    if success_count == total_apps:
        log_success(f"Theme applied successfully! ({success_count}/{total_apps} apps)")
        log_info(f"{'='*60}\n", "cyan")
        return True
    else:
        log_warning(f"Theme partially applied ({success_count}/{total_apps} apps)")
        log_info(f"{'='*60}\n", "cyan")
        return success_count > 0


def list_themes() -> bool:
    """List available themes"""
    if not THEMES_DIR.exists():
        log_error(f"Themes directory not found: {THEMES_DIR}")
        return False
    
    themes = [f.stem for f in THEMES_DIR.glob("*.yaml")]
    
    if not themes:
        log_warning("No themes found")
        return True
    
    log_info(f"\nAvailable themes ({len(themes)}):\n", "cyan")
    
    for theme_name in sorted(themes):
        theme_path = THEMES_DIR / f"{theme_name}.yaml"
        try:
            with open(theme_path, 'r') as f:
                data = yaml.safe_load(f)
            
            meta = data.get('meta', {})
            description = meta.get('description', 'No description')
            author = meta.get('author', 'Unknown')
            
            log_info(f"  • {theme_name}", "green")
            log_info(f"    Description: {description}")
            log_info(f"    Author: {author}\n")
        
        except Exception as e:
            log_info(f"  • {theme_name}", "green")
            log_warning(f"    Error reading metadata: {e}\n")
    
    return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Apply color themes across all configured applications",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Apply a theme
  %(prog)s myoriginal
  
  # Apply with dry-run
  %(prog)s myoriginal --dry-run
  
  # List available themes
  %(prog)s --list
  
  # Verbose logging
  %(prog)s myoriginal -v
        """
    )
    
    parser.add_argument(
        'theme',
        nargs='?',
        help='Theme name to apply (without .yaml extension)'
    )
    
    parser.add_argument(
        '--list',
        action='store_true',
        help='List available themes'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without writing files'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )
    
    args = parser.parse_args()
    
    # List themes
    if args.list:
        return list_themes()
    
    # Apply theme
    if not args.theme:
        parser.print_help()
        return False
    
    return apply_theme(args.theme, dry_run=args.dry_run, verbose=args.verbose)


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
