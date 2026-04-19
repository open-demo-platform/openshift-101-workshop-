# OpenShift 101: Fundamentals Workshop

A hands-on workshop teaching Red Hat OpenShift Container Platform basics through practical exercises.

[![Validation Status](https://img.shields.io/badge/validation-passing-brightgreen)](VALIDATION.md)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.14+-red)](https://www.openshift.com/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

**Workshop URL**: https://showroom-{guid}.apps.{cluster-domain}/modules/index.html

> **Note**: Access the workshop content at `/modules/index.html` to go directly to the lab guide.

---

## Overview

**Duration**: 3-4 hours  
**Difficulty**: Beginner  
**Target Audience**: Developers with basic Kubernetes knowledge  
**Format**: Self-paced, hands-on labs with embedded terminal  

### What You'll Learn

This workshop teaches OpenShift fundamentals through four progressive modules:

1. **OpenShift Fundamentals** (45 min) - Console navigation, CLI basics, Projects
2. **Deploying Applications** (60 min) - Container images, Source-to-Image (S2I), Scaling
3. **Networking & Routes** (45 min) - Services, Routes, TLS configuration
4. **Configuration Management** (45 min) - ConfigMaps, Secrets, Volume mounts

By the end, you'll be able to:
- Navigate the OpenShift web console and CLI
- Deploy applications from container images and source code
- Expose applications with HTTP and HTTPS routes
- Manage application configuration securely

---

## Modules

### Module 1: OpenShift Fundamentals (45 min)

Learn the basics of OpenShift Container Platform:

- **Web Console**: Navigate the OpenShift dashboard and project views
- **CLI Basics**: Use `oc` commands for cluster management
- **Projects & Namespaces**: Create and manage isolated environments
- **RBAC**: Understand user permissions and access control

**Key Commands**: `oc login`, `oc whoami`, `oc new-project`, `oc get all`

---

### Module 2: Deploying Applications (60 min)

Deploy containerized applications using multiple methods:

- **Container Images**: Deploy pre-built images from registries
- **Source-to-Image (S2I)**: Build applications from source code
- **Scaling**: Horizontally scale deployments
- **Rolling Updates**: Update applications with zero downtime

**Applications Deployed**:
- `parksmap` - Interactive map application (from container image)
- `nodejs-ex` - Node.js example app (from GitHub via S2I)

**Key Commands**: `oc new-app`, `oc scale`, `oc rollout`, `oc logs`

---

### Module 3: Networking & Routes (45 min)

Expose applications to external traffic:

- **Services**: Internal load balancing with ClusterIP
- **HTTP Routes**: External access via HTTP
- **HTTPS Routes**: Secure access with TLS edge termination
- **Load Balancing**: Distribute traffic across pod replicas

**Key Concepts**: ClusterIP, NodePort, LoadBalancer, Route, Ingress

**Key Commands**: `oc expose`, `oc create route edge`, `oc get endpoints`

---

### Module 4: Configuration Management (45 min)

Manage application configuration separately from code:

- **ConfigMaps**: Store non-sensitive configuration data
- **Secrets**: Store sensitive information (passwords, tokens)
- **Environment Variables**: Inject configuration into pods
- **Volume Mounts**: Mount configuration as files

**Key Concepts**: 12-Factor App, Immutable Infrastructure, Secret Rotation

**Key Commands**: `oc create configmap`, `oc create secret`, `oc set env`

---

## Prerequisites

### Required Knowledge
- Basic Linux command line experience
- Familiarity with containers (Docker/Podman)
- Basic understanding of Kubernetes concepts (pods, deployments)

### Required Access
- OpenShift 4.14+ cluster with admin access
- OR use the provided demo cluster (see Workshop URL above)

### Tools (for local testing)
- `oc` CLI (OpenShift CLI)
- `helm` (for Helm deployment)
- `podman` or `docker` (for local Showroom preview)
- `git`

---

## Quick Start

### Option 1: Access a Deployed Workshop Instance

When the workshop is deployed to a cluster, access it at:

**https://showroom-{guid}.apps.{cluster-domain}/modules/index.html**

The `{guid}` is a unique identifier for your workshop instance, and `{cluster-domain}` is your OpenShift cluster's application domain (e.g., `apps.mycluster.example.com`).

---

### Option 2: Deploy to Your Own Cluster

#### Prerequisites
- OpenShift 4.14+ cluster
- Cluster admin access
- ArgoCD installed (OpenShift GitOps operator)
- Helm 3.x installed

#### Deploy via Helm

```bash
# Clone the repository
git clone https://github.com/open-demo-platform/openshift-101-workshop-.git
cd openshift-101-workshop-

# Set your cluster connection
export KUBECONFIG=/path/to/your/kubeconfig

# Install the workshop
helm install openshift-101 deploy/helm \
  --namespace openshift-101 \
  --create-namespace \
  --set deployer.domain="apps.YOUR-CLUSTER-DOMAIN" \
  --set deployer.apiUrl="https://api.YOUR-CLUSTER-DOMAIN:6443"

# Wait for deployment
oc get pods -n showroom -w

# Get the Showroom URL
oc get route showroom -n showroom -o jsonpath='{"https://"}{.spec.host}{"\n"}'
```

**Expected Deployment Time**: 2-3 minutes

#### Deploy via Babylon

If you're using the Babylon workshop platform:

```bash
./scripts/deploy-to-babylon.sh
```

This creates a `Workshop` Custom Resource in the `babylon-workshops` namespace.

---

## Testing Locally

### Preview Lab Content

Test the Showroom content before deploying to a cluster:

```bash
cd content/showroom
podman run --rm --name antora \
  -v $PWD:/antora:z \
  -p 8080:8080 -i -t \
  ghcr.io/juliaaano/antora-viewer
```

Open http://localhost:8080 in your browser.

**OR** use the convenience script:

```bash
./scripts/test-local.sh
```

### Validate Helm Chart

Generate manifests and validate syntax:

```bash
cd deploy/helm
helm template openshift-101 . --values values.yaml > /tmp/openshift-101-manifests.yaml

# Validate against cluster
oc apply --dry-run=client -f /tmp/openshift-101-manifests.yaml
```

---

## Repository Structure

```
openshift-101-workshop/
├── README.md                           # This file
├── VALIDATION.md                       # End-to-end test results
├── workshop.yaml                       # Babylon Workshop CR
├── site.yml                            # Antora playbook
├── ui-config.yml                       # Showroom UI config
│
├── deploy/helm/                        # Helm deployment
│   ├── Chart.yaml
│   ├── values.yaml                     # Workshop configuration
│   ├── templates/
│   │   └── applications.yaml           # ArgoCD Applications
│   └── components/                     # Modular components
│       ├── showroom/                   # Showroom lab guide
│       ├── hello-world/                # Demo application
│       └── operator/                   # Operator installation
│
├── content/showroom/                   # Lab guide content
│   ├── default-site.yml                # Local preview config
│   └── content/
│       ├── antora.yml                  # Antora configuration
│       └── modules/ROOT/
│           ├── nav.adoc                # Navigation menu
│           ├── pages/
│           │   ├── index.adoc          # Welcome page
│           │   ├── module-01.adoc      # OpenShift Fundamentals
│           │   ├── module-02.adoc      # Deploying Applications
│           │   ├── module-03.adoc      # Networking & Routes
│           │   ├── module-04.adoc      # Configuration Management
│           │   └── conclusion.adoc     # Next steps
│           ├── assets/images/          # Screenshots
│           └── supplemental-ui/        # Custom UI elements
│
└── scripts/
    ├── test-local.sh                   # Local testing
    └── deploy-to-babylon.sh            # Babylon deployment
```

---

## Configuration

### Helm Values

Key configuration options in `deploy/helm/values.yaml`:

```yaml
gitops:
  repoUrl: "https://github.com/open-demo-platform/openshift-101-workshop-.git"
  revision: "main"

components:
  showroom:
    enabled: true
    content:
      repoUrl: "https://github.com/open-demo-platform/openshift-101-workshop-.git"
      repoRef: "main"
  
  helloWorld:
    enabled: true
    namespace: parksmap-demo
    image: quay.io/openshiftroadshow/parksmap:latest

deployer:
  domain: "apps.YOUR-CLUSTER-DOMAIN"
  apiUrl: "https://api.YOUR-CLUSTER-DOMAIN:6443"
```

### Antora Variables

Lab content uses variables that are populated at build time:

- `{openshift_version}` - OpenShift version (e.g., "4.14")
- `{openshift_cluster_domain}` - Cluster apps domain
- `{openshift_api_url}` - API server URL
- `{openshift_console_url}` - Web console URL
- `{guid}` - Unique identifier for multi-user deployments

Edit `content/showroom/content/antora.yml` to customize these values.

---

## Troubleshooting

### Showroom Pod Not Starting

**Symptom**: Pod stuck in `Init:Error` or `CrashLoopBackOff`

**Solution**:
```bash
# Check init container logs
oc logs -n showroom deployment/showroom -c git-cloner
oc logs -n showroom deployment/showroom -c antora-builder

# Common issues:
# 1. Repository not accessible (check repoUrl)
# 2. site.yml not found (ensure it's in repo root)
# 3. Antora build errors (check antora.yml syntax)
```

### ArgoCD Application Not Syncing

**Symptom**: Applications stuck in `OutOfSync` status

**Solution**:
```bash
# Check ArgoCD application status
oc get applications -n openshift-gitops

# Grant ArgoCD permissions (if needed)
oc create rolebinding argocd-edit-showroom \
  --clusterrole=edit \
  --serviceaccount=openshift-gitops:openshift-gitops-argocd-application-controller \
  -n showroom
```

### Commands Fail in Workshop

**Symptom**: `oc` commands return permission errors

**Solution**: Ensure you're logged in with appropriate permissions
```bash
oc whoami
oc auth can-i create project
```

---

## Customization

### Adding a New Module

1. Create new module file:
```bash
cat > content/showroom/content/modules/ROOT/pages/module-05.adoc <<EOF
= Module 5: Persistent Storage

== Introduction
Learn about persistent volumes in OpenShift...
EOF
```

2. Update navigation:
```bash
vim content/showroom/content/modules/ROOT/nav.adoc
# Add: * xref:module-05.adoc[5. Persistent Storage]
```

3. Commit and push:
```bash
git add .
git commit -m "Add Module 5: Persistent Storage"
git push origin main
```

4. Restart Showroom deployment:
```bash
oc rollout restart deployment/showroom -n showroom
```

### Changing Workshop Duration

Update `workshop.yaml`:
```yaml
spec:
  estimatedDuration: 5h  # Change from 4h to 5h
  labels:
    duration: 5h
```

### Customizing Demo Application

Edit `deploy/helm/values.yaml`:
```yaml
components:
  helloWorld:
    enabled: true
    namespace: my-demo
    image: quay.io/my-org/my-app:latest
    replicas: 2
```

---

## Validation

This workshop has been end-to-end validated on OpenShift 4.21.9 (Kubernetes 1.34.5).

**Validation Report**: See [VALIDATION.md](VALIDATION.md)

**Test Results**:
- ✅ 39/39 tests passed
- ✅ All modules completable
- ✅ Average completion time: 3h 45min
- ✅ No critical issues

---

## Contributing

Contributions are welcome! To contribute:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes
4. Test locally with `./scripts/test-local.sh`
5. Commit your changes (`git commit -m "Add feature: X"`)
6. Push to your fork (`git push origin feature/my-improvement`)
7. Create a Pull Request

**Before submitting**:
- Ensure all modules still work end-to-end
- Update VALIDATION.md if adding new features
- Follow AsciiDoc syntax for lab content
- Test Helm chart deploys successfully

---

## Support

For issues or questions:

- **Issues**: https://github.com/open-demo-platform/openshift-101-workshop-/issues
- **Discussions**: https://github.com/open-demo-platform/openshift-101-workshop-/discussions

---

## Resources

### OpenShift Documentation
- [OpenShift 4.14 Documentation](https://docs.openshift.com/container-platform/4.14/)
- [OpenShift CLI Reference](https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html)

### Interactive Learning
- [OpenShift Interactive Learning Portal](https://learn.openshift.com/)
- [Red Hat Developer - OpenShift](https://developers.redhat.com/products/openshift/overview)

### Training & Certification
- [DO180: Introduction to Containers, Kubernetes, and OpenShift](https://www.redhat.com/en/services/training/do180-introduction-containers-kubernetes-red-hat-openshift)
- [EX180: Red Hat Certified Specialist in Containers](https://www.redhat.com/en/services/training/ex180-red-hat-certified-specialist-containers-exam)

---

## Credits

### Built On
- **Template**: [workshop-template](https://github.com/open-demo-platform/workshop-template)
- **Pattern**: [field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) (RHPDS)
- **Lab Guide**: [Showroom](https://github.com/rhpds/showroom-deployer)
- **Deployment**: [Babylon](https://github.com/rhpds/babylon)

### Sample Applications
- **parksmap**: [openshiftroadshow/parksmap](https://quay.io/repository/openshiftroadshow/parksmap)
- **nodejs-ex**: [sclorg/nodejs-ex](https://github.com/sclorg/nodejs-ex)

### Development Tools
- **AI Skills**: [rhel-devops-skills-cli](https://github.com/tosin2013/rhel-devops-skills-cli)
- **Antora**: [Antora Documentation Site Generator](https://antora.org/)

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

---

## Author

**Tosin Akinosho** (takinosh@redhat.com)

Created as a reference implementation for the Open Demo Platform workshop-template.

---

## Next Steps

After completing this workshop:

1. **OpenShift 201**: Operators, Persistent Storage, CI/CD Pipelines
2. **OpenShift 301**: Service Mesh, Serverless, GitOps, Multi-cluster
3. **Build Your Own**: Use this workshop as a template for creating custom workshops

**Happy Learning!** 🚀
