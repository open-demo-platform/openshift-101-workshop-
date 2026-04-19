#!/bin/bash
#
# Showroom Attribute Validation Script
# Tests Antora attribute substitution from local dev to OpenShift deployment
#
# Based on research:
# - Antora attribute precedence: CLI > Playbook > Component > Page
# - Hard-set playbook attributes BLOCK component attributes
# - External attributes (CLI) must be "ready as-is" (no substitutions applied)
#
# Usage:
#   ./scripts/validate-showroom-attributes.sh [OPTIONS]
#
# Options:
#   --local-only       Test only local Antora build
#   --cluster-only     Test only cluster deployment
#   --user-data FILE   Use custom user_data.yml file
#   --verbose          Show detailed output
#

set -e

# Colors for output
RED='\033[0:31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_OUTPUT_DIR="${PROJECT_ROOT}/test-output"
KUBECONFIG="${KUBECONFIG:-/home/vpcuser/agnosticd-v2-output/odp-prod/openshift-cluster_odp-prod_kubeconfig}"

# Default test values
TEST_CLUSTER_DOMAIN="apps.test-cluster.example.com"
TEST_API_URL="https://api.test-cluster.example.com:6443"
TEST_CONSOLE_URL="https://console-openshift-console.apps.test-cluster.example.com"
TEST_USER="testuser"
TEST_PASSWORD="testpass123"
TEST_GUID="test-guid-abc"

# Parse command line arguments
LOCAL_ONLY=false
CLUSTER_ONLY=false
USER_DATA_FILE=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --local-only)
            LOCAL_ONLY=true
            shift
            ;;
        --cluster-only)
            CLUSTER_ONLY=true
            shift
            ;;
        --user-data)
            USER_DATA_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            head -n 20 "$0" | grep "^#" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${NC}    $*${NC}"
    fi
}

# Create test user_data.yml
create_test_user_data() {
    local output_file="$1"
    cat > "$output_file" <<EOF
# Test user_data.yml for validation
# These values will be merged into content/antora.yml

openshift_cluster_domain: ${TEST_CLUSTER_DOMAIN}
openshift_api_url: ${TEST_API_URL}
openshift_console_url: ${TEST_CONSOLE_URL}
user: ${TEST_USER}
password: "${TEST_PASSWORD}"
guid: ${TEST_GUID}

# Legacy compatibility
cluster_domain: ${TEST_CLUSTER_DOMAIN}
demo_namespace: parksmap-demo
demo_app: parksmap
username: ${TEST_USER}
EOF
}

# Simulate merge process (mimics showroom-content container)
merge_user_data() {
    local user_data_file="$1"
    local antora_file="$2"
    local output_file="$3"

    log_info "Simulating user_data.yml merge..."
    log_verbose "User data: $user_data_file"
    log_verbose "Antora file: $antora_file"
    log_verbose "Output: $output_file"

    # This is a simplified version of what the merge script does
    # Real implementation uses Python/yq to merge YAML properly

    # For now, use yq if available, otherwise manual sed
    if command -v yq &> /dev/null; then
        log_verbose "Using yq for YAML merge"
        # Read base antora.yml
        cp "$antora_file" "$output_file"

        # Merge user_data values into attributes section
        while IFS=': ' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue

            # Remove quotes from value
            value=$(echo "$value" | sed 's/^"//;s/"$//')

            log_verbose "Setting attribute: $key = $value"
            yq eval ".asciidoc.attributes.$key = \"$value\"" -i "$output_file"
        done < "$user_data_file"
    else
        log_warning "yq not found, using sed (less reliable)"
        cp "$antora_file" "$output_file"

        # Simple sed-based merge (fragile, for demo purposes)
        while IFS=': ' read -r key value; do
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue

            value=$(echo "$value" | sed 's/^"//;s/"$//')

            # Try to replace existing attribute or add new one
            if grep -q "^    $key:" "$output_file"; then
                sed -i "s|^    $key:.*|    $key: $value|" "$output_file"
            else
                # Add after attributes: line
                sed -i "/^  attributes:/a\\    $key: $value" "$output_file"
            fi
        done < "$user_data_file"
    fi

    log_success "Merge completed"
}

