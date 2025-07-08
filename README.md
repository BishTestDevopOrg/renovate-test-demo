# 🏆 RENOVATE DEVOPS AUTOMATION - COMPLETE IMPLEMENTATION GUIDE

## Project Overview
**Objective**: Implement enterprise-grade Renovate automation for automated dependency updates
**Repository**: https://github.com/BishTestDevopOrg/renovate-test-demo
**Tech Stack**: Node.js, TypeScript, Express, Docker, Kubernetes, Renovate

---

## 🚀 Step-by-Step Implementation

### **Phase 1: Project Setup**

#### 1. Create GitHub Organization and Repository
```bash
# Create organization: BishTestDevopOrg
# Create repository: renovate-test-demo (public, with README, Node.js .gitignore, MIT license)
git clone https://github.com/BishTestDevopOrg/renovate-test-demo.git
cd renovate-test-demo
```

#### 2. Initialize Node.js Project
```bash
npm init -y
npm install express cors helmet dotenv
npm install -D typescript @types/node @types/express @types/cors ts-node nodemon
npx tsc --init
mkdir src
```

#### 3. Create Express Application
```bash
# Create src/index.ts
cat > src/index.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Renovate Node.js Demo API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📝 Health check: http://localhost:${PORT}/health`);
});
EOF
```

#### 4. Update Package.json Scripts
```json
"scripts": {
  "start": "node dist/index.js",
  "dev": "nodemon src/index.ts",
  "build": "tsc",
  "test": "echo \"Error: no test specified\" && exit 1"
}
```

#### 5. Test Application
```bash
npm run dev
# Output: 🚀 Server running on port 3000

# Test endpoints
curl http://localhost:3000/
# Output: {"message":"Renovate Node.js Demo API","version":"1.0.0","timestamp":"2025-07-08T..."}

curl http://localhost:3000/health
# Output: {"status":"healthy","uptime":74.32,"timestamp":"2025-07-08T..."}
```

#### 6. Create Renovate Configuration
```bash
cat > renovate.json << 'EOF'
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json"
}
EOF
```

#### 7. Commit Initial Code
```bash
git add .
git commit -m "feat: initial Node.js Express TypeScript application with Renovate"
git push origin main
```

---

### **Phase 2: Local Renovate Testing**

#### 8. Create GitHub Personal Access Token
```bash
# Go to https://github.com/settings/tokens
# Create token with 'repo' and 'workflow' scopes
# Copy token: ghp_xxxxxxxxxx
```

#### 9. Test Renovate with Docker
```bash
# Create environment file
cat > .env.renovate << 'EOF'
RENOVATE_TOKEN=your_github_token_here
RENOVATE_REPOSITORIES=BishTestDevopOrg/renovate-test-demo
LOG_LEVEL=info
GITHUB_USERNAME=20was
EOF

# Run Renovate locally
docker run --rm \
  --env-file .env.renovate \
  -v "$(pwd)":/tmp/renovate \
  renovate/renovate:latest \
  --platform=github \
  --autodiscover=false \
  BishTestDevopOrg/renovate-test-demo
```

**Expected Output:**
```
INFO: Repository started (repository=BishTestDevopOrg/renovate-test-demo)
INFO: Onboarding PR created (repository=BishTestDevopOrg/renovate-test-demo)
INFO: Repository finished (repository=BishTestDevopOrg/renovate-test-demo)
```

#### 10. Merge Onboarding PR
```bash
# Go to GitHub, merge the "Configure Renovate" PR
# This activates Renovate for the repository
```

#### 11. Test Dependency Update
```bash
# Add older dependency for testing
npm install --save-exact lodash@4.17.20

git add package.json package-lock.json
git commit -m "feat: add lodash dependency for Renovate testing"
git push origin main

# Run Renovate again
docker run --rm --env-file .env.renovate -v "$(pwd)":/tmp/renovate renovate/renovate:latest --platform=github --autodiscover=false BishTestDevopOrg/renovate-test-demo
```

**Expected Output:**
```
INFO: Branch created (repository=BishTestDevopOrg/renovate-test-demo, branch=renovate/lodash-4.x)
INFO: PR created (repository=BishTestDevopOrg/renovate-test-demo, branch=renovate/lodash-4.x)
```

---

### **Phase 3: Kubernetes Deployment**

#### 12. Create Kubernetes Manifests
```bash
mkdir k8s

# Create namespace
cat > k8s/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: renovate
  labels:
    name: renovate
    purpose: dependency-automation
EOF

# Create ConfigMap
cat > k8s/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: renovate-config
  namespace: renovate
  labels:
    app: renovate
