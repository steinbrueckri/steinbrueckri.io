#!/usr/bin/env bash

# Gallery Image Synchronization Script
# Synchronizes images from the Hetzner Object Storage (S3) bucket to local
# gallery directories using rclone.
# Usage: ./get_gallery_images.sh [--dry-run] [--verbose] [--help] <ACCESS_KEY_ID> <SECRET_ACCESS_KEY>

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# Object storage configuration (Hetzner S3). Override via env if needed.
readonly S3_ENDPOINT="${S3_ENDPOINT:-https://fsn1.your-objectstorage.com}"
readonly S3_REGION="${S3_REGION:-fsn1}"
readonly S3_BUCKET="${S3_BUCKET:-steinbrueck-io-gallery}"
readonly RCLONE_REMOTE="${RCLONE_REMOTE:-hz}"

# Global variables
DRY_RUN=false
VERBOSE=false
SEARCH_PATH="content/gallery/**"
ACCESS_KEY_ID=""
SECRET_ACCESS_KEY=""

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
    $SCRIPT_NAME [OPTIONS] [SEARCH_PATH] <ACCESS_KEY_ID> <SECRET_ACCESS_KEY>

DESCRIPTION:
    Synchronizes images from the Hetzner Object Storage (S3) bucket to local
    gallery directories using rclone. By default each gallery is fetched from
    "<bucket>/<gallery title>" (the gallery directory name). A gallery can
    override this by setting a 'source_bucket: "bucket/path"' field in its
    index.md.

OPTIONS:
    --dry-run       Show what would be done without actually doing it
    --verbose       Enable verbose output
    --help          Show this help message

ARGUMENTS:
    SEARCH_PATH         Path pattern to search for gallery directories (default: content/gallery/**)
    ACCESS_KEY_ID       Hetzner S3 access key ID
    SECRET_ACCESS_KEY   Hetzner S3 secret access key

ENVIRONMENT:
    S3_ENDPOINT     Object storage endpoint (default: $S3_ENDPOINT)
    S3_REGION       Object storage region (default: $S3_REGION)
    RCLONE_REMOTE   Internal rclone remote name (default: $RCLONE_REMOTE)

EXAMPLES:
    $SCRIPT_NAME my_access_key my_secret_key
    $SCRIPT_NAME "content/gallery/**" my_access_key my_secret_key
    $SCRIPT_NAME --dry-run --verbose my_access_key my_secret_key

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
                if [[ -z "$ACCESS_KEY_ID" && -z "$SECRET_ACCESS_KEY" ]]; then
                    # First argument - could be search path or access key ID
                    if [[ "$1" == *"*"* ]]; then
                        # Contains wildcards, likely a search path
                        SEARCH_PATH="$1"
                    else
                        # No wildcards, treat as access key ID
                        ACCESS_KEY_ID="$1"
                    fi
                elif [[ -z "$ACCESS_KEY_ID" ]]; then
                    ACCESS_KEY_ID="$1"
                elif [[ -z "$SECRET_ACCESS_KEY" ]]; then
                    SECRET_ACCESS_KEY="$1"
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

    # Check if rclone is available
    if ! command -v rclone &> /dev/null; then
        log_error "rclone command not found. Please install rclone."
        log_info "Visit: https://rclone.org/install/"
        exit 1
    fi

    # Check if required arguments are provided
    if [[ -z "$ACCESS_KEY_ID" || -z "$SECRET_ACCESS_KEY" ]]; then
        log_error "Missing required arguments: ACCESS_KEY_ID and SECRET_ACCESS_KEY"
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

# Configure the rclone S3 remote from the provided credentials.
# rclone reads remote settings from RCLONE_CONFIG_<REMOTE>_<KEY> env vars,
# so no on-disk config file is needed.
configure_rclone() {
    log_info "Configuring object storage access (endpoint: $S3_ENDPOINT)..."

    local remote_upper
    remote_upper="${RCLONE_REMOTE^^}"

    export "RCLONE_CONFIG_${remote_upper}_TYPE=s3"
    export "RCLONE_CONFIG_${remote_upper}_PROVIDER=Other"
    export "RCLONE_CONFIG_${remote_upper}_ENDPOINT=${S3_ENDPOINT}"
    export "RCLONE_CONFIG_${remote_upper}_REGION=${S3_REGION}"
    export "RCLONE_CONFIG_${remote_upper}_ACCESS_KEY_ID=${ACCESS_KEY_ID}"
    export "RCLONE_CONFIG_${remote_upper}_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: configured rclone remote '$RCLONE_REMOTE' (access key: ${ACCESS_KEY_ID:0:6}...)"
    fi

    log_success "Object storage access configured"
}

# Extract the optional source_bucket override from an index.md file.
# Prints the "bucket/path" if set, nothing otherwise (the default is derived
# from the gallery directory name by the caller).
extract_source_bucket() {
    local index_file="$1"

    [[ -f "$index_file" ]] || return 0

    grep -E '^source_bucket\s*:' "$index_file" | cut -d '"' -f2 || true
}

# Synchronize images for a single gallery
sync_gallery_images() {
    local index_file="$1"
    local basepath
    local target_dir
    local gallery
    local source_path
    local source

    basepath=$(dirname "$index_file")
    target_dir="$basepath/img/"
    gallery=$(basename "$basepath")

    # Default: derive "<bucket>/<gallery title>" from the directory name.
    # Optional override: a source_bucket field in index.md.
    source_path=$(extract_source_bucket "$index_file")
    if [[ -z "$source_path" ]]; then
        source_path="${S3_BUCKET}/${gallery}"
    fi

    # source_path is a backend-agnostic "bucket/path"; prefix the rclone remote.
    source="${RCLONE_REMOTE}:${source_path}"

    log_info "Processing gallery: $gallery"
    log_verbose "  Index file: $index_file"
    log_verbose "  Base path: $basepath"
    log_verbose "  Target directory: $target_dir"
    log_verbose "  Source: $source"

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
        log_info "DRY RUN: Would sync $source to $target_dir"
        log_verbose "DRY RUN: Command would be: rclone sync --fast-list \"$source\" \"$target_dir\""
    else
        log_info "Synchronizing images..."
        if rclone sync --fast-list "$source" "$target_dir"; then
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
    configure_rclone
    main
fi
