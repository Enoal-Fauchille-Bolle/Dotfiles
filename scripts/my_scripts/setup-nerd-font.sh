#!/bin/bash
# setup-nerd-font.sh - Installs Nerd Fonts and applies them to Ptyxis

# Configuration
NERD_FONTS_VERSION="v3.4.0"
NERD_FONTS_ARCHIVES=(
    DroidSansMono
)
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
PTYXIS_FONT="DroidSansM Nerd Font 12"

# Color codes for output
RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
RESET='\033[0m'

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

print_error() {
    echo -e "${RED}✗ $1${RESET}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${RESET}"
}

print_header() {
    echo -e "\n${BLUE}================================================${RESET}"
    echo -e "${BLUE}$1${RESET}"
    echo -e "${BLUE}================================================${RESET}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
check_dependencies() {
    local missing=0

    for cmd in curl unzip fc-cache; do
        if ! command_exists "$cmd"; then
            print_error "$cmd is required but not installed"
            missing=1
        fi
    done

    [ $missing -eq 0 ] || exit 1
}

# Download and extract one Nerd Font archive
install_font() {
    local archive="$1"
    local target="$FONT_DIR/$archive"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${archive}.zip"
    local tmp_zip

    if [ -d "$target" ] && [ "$FORCE" != "1" ]; then
        print_warning "$archive already installed - use --force to reinstall"
        return 0
    fi

    tmp_zip=$(mktemp --suffix=.zip) || return 1

    print_info "Downloading $archive ($NERD_FONTS_VERSION)..."
    if ! curl -fsSL -o "$tmp_zip" "$url"; then
        print_error "Failed to download $archive"
        rm -f "$tmp_zip"
        return 1
    fi

    print_info "Extracting $archive to $target..."
    rm -rf "$target"
    mkdir -p "$target"
    if unzip -q -o "$tmp_zip" -x "*.md" "*.txt" -d "$target"; then
        print_success "$archive installed"
    else
        print_error "Failed to extract $archive"
        rm -f "$tmp_zip"
        return 1
    fi

    rm -f "$tmp_zip"
}

# Install every configured font, then refresh the font cache
install_fonts() {
    print_header "Nerd Fonts Installation"

    mkdir -p "$FONT_DIR"

    for archive in "${NERD_FONTS_ARCHIVES[@]}"; do
        install_font "$archive"
    done

    print_info "Refreshing font cache..."
    if fc-cache -f "$FONT_DIR" >/dev/null; then
        print_success "Font cache refreshed"
    else
        print_error "Font cache refresh failed"
    fi
}

# Apply the font to Ptyxis (settings live in GSettings, not in a config file)
configure_ptyxis() {
    print_header "Ptyxis Configuration"

    if ! command_exists gsettings; then
        print_warning "gsettings not found - skipping Ptyxis configuration"
        return 0
    fi

    if ! gsettings list-schemas | grep -q '^org.gnome.Ptyxis$'; then
        print_warning "Ptyxis not installed - skipping Ptyxis configuration"
        return 0
    fi

    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name "$PTYXIS_FONT"
    print_success "Ptyxis font set to '$PTYXIS_FONT'"
}

# Show which font families are now available
print_summary() {
    print_header "Installed Nerd Font Families"

    fc-list : family | tr ',' '\n' | grep -i "nerd font" | sort -u
}

# Main execution
main() {
    check_dependencies
    install_fonts
    configure_ptyxis
    print_summary

    echo ""
    print_info "Restart Ptyxis and VS Code to pick up the new font"
}

FORCE=0
[ "$1" = "--force" ] && FORCE=1

main