data:
  config.json: |
    {
      "$schema": "https://docs.renovatebot.com/renovate-schema.json",
      "extends": ["config:base"],
      "timezone": "Australia/Sydney",
      "schedule": ["every weekday"],
      "packageRules": [
        {
          "matchUpdateTypes": ["minor", "patch"],
          "automerge": false
        }
      ],
      "prTitle": "chore(deps): {{depName}} {{#if isPinDigest}}{{{displayFrom}}} → {{{displayTo}}}{{else}}{{#if isMajor}}{{prettyNewMajor}}{{else}}{{#if isSingleVersion}}{{prettyNewVersion}}{{else}}{{#if newValue}}{{{newValue}}}{{else}}{{{newDigest}}}{{/if}}{{/if}}{{/if}}{{/if}}",
      "commitMessagePrefix": "chore(deps): ",
      "rebaseWhen": "conflicted",
      "platform": "github",
      "autodiscover": false
    }
EOF

# Create CronJob
cat > k8s/cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: renovate
  namespace: renovate
  labels:
    app: renovate
spec:
  schedule: "0 9 * * 1-5"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: renovate
        spec:
          restartPolicy: Never
          containers:
          - name: renovate
            image: renovate/renovate:41.21.0
            envFrom:
            - secretRef:
                name: renovate-secret
            env:
            - name: RENOVATE_CONFIG_FILE
              value: "/config/config.json"
            volumeMounts:
            - name: config-volume
              mountPath: /config
              readOnly: true
            resources:
              requests:
                memory: "512Mi"
                cpu: "250m"
              limits:
                memory: "1Gi"
                cpu: "500m"
          volumes:
          - name: config-volume
            configMap:
              name: renovate-config
EOF
```

#### 13. Create Deployment Script
```bash
cat > deploy.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "🚀 Deploying Renovate to Kubernetes"

if [[ -z "${RENOVATE_TOKEN:-}" ]]; then
    echo "❌ Error: Please set RENOVATE_TOKEN environment variable"
    echo "Example: export RENOVATE_TOKEN=your_github_token"
    exit 1
fi

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

kubectl create secret generic renovate-secret \
  --from-literal=RENOVATE_TOKEN="${RENOVATE_TOKEN}" \
  --from-literal=RENOVATE_REPOSITORIES="BishTestDevopOrg/renovate-test-demo" \
  --from-literal=LOG_LEVEL="info" \
  --from-literal=GITHUB_USERNAME="20was" \
  -n renovate \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/cronjob.yaml

echo "✅ Deployment complete!"
echo "Check status with: kubectl get all -n renovate"
EOF

chmod +x deploy.sh
```

#### 14. Deploy to Kubernetes
```bash
# Ensure Kubernetes is running
kubectl cluster-info
# Output: Kubernetes control plane is running at https://127.0.0.1:6443

# Set environment variable
export RENOVATE_TOKEN=your_github_token

# Deploy
./deploy.sh
```

**Expected Output:**
```
🚀 Deploying Renovate to Kubernetes
namespace/renovate created
configmap/renovate-config created
secret/renovate-secret created
cronjob.batch/renovate created
✅ Deployment complete!
```

#### 15. Verify Deployment
```bash
kubectl get all -n renovate
```

**Expected Output:**
```
NAME                     SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/renovate   0 9 * * 1-5   <none>     False     0        <none>          16s
```

#### 16. Test Manual Execution
```bash
# Create manual job
kubectl create job --from=cronjob/renovate renovate-test -n renovate

# Watch execution
kubectl get jobs -n renovate -w
```

**Expected Output:**
```
NAME            STATUS    COMPLETIONS   DURATION   AGE
renovate-test   Running   0/1           5s         5s
renovate-test   Complete   1/1           68s        68s
```

#### 17. Check Execution Logs
```bash
kubectl logs -l job-name=renovate-test -n renovate
```

**Expected Output:**
```
INFO: Repository started (repository=BishTestDevopOrg/renovate-test-demo)
INFO: Dependency extraction complete (repository=BishTestDevopOrg/renovate-test-demo)
INFO: PR created (repository=BishTestDevopOrg/renovate-test-demo)
INFO: Repository finished (repository=BishTestDevopOrg/renovate-test-demo)
```

#### 18. Clean Up and Finalize
```bash
# Clean up test job
kubectl delete job renovate-test -n renovate

# Update .gitignore for security
cat >> .gitignore << 'EOF'

# Renovate cache and temporary files
cache/
repos/
.env.renovate
**/*secret*.yaml
!**/*secret*.yaml.template
EOF

# Commit final setup
git add .
git commit -m "feat: add Kubernetes deployment for Renovate automation

- Kubernetes manifests for namespace, configmap, cronjob
- Deployment script with external secret management
- No secrets in Git (security best practice)
- Ready for AWS EKS migration"

git push origin main
```

---

## 📊 Project Structure
```
renovate-test-demo/
├── src/
│   └── index.ts              # Express TypeScript application
├── k8s/
│   ├── namespace.yaml        # Kubernetes namespace
│   ├── configmap.yaml        # Renovate configuration
│   └── cronjob.yaml          # Scheduled execution
├── deploy.sh                 # Deployment automation
├── package.json              # Node.js dependencies
├── renovate.json             # Renovate configuration
├── tsconfig.json             # TypeScript configuration
└── .gitignore                # Security exclusions
```