#!/bin/bash
set -euo pipefail

echo "🚀 Deploying Renovate to Kubernetes"

# Check if RENOVATE_TOKEN is set
if [[ -z "${RENOVATE_TOKEN:-}" ]]; then
    echo "❌ Error: Please set RENOVATE_TOKEN environment variable"
    echo "Example: export RENOVATE_TOKEN=your_github_token"
    exit 1
fi

# Apply namespace and configmap
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

# Create secret from environment variable
kubectl create secret generic renovate-secret \
  --from-literal=RENOVATE_TOKEN="${RENOVATE_TOKEN}" \
  --from-literal=RENOVATE_REPOSITORIES="BishTestDevopOrg/renovate-test-demo" \
  --from-literal=LOG_LEVEL="info" \
  --from-literal=GITHUB_USERNAME="20was" \
  -n renovate \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy the CronJob
kubectl apply -f k8s/cronjob.yaml

echo "✅ Deployment complete!"
echo "Check status with: kubectl get all -n renovate"