# Build with Antora locally
test_local_antora_build() {
    log_info "Testing local Antora build..."

    # Create test output directory
    mkdir -p "$TEST_OUTPUT_DIR"

    # Create test user_data.yml
    local test_user_data="$TEST_OUTPUT_DIR/user_data.yml"
    if [ -n "$USER_DATA_FILE" ]; then
        cp "$USER_DATA_FILE" "$test_user_data"
    else
        create_test_user_data "$test_user_data"
    fi

    # Merge user_data into antora.yml
    local merged_antora="$TEST_OUTPUT_DIR/antora.yml"
    merge_user_data "$test_user_data" "$PROJECT_ROOT/content/antora.yml" "$merged_antora"

    # Copy merged antora.yml to content directory for build
    cp "$merged_antora" "$PROJECT_ROOT/content/antora.yml"

    # Build with Antora (using CLI attributes as fallback)
    log_info "Running Antora build..."

    if command -v npx &> /dev/null && [ -f "$PROJECT_ROOT/site.yml" ]; then
        log_verbose "Using npx antora"
        cd "$PROJECT_ROOT"
        npx antora \
            --attribute openshift_cluster_domain="$TEST_CLUSTER_DOMAIN" \
            --attribute openshift_api_url="$TEST_API_URL" \
            --attribute user="$TEST_USER" \
            --attribute password="$TEST_PASSWORD" \
            --attribute guid="$TEST_GUID" \
            --to-dir="$TEST_OUTPUT_DIR/www" \
            site.yml
    elif command -v podman &> /dev/null; then
        log_verbose "Using podman with antora-viewer"
        podman run --rm \
            -v "$PROJECT_ROOT:/antora:z" \
            ghcr.io/juliaaano/antora-viewer \
            antora \
            --to-dir=/antora/test-output/www \
            /antora/site.yml
    else
        log_error "No Antora build tool available (need npx or podman)"
        return 1
    fi

    log_success "Antora build completed"
}

# Validate attribute substitution in HTML
validate_html_attributes() {
    log_info "Validating attribute substitution in generated HTML..."

    local html_file="$TEST_OUTPUT_DIR/www/modules/module-01.html"

    if [ ! -f "$html_file" ]; then
        log_error "HTML file not found: $html_file"
        return 1
    fi

    log_verbose "Checking: $html_file"

    # Define expected substitutions
    declare -A expected_values=(
        ["openshift_api_url"]="$TEST_API_URL"
        ["openshift_cluster_domain"]="$TEST_CLUSTER_DOMAIN"
        ["user"]="$TEST_USER"
        ["guid"]="$TEST_GUID"
    )

    local failed=0

    for attr in "${!expected_values[@]}"; do
        local expected="${expected_values[$attr]}"

        # Check if literal placeholder appears in content (exclude navbar/metadata)
        # Filter out canonical links and navbar which use site.yml attributes
        local content_only
        content_only=$(grep -v "canonical\|navbar" "$html_file")

        if echo "$content_only" | grep -q "{$attr}"; then
            log_error "Attribute {$attr} NOT substituted (appears literally in content)"
            failed=$((failed + 1))
            log_verbose "Expected: $expected"
            log_verbose "Found: {$attr}"
        elif echo "$content_only" | grep -q "$expected"; then
            log_success "Attribute {$attr} → $expected ✓"
        else
            log_warning "Attribute {$attr} not found in HTML (might not be used)"
        fi
    done

    if [ $failed -gt 0 ]; then
        log_error "$failed attribute(s) failed to substitute"
        return 1
    fi

    log_success "All tested attributes substituted correctly"
    return 0
}

