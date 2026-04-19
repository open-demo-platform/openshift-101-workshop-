#!/bin/bash
# deploy-to-babylon.sh - Deploy workshop to Babylon platform

set -e

echo "==================================================================="
echo "Workshop Template - Deploy to Babylon"
echo "==================================================================="
echo ""

# Configuration
WORKSHOP_NAME="workshop-template"
BABYLON_NAMESPACE="babylon-workshops"
KUBECONFIG="${KUBECONFIG:-/home/vpcuser/agnosticd-v2-output/odp-prod/openshift-cluster_odp-prod_kubeconfig}"

# Check prerequisites
echo "1. Checking prerequisites..."

if [ ! -f "$KUBECONFIG" ]; then
    echo "   ✗ Kubeconfig not found at: $KUBECONFIG"
    echo "   Set KUBECONFIG environment variable or update this script"
    exit 1
fi
echo "   ✓ Kubeconfig found"

if ! command -v oc &> /dev/null; then
    echo "   ✗ oc CLI not found"
    echo "   Install OpenShift CLI: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
    exit 1
fi
echo "   ✓ oc CLI available"

# Test cluster connection
echo ""
echo "2. Testing cluster connection..."
export KUBECONFIG
if ! oc whoami &> /dev/null; then
    echo "   ✗ Cannot connect to cluster"
    echo "   Check your kubeconfig and cluster access"
    exit 1
fi
CURRENT_USER=$(oc whoami)
echo "   ✓ Connected as: $CURRENT_USER"

# Create namespace if needed
echo ""
echo "3. Checking Babylon workshops namespace..."
if ! oc get namespace $BABYLON_NAMESPACE &> /dev/null; then
    echo "   Creating namespace: $BABYLON_NAMESPACE"
    oc create namespace $BABYLON_NAMESPACE
else
    echo "   ✓ Namespace exists: $BABYLON_NAMESPACE"
fi

# Deploy Workshop CR
echo ""
echo "4. Deploying Workshop CR..."
if [ ! -f "workshop.yaml" ]; then
    echo "   ✗ workshop.yaml not found"
    echo "   Run this script from the workshop-template root directory"
    exit 1
fi

oc apply -f workshop.yaml -n $BABYLON_NAMESPACE
echo "   ✓ Workshop CR applied"

# Verify deployment
echo ""
echo "5. Verifying deployment..."
sleep 2
if oc get workshop $WORKSHOP_NAME -n $BABYLON_NAMESPACE &> /dev/null; then
    echo "   ✓ Workshop CR created successfully"
    echo ""
    echo "Workshop details:"
    oc get workshop $WORKSHOP_NAME -n $BABYLON_NAMESPACE -o yaml | grep -A 5 "spec:"
else
    echo "   ✗ Workshop CR not found"
    exit 1
fi

echo ""
echo "==================================================================="
echo "✓ Workshop deployed to Babylon!"
echo "==================================================================="
echo ""
echo "Next steps:"
echo "  1. View workshop in catalog:"
echo "     oc get workshop -n $BABYLON_NAMESPACE"
echo ""
echo "  2. Check Babylon catalog UI:"
echo "     CATALOG_URL=\$(oc get route babylon-catalog -n babylon-catalog -o jsonpath='{.spec.host}')"
echo "     echo \"https://\$CATALOG_URL\""
echo ""
echo "  3. Provision your workshop from the catalog UI"
echo ""
