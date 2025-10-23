#!/bin/bash

################################################################################
# THEME ENGINE INSTALLATION SCRIPT
#
# Automated setup for the Theme Engine system
# Installs dependencies, creates directory structure, sets up symlinks, and
# applies the default theme
#
# Usage: bash install.sh [--verbose] [--help]
#
# Features:
#   - Checks system dependencies
#   - Installs Python packages
#   - Creates directory structure
#   - Sets up application symlinks
#   - Applies default theme
#   - Validates installation
#   - Reloads applications
#
################################################################################

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
THEME_ENGINE_DIR="${HOME}/.config/theme-engine"
SCRIPTS_DIR="${THEME_ENGINE_DIR}/scripts"
GENERATED_DIR="${THEME_ENGINE_DIR}/generated"

# Configuration
VERBOSE=false
DEFAULT_THEME="myoriginal"

################################################################################
# HELPER FUNCTIONS
################################################################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         THEME ENGINE - INSTALLATION SCRIPT                    ║"
    echo "║                                                                ║"
    echo "║      Installing theme management system for dotfiles          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}  [DEBUG]${NC} $1"
    fi
}

show_help() {
    cat << 'EOF'
THEME ENGINE INSTALLATION SCRIPT

Usage: bash install.sh [OPTIONS]

Options:
    -v, --verbose       Show detailed output
    -h, --help          Show this help message

Examples:
    bash install.sh                 # Standard installation
    bash install.sh --verbose       # With detailed output

Features:
    • Installs Python dependencies (PyYAML, Jinja2, colorama)
    • Creates ~/.config/theme-engine directory structure
    • Creates symlinks for all 4 applications
    • Applies default theme (myoriginal)
    • Reloads all applications
    • Validates installation

Requirements:
    • bash 4.0+
    • python3 3.6+
    • pip or pip3

For more information, see: ~/.config/theme-engine/README.md

EOF
}

################################################################################
# INSTALLATION STEPS
################################################################################

check_dependencies() {
    print_step "Checking system dependencies..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        return 1
    fi
    local py_version=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python 3 found (version: $py_version)"
    log_verbose "Python executable: $(which python3)"
    
    # Check pip
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        print_error "pip/pip3 is not installed"
        return 1
    fi
    local pip_cmd="pip3"
    if ! command -v pip3 &> /dev/null; then
        pip_cmd="pip"
    fi
    print_success "pip found"
    log_verbose "pip command: $pip_cmd"
    
    return 0
}

install_python_packages() {
    print_step "Installing Python dependencies..."
    
    local packages=("PyYAML" "Jinja2" "colorama")
    
    for package in "${packages[@]}"; do
        if python3 -c "import ${package,,}" 2>/dev/null; then
            print_success "$package already installed"
        else
            echo "Installing $package..."
            if python3 -m pip install "$package" > /dev/null 2>&1; then
                print_success "$package installed"
            else
                print_error "Failed to install $package"
                return 1
            fi
        fi
    done
    
    return 0
}