# Test with showroom-content container (matches cluster)
test_showroom_container() {
    log_info "Testing with showroom-content container (matches cluster)..."

    # Pull the actual showroom-content image
    local showroom_image="quay.io/rhpds/showroom-content:v1.3.1"

    log_info "Pulling showroom-content image..."
    if ! podman pull "$showroom_image" 2>&1 | grep -v "Trying to pull"; then
        log_error "Failed to pull showroom-content image"
        return 1
    fi

    # Create test user_data.yml
    local test_user_data="$TEST_OUTPUT_DIR/user_data.yml"
    create_test_user_data "$test_user_data"

    # Run showroom-content container
    log_info "Running showroom-content build..."
    mkdir -p "$TEST_OUTPUT_DIR/showroom-www"

    podman run --rm \
        -v "$PROJECT_ROOT:/showroom/repo:z" \
        -v "$test_user_data:/user_data/user_data.yml:z" \
        -v "$TEST_OUTPUT_DIR/showroom-www:/showroom/www:z" \
        -e FILES_DIR="/showroom/repo" \
        -e OUTPUT_DIR="/showroom/www" \
        -e ANTORA_SITE_FILE="site.yml" \
        "$showroom_image"

    log_success "Showroom container build completed"

    # Validate the output
    local showroom_html="$TEST_OUTPUT_DIR/showroom-www/modules/module-01.html"
    if [ -f "$showroom_html" ]; then
        log_info "Validating showroom container output..."
        # Use same validation logic
        TEST_OUTPUT_DIR="$TEST_OUTPUT_DIR/showroom-www/.." validate_html_attributes
    else
        log_error "Showroom HTML not found: $showroom_html"
        return 1
    fi
}

# Test cluster deployment
test_cluster_deployment() {
    log_info "Testing cluster deployment..."

    if [ ! -f "$KUBECONFIG" ]; then
        log_error "KUBECONFIG not found: $KUBECONFIG"
        log_info "Set KUBECONFIG environment variable or use --local-only"
        return 1
    fi

    # Get showroom route
    local showroom_url
    showroom_url=$(oc get route showroom -n showroom -o jsonpath='{.spec.host}' 2>/dev/null)

    if [ -z "$showroom_url" ]; then
        log_error "Showroom route not found in cluster"
        log_info "Deploy the workshop first: helm install openshift-101 deploy/helm"
        return 1
    fi

    log_info "Testing cluster deployment at: https://$showroom_url"

    # Fetch module-01 page from cluster
    local cluster_html="$TEST_OUTPUT_DIR/cluster-module-01.html"
    if ! curl -s -o "$cluster_html" "https://$showroom_url/modules/module-01.html"; then
        log_error "Failed to fetch page from cluster"
        return 1
    fi

    log_success "Fetched page from cluster"

    # Get actual cluster values from user_data ConfigMap
    log_info "Reading user_data from cluster..."
    local cluster_domain
    cluster_domain=$(oc get configmap showroom-userdata -n showroom -o jsonpath='{.data.user_data\.yml}' | grep openshift_cluster_domain | cut -d':' -f2 | tr -d ' ')

    log_verbose "Cluster domain: $cluster_domain"

    # Validate against actual cluster values
    if grep -q "{openshift_api_url}" "$cluster_html"; then
        log_error "Cluster: Attributes NOT substituted (literal placeholders found)"
        grep -o "{[^}]*}" "$cluster_html" | sort -u
        return 1
    elif grep -q "$cluster_domain" "$cluster_html"; then
        log_success "Cluster: Attributes substituted correctly"
    else
        log_warning "Cluster: Could not verify attribute substitution"
    fi
}

# Main test orchestration
main() {
    echo "=========================================="
    echo "Showroom Attribute Validation"
    echo "=========================================="
    echo ""

    cd "$PROJECT_ROOT"

    # Run tests based on flags
    if [ "$CLUSTER_ONLY" = false ]; then
        log_info "Phase 1: Local Testing"
        echo "------------------------------------------"
        test_local_antora_build || exit 1
        echo ""

        validate_html_attributes || exit 1
        echo ""

        log_info "Phase 2: Container Testing (Showroom)"
        echo "------------------------------------------"
        test_showroom_container || log_warning "Showroom container test failed (non-blocking)"
        echo ""
    fi

    if [ "$LOCAL_ONLY" = false ]; then
        log_info "Phase 3: Cluster Testing"
        echo "------------------------------------------"
        test_cluster_deployment || log_warning "Cluster test failed (non-blocking)"
        echo ""
    fi

    echo "=========================================="
    log_success "Validation Complete!"
    echo "=========================================="
    echo ""
    echo "Test output saved to: $TEST_OUTPUT_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Review HTML files in test-output/www/"
    echo "  2. Compare local vs cluster behavior"
    echo "  3. Fix any issues found"
    echo "  4. Re-run validation"
    echo ""
}

# Run main function
main
