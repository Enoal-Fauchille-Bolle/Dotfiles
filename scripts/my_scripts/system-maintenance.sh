#!/bin/bash

# Color codes for output
RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
RESET='\033[0m'

# Counters for summary
SUCCESS_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${RESET}"
    ((SUCCESS_COUNT++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
    ((WARNING_COUNT++))
}

print_error() {
    echo -e "${RED}✗ $1${RESET}"
    ((ERROR_COUNT++))
}

print_info() {
    echo -e "${BLUE}ℹ $1${RESET}"
}

print_header() {
    echo -e "\n${BLUE}================================================${RESET}"
    echo -e "${BLUE}$1${RESET}"
    echo -e "${BLUE}================================================${RESET}"
}

# Function to ask for confirmation
ask_confirmation() {
    local message="$1"
    echo -e "${YELLOW}$message (y/N): ${RESET}"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install missing package managers
install_missing_managers() {
    print_header "Installing Missing Package Managers"

    # Install pnpm if npm exists but pnpm doesn't
    if command_exists npm && ! command_exists pnpm; then
        print_info "Installing pnpm..."
        if npm install -g pnpm; then
            print_success "pnpm installed successfully"
        else
            print_error "Failed to install pnpm"
        fi
    fi

    # Install pip if python3 exists but pip doesn't
    if command_exists python3 && ! command_exists pip; then
        print_info "Installing pip..."
        if python3 -m ensurepip --upgrade; then
            print_success "pip installed successfully"
        else
            print_error "Failed to install pip"
        fi
    fi

    # Install gem if ruby exists but gem doesn't
    if command_exists ruby && ! command_exists gem; then
        print_warning "Ruby found but gem not available - may need manual installation"
    fi

    # Install composer if php exists but composer doesn't
    if command_exists php && ! command_exists composer; then
        print_info "Installing composer..."
        if curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; then
            print_success "composer installed successfully"
        else
            print_error "Failed to install composer"
        fi
    fi
}

# System packages update
update_system_packages() {
    print_header "System Package Updates"

    if ask_confirmation "Update system packages with dnf?"; then
        if sudo dnf update -y; then
            print_success "System packages updated successfully"
        else
            print_error "System package update failed"
        fi
    else
        print_info "Skipping system package updates"
    fi
}

# Flatpak updates
update_flatpak() {
    print_header "Flatpak Updates"

    if command_exists flatpak; then
        print_info "Updating system Flatpak packages..."
        if sudo flatpak update -y --system 2>/dev/null; then
            print_success "System Flatpak packages updated"
        else
            print_warning "System Flatpak update had issues or no packages to update"
        fi

        print_info "Updating user Flatpak packages..."
        if flatpak update -y --user 2>/dev/null; then
            print_success "User Flatpak packages updated"
        else
            print_warning "User Flatpak update had issues or no packages to update"
        fi
    else
        print_warning "Flatpak not found - skipping"
    fi
}

# Rust toolchain and packages
update_rust() {
    print_header "Rust Updates"

    if command_exists rustup; then
        print_info "Updating Rust toolchain..."
        if rustup update; then
            print_success "Rust toolchain updated"
        else
            print_error "Rust toolchain update failed"
        fi
    else
        print_warning "rustup not found - skipping Rust toolchain update"
    fi

    if command_exists cargo; then
        print_info "Updating Rust packages..."
        # if command_exists cargo-update
        if cargo install-update --help >/dev/null 2>&1; then
            if cargo install-update -a; then
                print_success "Rust packages updated"
            else
                print_error "Rust packages update failed"
            fi
        else
            print_warning "cargo-update not installed - skipping Rust package updates"
            print_info "Install with: cargo install cargo-update"
        fi
    else
        print_warning "cargo not found - skipping Rust packages"
    fi
}

# Haskell updates
update_haskell() {
    print_header "Haskell Updates"

    if command_exists ghcup; then
        print_info "Updating Haskell toolchain..."
        if ghcup upgrade; then
            print_success "Haskell toolchain updated"
        else
            print_error "Haskell toolchain update failed"
        fi
    else
        print_warning "ghcup not found - skipping Haskell updates"
    fi
}

# Node.js packages (pnpm)
update_nodejs() {
    print_header "Node.js Global Package Updates"

    if command_exists pnpm; then
        print_info "Updating global pnpm packages..."
        if pnpm update -g; then
            print_success "Global pnpm packages updated"
        else
            print_error "Global pnpm package update failed"
        fi
    elif command_exists npm; then
        print_info "pnpm not found, using npm for global packages..."
        if npm update -g; then
            print_success "Global npm packages updated"
        else
            print_error "Global npm package update failed"
        fi
    else
        print_warning "No Node.js package manager found - skipping"
    fi
}

# Python packages
update_python() {
    print_header "Python Global Package Updates"

    if command_exists pip; then
        print_info "Updating global pip packages..."
        # Get list of outdated packages
        outdated_packages=$(pip list --outdated --format=freeze 2>/dev/null | grep -v '^-e' | cut -d = -f 1)

        if [ -n "$outdated_packages" ]; then
            echo "$outdated_packages" | xargs -n1 pip install -U
            if [ $? -eq 0 ]; then
                print_success "Global pip packages updated"
            else
                print_error "Some pip packages failed to update"
            fi
        else
            print_success "All pip packages are up to date"
        fi
    else
        print_warning "pip not found - skipping Python package updates"
    fi

    # pipx updates
    if command_exists pipx; then
        print_info "Updating pipx packages..."
        if pipx upgrade-all; then
            print_success "pipx packages updated"
        else
            print_warning "pipx package update had issues"
        fi
    fi
}

# Ruby gems
update_ruby() {
    print_header "Ruby Global Gem Updates"

    if command_exists gem; then
        print_info "Updating global Ruby gems..."
        if gem update; then
            print_success "Global Ruby gems updated"
        else
            print_error "Ruby gem update failed"
        fi
    else
        print_warning "gem not found - skipping Ruby gem updates"
    fi
}

# Go packages
update_go() {
    print_header "Go Package Updates"

    if command_exists go; then
        print_info "Go found, but no automatic update mechanism for globally installed packages"
        print_info "Consider manually updating important Go tools if needed"
    else
        print_warning "go not found - skipping Go package updates"
    fi
}

# PHP Composer global packages
update_php() {
    print_header "PHP Global Package Updates"

    if command_exists composer; then
        print_info "Updating global Composer packages..."
        if composer global update; then
            print_success "Global Composer packages updated"
        else
            print_warning "Composer global update had issues or no packages installed"
        fi
    else
        print_warning "composer not found - skipping PHP package updates"
    fi
}

# .NET global tools
update_dotnet() {
    print_header ".NET Global Tool Updates"

    if command_exists dotnet; then
        print_info "Updating .NET global tools..."
        # List and update each tool
        dotnet tool list -g 2>/dev/null | tail -n +3 | awk '{print $1}' | while read -r tool; do
            if [ -n "$tool" ]; then
                if dotnet tool update -g "$tool"; then
                    print_success ".NET tool $tool updated"
                else
                    print_warning ".NET tool $tool update failed"
                fi
            fi
        done
    else
        print_warning "dotnet not found - skipping .NET tool updates"
    fi
}

# System cleanup
cleanup_system() {
    print_header "System Cleanup"

    # DNF cleanup
    if command_exists dnf; then
        print_info "Cleaning DNF package cache..."
        if sudo dnf clean all; then
            print_success "DNF cache cleaned"
        else
            print_error "DNF cache cleanup failed"
        fi
    fi

    # Flatpak cleanup
    if command_exists flatpak; then
        print_info "Repairing Flatpak installations..."
        sudo flatpak repair --system 2>/dev/null && print_success "System Flatpak repaired" || print_warning "System Flatpak repair had issues"
        flatpak repair --user 2>/dev/null && print_success "User Flatpak repaired" || print_warning "User Flatpak repair had issues"
    fi

    # Cargo cleanup
    if command_exists cargo; then
        print_info "Cleaning Cargo cache..."
        if command_exists cargo-cache; then
            if cargo cache -a; then
                print_success "Cargo cache cleaned"
            else
                print_error "Cargo cache cleanup failed"
            fi
        else
            print_warning "cargo-cache not installed - skipping Cargo cleanup"
        fi
    fi

    # GHCup cleanup
    if command_exists ghcup; then
        print_info "Cleaning GHCup cache..."
        ghcup gc --cache 2>/dev/null && print_success "GHCup cache cleaned" || print_warning "GHCup cache cleanup had issues"
    fi

    # pnpm cleanup
    if command_exists pnpm; then
        print_info "Cleaning pnpm cache..."
        if pnpm store prune; then
            print_success "pnpm store pruned"
        else
            print_warning "pnpm store prune had issues"
        fi
    fi

    # pip cleanup
    if command_exists pip; then
        print_info "Cleaning pip cache..."
        if pip cache purge; then
            print_success "pip cache cleaned"
        else
            print_warning "pip cache cleanup had issues"
        fi
    fi
}

# Print summary
print_summary() {
    print_header "Maintenance Summary"
    echo -e "${GREEN}✓ Successful operations: $SUCCESS_COUNT${RESET}"
    echo -e "${YELLOW}⚠ Warnings: $WARNING_COUNT${RESET}"
    echo -e "${RED}✗ Errors: $ERROR_COUNT${RESET}"
    echo ""

    if [ $ERROR_COUNT -eq 0 ]; then
        print_success "Maintenance completed successfully!"
    else
        print_warning "Maintenance completed with some errors"
    fi
}

# Main execution
main() {
    print_header "System Maintenance Script"

    # Install missing package managers first
    install_missing_managers

    # Update packages
    update_system_packages
    update_flatpak
    update_rust
    update_haskell
    update_nodejs
    update_python
    update_ruby
    update_go
    update_php
    update_dotnet

    # Cleanup
    if ask_confirmation "Perform system cleanup?"; then
        cleanup_system
    else
        print_info "Skipping system cleanup"
    fi

    # Print summary
    print_summary
}

# Run main function
sudo echo "Force sudo checking at the start of the script" >/dev/null
main