create_directories() {
    print_step "Creating directory structure..."
    
    local dirs=(
        "${THEME_ENGINE_DIR}"
        "${THEME_ENGINE_DIR}/themes"
        "${THEME_ENGINE_DIR}/templates"
        "${THEME_ENGINE_DIR}/scripts"
        "${GENERATED_DIR}"
        "${GENERATED_DIR}/waybar"
        "${GENERATED_DIR}/kitty"
        "${GENERATED_DIR}/fuzzel"
        "${GENERATED_DIR}/wlogout"
        "${HOME}/.config/waybar/themes"
        "${HOME}/.config/kitty/themes"
        "${HOME}/.config/fuzzel/themes"
        "${HOME}/.config/wlogout/themes"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created: $dir"
            log_verbose "Directory: $dir"
        else
            print_success "Directory exists: $dir"
            log_verbose "Exists: $dir"
        fi
    done
    
    return 0
}

create_symlinks() {
    print_step "Creating symlinks to generated theme files..."
    
    # Define symlinks: source -> target
    local symlinks=(
        "${GENERATED_DIR}/waybar/theme.css:${HOME}/.config/waybar/themes/active.css"
        "${GENERATED_DIR}/kitty/theme.conf:${HOME}/.config/kitty/themes/active.conf"
        "${GENERATED_DIR}/fuzzel/theme.ini:${HOME}/.config/fuzzel/themes/active.ini"
        "${GENERATED_DIR}/wlogout/theme.css:${HOME}/.config/wlogout/themes/active.css"
    )
    
    for link in "${symlinks[@]}"; do
        IFS=':' read -r source target <<< "$link"
        
        # Remove existing symlink/file
        if [ -L "$target" ] || [ -f "$target" ]; then
            rm -f "$target"
            log_verbose "Removed existing: $target"
        fi
        
        # Create new symlink
        if ln -sf "$source" "$target"; then
            print_success "Symlink created: $(basename $target)"
            log_verbose "Link: $target -> $source"
        else
            print_error "Failed to create symlink: $target"
            return 1
        fi
    done
    
    return 0
}

apply_default_theme() {
    print_step "Applying default theme (${DEFAULT_THEME})..."
    
    if [ ! -f "${SCRIPTS_DIR}/apply-theme.py" ]; then
        print_error "apply-theme.py not found at ${SCRIPTS_DIR}/apply-theme.py"
        return 1
    fi
    
    if python3 "${SCRIPTS_DIR}/apply-theme.py" "${DEFAULT_THEME}" > /dev/null 2>&1; then
        print_success "Theme applied: ${DEFAULT_THEME}"
    else
        print_warning "Theme application had issues (check symlinks and paths)"
        log_verbose "Theme application command: python3 ${SCRIPTS_DIR}/apply-theme.py ${DEFAULT_THEME}"
    fi
    
    return 0
}

reload_applications() {
    print_step "Reloading applications..."
    
    if [ ! -f "${SCRIPTS_DIR}/reload-apps.sh" ]; then
        print_warning "reload-apps.sh not found - skipping application reload"
        return 0
    fi
    
    if bash "${SCRIPTS_DIR}/reload-apps.sh" > /dev/null 2>&1; then
        print_success "Applications reloaded"
    else
        print_warning "Application reload had issues (apps may need manual restart)"
        log_verbose "Reload command: bash ${SCRIPTS_DIR}/reload-apps.sh"
    fi
    
    return 0
}

validate_installation() {
    print_step "Validating installation..."
    
    local errors=0
    
    # Check directories
    if [ ! -d "${THEME_ENGINE_DIR}" ]; then
        print_error "Theme engine directory not found"
        ((errors++))
    fi
    
    # Check symlinks
    if [ ! -L "${HOME}/.config/waybar/themes/active.css" ]; then
        print_error "Waybar symlink not created"
        ((errors++))
    else
        print_success "Waybar symlink: OK"
    fi
    
    if [ ! -L "${HOME}/.config/kitty/themes/active.conf" ]; then
        print_error "Kitty symlink not created"
        ((errors++))
    else
        print_success "Kitty symlink: OK"
    fi
    
    if [ ! -L "${HOME}/.config/fuzzel/themes/active.ini" ]; then
        print_error "Fuzzel symlink not created"
        ((errors++))
    else
        print_success "Fuzzel symlink: OK"
    fi
    
    if [ ! -L "${HOME}/.config/wlogout/themes/active.css" ]; then
        print_error "Wlogout symlink not created"
        ((errors++))
    else
        print_success "Wlogout symlink: OK"
    fi
    
    # Check scripts
    if [ ! -f "${SCRIPTS_DIR}/apply-theme.py" ]; then
        print_error "apply-theme.py not found"
        ((errors++))
    else
        print_success "apply-theme.py: OK"
    fi
    
    if [ ! -f "${SCRIPTS_DIR}/list-themes.py" ]; then
        print_error "list-themes.py not found"
        ((errors++))
    else
        print_success "list-themes.py: OK"
    fi
    
    if [ ! -f "${SCRIPTS_DIR}/validate-theme.py" ]; then
        print_error "validate-theme.py not found"
        ((errors++))
    else
        print_success "validate-theme.py: OK"
    fi
    
    if [ ! -f "${SCRIPTS_DIR}/reload-apps.sh" ]; then
        print_error "reload-apps.sh not found"
        ((errors++))
    else
        print_success "reload-apps.sh: OK"
    fi
    
    return $errors
}

print_usage() {
    echo ""
    echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}INSTALLATION COMPLETE!${NC}"
    echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Theme Engine is now ready to use!"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo "  1. List available themes:"
    echo "     python3 ${SCRIPTS_DIR}/list-themes.py --detailed"
    echo ""
    echo "  2. Apply a theme:"
    echo "     python3 ${SCRIPTS_DIR}/apply-theme.py myoriginal"
    echo ""
    echo "  3. Reload apps:"
    echo "     bash ${SCRIPTS_DIR}/reload-apps.sh"
    echo ""
    echo -e "${CYAN}Create Aliases (optional):${NC}"
    echo "Add to ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "alias apply-theme='python3 ${SCRIPTS_DIR}/apply-theme.py'"
    echo "alias list-themes='python3 ${SCRIPTS_DIR}/list-themes.py'"
    echo "alias validate-theme='python3 ${SCRIPTS_DIR}/validate-theme.py'"
    echo "alias reload-apps='bash ${SCRIPTS_DIR}/reload-apps.sh'"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "  • README: ${THEME_ENGINE_DIR}/README.md"
    echo "  • Themes: ${THEME_ENGINE_DIR}/themes/"
    echo "  • Templates: ${THEME_ENGINE_DIR}/templates/"
    echo "  • Scripts: ${SCRIPTS_DIR}/"
    echo ""
    echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# MAIN INSTALLATION FLOW
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_banner
    echo ""
    
    # Run installation steps
    check_dependencies || { print_error "Dependency check failed"; exit 1; }
    echo ""
    
    install_python_packages || { print_error "Python package installation failed"; exit 1; }
    echo ""
    
    create_directories || { print_error "Directory creation failed"; exit 1; }
    echo ""
    
    create_symlinks || { print_error "Symlink creation failed"; exit 1; }
    echo ""
    
    apply_default_theme || { print_warning "Theme application had issues"; }
    echo ""
    
    reload_applications || { print_warning "Application reload had issues"; }
    echo ""
    
    # Validate
    if validate_installation; then
        print_success "All validation checks passed!"
        echo ""
        print_usage
        exit 0
    else
        print_error "Some validation checks failed"
        exit 1
    fi
}

# Run main function
main "$@"
