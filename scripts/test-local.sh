#!/bin/bash
# test-local.sh - Test workshop content locally

set -e

echo "==================================================================="
echo "Workshop Template - Local Testing"
echo "==================================================================="
echo ""

# Test 1: Showroom Content
echo "1. Testing Showroom content..."
if [ -d "content/showroom" ]; then
    echo "   ✓ Showroom content directory exists"

    # Check if podman is available
    if command -v podman &> /dev/null; then
        echo "   Starting Antora viewer..."
        echo "   Open http://localhost:8080 in your browser"
        echo "   Press Ctrl+C to stop"
        echo ""
        cd content/showroom
        podman run --rm --name antora \
          -v $PWD:/antora:z \
          -p 8080:8080 -i -t \
          ghcr.io/juliaaano/antora-viewer
        cd ../..
    else
        echo "   ⚠ Podman not found - skipping Showroom preview"
        echo "   Install podman to test lab guides locally"
    fi
else
    echo "   ✗ Showroom content directory not found"
    exit 1
fi

# Test 2: Helm Chart (if exists)
echo ""
echo "2. Testing Helm chart..."
if [ -d "deploy/helm" ] && [ -f "deploy/helm/Chart.yaml" ]; then
    echo "   ✓ Helm chart directory exists"

    # Check if helm is available
    if command -v helm &> /dev/null; then
        echo "   Running helm template..."
        helm template workshop-test deploy/helm --values deploy/helm/values.yaml > /tmp/workshop-helm-test.yaml
        echo "   ✓ Helm template successful"
        echo "   Output saved to: /tmp/workshop-helm-test.yaml"

        # Dry-run with oc if available
        if command -v oc &> /dev/null; then
            echo "   Running oc dry-run..."
            oc apply --dry-run=client -f /tmp/workshop-helm-test.yaml
            echo "   ✓ Kubernetes manifests valid"
        else
            echo "   ⚠ oc not found - skipping Kubernetes validation"
        fi
    else
        echo "   ⚠ Helm not found - skipping Helm chart test"
        echo "   Install helm to test charts locally"
    fi
elif [ -d "deploy/ansible" ]; then
    echo "   ⚠ Ansible deployment pattern detected (Helm chart not used)"
else
    echo "   ✗ No deployment pattern found (neither Helm nor Ansible)"
    exit 1
fi

# Test 3: Ansible Playbook (if exists)
echo ""
echo "3. Testing Ansible playbook..."
if [ -d "deploy/ansible" ] && [ -f "deploy/ansible/playbook.yml" ]; then
    echo "   ✓ Ansible playbook directory exists"

    # Check if ansible-playbook is available
    if command -v ansible-playbook &> /dev/null; then
        echo "   Running ansible-playbook syntax check..."
        ansible-playbook deploy/ansible/playbook.yml --syntax-check
        echo "   ✓ Ansible playbook syntax valid"
    else
        echo "   ⚠ ansible-playbook not found - skipping Ansible test"
        echo "   Install ansible to test playbooks locally"
    fi
elif [ -d "deploy/helm" ]; then
    echo "   ⚠ Helm deployment pattern detected (Ansible playbook not used)"
else
    echo "   ✗ No deployment pattern found (neither Helm nor Ansible)"
    exit 1
fi

echo ""
echo "==================================================================="
echo "✓ Local testing complete!"
echo "==================================================================="
echo ""
echo "Next steps:"
echo "  1. Review Showroom content at http://localhost:8080"
echo "  2. Check generated manifests in /tmp/workshop-helm-test.yaml"
echo "  3. Deploy to Babylon: ./scripts/deploy-to-babylon.sh"
echo ""
