#!/usr/bin/env bash

# Gallery Image Synchronization Script
# Synchronizes images from B2 buckets to local gallery directories
# Usage: ./get_gallery_images.sh [--dry-run] [--verbose] [--help] <B2_APPLICATION_KEY_ID> <B2_APPLICATION_KEY>

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# Global variables
DRY_RUN=false
VERBOSE=false
SEARCH_PATH="content/gallery/**"
B2_APPLICATION_KEY_ID=""
B2_APPLICATION_KEY=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}${LOG_PREFIX} INFO:${NC} $*"
}

log_success() {
    echo -e "${GREEN}${LOG_PREFIX} SUCCESS:${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}${LOG_PREFIX} WARNING:${NC} $*"
}

log_error() {
    echo -e "${RED}${LOG_PREFIX} ERROR:${NC} $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}${LOG_PREFIX} DEBUG:${NC} $*"
    fi
}

# Help function
show_help() {
    cat << EOF
Gallery Image Synchronization Script

SYNOPSIS:
    $SCRIPT_NAME [OPTIONS] [SEARCH_PATH] <B2_APPLICATION_KEY_ID> <B2_APPLICATION_KEY>

DESCRIPTION:
    Synchronizes images from B2 buckets to local gallery directories.
    Reads source_bucket information from index.md files in gallery directories.

OPTIONS:
    --dry-run       Show what would be done without actually doing it
    --verbose       Enable verbose output
    --help          Show this help message

ARGUMENTS:
    SEARCH_PATH             Path pattern to search for gallery directories (default: content/gallery/**)
    B2_APPLICATION_KEY_ID   Your B2 application key ID
    B2_APPLICATION_KEY      Your B2 application key

EXAMPLES:
    $SCRIPT_NAME my_key_id my_secret_key
    $SCRIPT_NAME "content/gallery/**" my_key_id my_secret_key
    $SCRIPT_NAME --dry-run --verbose my_key_id my_secret_key

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # Check if this is the first non-option argument
                if [[ -z "$B2_APPLICATION_KEY_ID" && -z "$B2_APPLICATION_KEY" ]]; then
                    # First argument - could be search path or key ID
                    if [[ "$1" == *"*"* ]]; then
                        # Contains wildcards, likely a search path
                        SEARCH_PATH="$1"
                    else
                        # No wildcards, treat as key ID
                        B2_APPLICATION_KEY_ID="$1"
                    fi
                elif [[ -z "$B2_APPLICATION_KEY_ID" ]]; then
                    B2_APPLICATION_KEY_ID="$1"
                elif [[ -z "$B2_APPLICATION_KEY" ]]; then
                    B2_APPLICATION_KEY="$1"
                else
                    log_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if b2 command is available
    if ! command -v b2 &> /dev/null; then
        # Try common installation paths
        if [[ -f "$HOME/bin/b2" ]]; then
            export PATH="$HOME/bin:$PATH"
            log_info "Found b2 in $HOME/bin, added to PATH"
        elif [[ -f "/usr/local/bin/b2" ]]; then
            export PATH="/usr/local/bin:$PATH"
            log_info "Found b2 in /usr/local/bin, added to PATH"
        else
            log_error "b2 command not found. Please install the B2 CLI tool."
            log_info "Visit: https://www.backblaze.com/b2/docs/quick_command_line.html"
            exit 1
        fi
    fi
    
    # Check if required arguments are provided
    if [[ -z "$B2_APPLICATION_KEY_ID" || -z "$B2_APPLICATION_KEY" ]]; then
        log_error "Missing required arguments: B2_APPLICATION_KEY_ID and B2_APPLICATION_KEY"
        show_help
        exit 1
    fi
    
    # Check if search path exists
    local base_path
    base_path=$(echo "$SEARCH_PATH" | sed 's/\*.*$//')
    if [[ ! -d "$base_path" ]]; then
        log_error "Gallery directory '$base_path' not found"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Authenticate with B2
authenticate_b2() {
    log_info "Authenticating with B2..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would authenticate with B2 using key ID: ${B2_APPLICATION_KEY_ID:0:8}..."
        return 0
    fi
    
    if ! b2 authorize-account "$B2_APPLICATION_KEY_ID" "$B2_APPLICATION_KEY" &> /dev/null; then
        log_error "Failed to authenticate with B2"
        exit 1
    fi
    
    log_success "Successfully authenticated with B2"
}

# Extract source bucket from index.md file
extract_source_bucket() {
    local index_file="$1"
    
    if [[ ! -f "$index_file" ]]; then
        log_error "Index file not found: $index_file"
        return 1
    fi
    
    local source_bucket
    source_bucket=$(grep -E '^source_bucket\s*:' "$index_file" | cut -d '"' -f2 || true)
    
    if [[ -z "$source_bucket" ]]; then
        log_warning "No source_bucket found in $index_file"
        return 1
    fi
    
    echo "$source_bucket"
}

# Synchronize images for a single gallery
sync_gallery_images() {
    local index_file="$1"
    local basepath
    local target_dir
    local source_bucket
    
    basepath=$(dirname "$index_file")
    target_dir="$basepath/img/"
    if ! source_bucket=$(extract_source_bucket "$index_file"); then
        log_warning "Skipping gallery due to missing source_bucket: $(basename "$basepath")"
        return 1
    fi
    
    log_info "Processing gallery: $(basename "$basepath")"
    log_verbose "  Index file: $index_file"
    log_verbose "  Base path: $basepath"
    log_verbose "  Target directory: $target_dir"
    log_verbose "  Source bucket: $source_bucket"
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN: Would create directory: $target_dir"
        else
            mkdir -p "$target_dir"
            log_verbose "Created directory: $target_dir"
        fi
    fi
    
    # Perform synchronization
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would sync $source_bucket to $target_dir"
        log_verbose "DRY RUN: Command would be: b2 sync --delete --no-progress \"$source_bucket\" \"$target_dir\""
    else
        log_info "Synchronizing images..."
        if b2 sync --delete --no-progress "$source_bucket" "$target_dir" 2>/dev/null; then
            log_success "Successfully synchronized: $(basename "$basepath")"
        else
            log_error "Failed to synchronize: $(basename "$basepath")"
            return 1
        fi
    fi
    
    return 0
}

# Main execution function
main() {
    log_info "Starting gallery image synchronization..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE: No actual changes will be made"
    fi
    
    local processed_count=0
    local success_count=0
    local error_count=0
    
    # Find all index.md files in gallery directories
    local index_files
    local search_base
    search_base=$(echo "$SEARCH_PATH" | sed 's/\*.*$//')
    log_verbose "Search base path: $search_base"
    
    mapfile -t index_files < <(find "$search_base" -name 'index.md' -type f 2>/dev/null || true)
    
    if [[ ${#index_files[@]} -eq 0 ]]; then
        log_warning "No index.md files found in gallery directories"
        return 0
    fi
    
    log_info "Found ${#index_files[@]} gallery directories to process"
    
    # Process each gallery
    for index_file in "${index_files[@]}"; do
        processed_count=$((processed_count + 1))
        
        echo "---------------------------------------------------------"
        log_info "Processing gallery $processed_count of ${#index_files[@]}"
        log_verbose "Processing file: $index_file"
        
        set +e
        if sync_gallery_images "$index_file"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
        fi
        set -e
    done
    
    # Summary
    echo "========================================================="
    log_info "Synchronization complete!"
    log_info "Processed: $processed_count galleries"
    log_success "Successful: $success_count"
    
    if [[ $error_count -gt 0 ]]; then
        log_error "Failed: $error_count"
        exit 1
    else
        log_success "All galleries synchronized successfully!"
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    validate_prerequisites
    authenticate_b2
    main
fi