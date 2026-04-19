# Workshop Template for Open Demo Platform

A streamlined template for creating workshops that deploy on the Open Demo Platform using Babylon orchestration.

**Based on RHPDS Patterns**:
- [field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template) - Deployment patterns
- [showroom_template_default](https://github.com/rhpds/showroom_template_default) - Lab guide content

---

## Quick Start (Clone, Customize, Deploy)

**Step 1: Clone This Template**
```bash
git clone https://github.com/open-demo-platform/workshop-template.git my-workshop
cd my-workshop
git remote set-url origin https://github.com/YOUR-ORG/my-workshop.git
```

**Step 2: Choose Deployment Pattern**

**Option A: Helm (for Kubernetes manifests)**
```bash
rm -rf deploy/ansible
cp -r deploy/helm/* deploy/
```

**Option B: Ansible (for complex deployments with wait-for-ready logic)**
```bash
rm -rf deploy/helm
cp -r deploy/ansible/* deploy/
```

**Step 3: Customize Content**
```bash
# Update workshop metadata
vim workshop.yaml

# Customize deployment
vim deploy/values.yaml  # (Helm) or deploy/playbook.yml (Ansible)

# Write lab guide content
vim content/showroom/content/modules/ROOT/pages/index.adoc
```

**Step 4: Test Locally**
```bash
./scripts/test-local.sh
```

**Step 5: Deploy to Babylon**
```bash
./scripts/deploy-to-babylon.sh
```

**Total Time**: < 1 hour from zero to deployed workshop

---

## Repository Structure

```
workshop-template/
├── README.md                           # This file
├── workshop.yaml                       # Babylon Workshop CR definition
│
├── deploy/                             # Deployment manifests
│   ├── helm/                           # Option 1: Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/                  # Kubernetes manifests
│   │   └── components/                 # Modular components
│   └── ansible/                        # Option 2: Ansible playbook
│       ├── playbook.yml
│       ├── tasks/
│       └── templates/
│
├── content/                            # Lab guide content
│   └── showroom/                       # Showroom (Antora/AsciiDoc)
│       ├── content/                    # Lab modules
│       │   └── modules/ROOT/
│       │       ├── nav.adoc            # Navigation sidebar
│       │       ├── pages/              # Lab pages
│       │       │   ├── index.adoc      # Overview
│       │       │   ├── module-01.adoc  # Lab 1
│       │       │   └── module-02.adoc  # Lab 2
│       │       ├── assets/images/      # Screenshots, diagrams
│       │       └── examples/           # Downloadable files
│       ├── antora.yml                  # Showroom config
│       └── default-site.yml            # Antora site config
│
├── scripts/                            # Automation scripts
│   ├── test-local.sh                   # Local testing
│   └── deploy-to-babylon.sh            # Deploy to platform
│
└── .github/                            # CI/CD automation
    └── workflows/
        └── deploy.yml                  # Auto-deploy on push

```

---

## What Gets Deployed

When a user provisions your workshop from the Babylon catalog:

```
┌─────────────────────────────────────────────────────────────┐
│ User clicks "Provision" in Babylon Catalog                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Babylon Workshop Manager creates WorkshopProvision CR       │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴──────────┐
         │                      │
         ▼                      ▼
┌────────────────────┐  ┌──────────────────────┐
│ Hub Cluster        │  │ Student Cluster(s)   │
│ (Showroom)         │  │ (Your workload)      │
│                    │  │                      │
│ - Lab guide        │  │ - Deployed via       │
│ - Terminal         │  │   ArgoCD (Helm) or   │
│ - Assets           │  │   AAP (Ansible)      │
└────────────────────┘  └──────────────────────┘
```

**Architecture**: Hub-Student Topology (from RHPDS pattern)
- **Hub cluster**: Runs Showroom (lab guide + terminal)
- **Student cluster(s)**: One per student or shared, runs your demo workload
- **Provisioning**: AAP + AgnosticD provision both clusters
- **Deployment**: ArgoCD deploys your content to student clusters

---

## Deployment Patterns

### Helm Pattern (deploy/helm/)

Use when deployment can be expressed as Kubernetes manifests with Helm templating.

```
Your Git Repo         Student Cluster
┌────────────┐       ┌─────────────────────┐
│ Helm Chart │─ArgoCD→│ Your Workload       │
│ (templates,│       │ (operators, apps)    │
│  values)   │       └─────────────────────┘
└────────────┘
```

**Example `values.yaml`**:
```yaml
components:
  operator:
    enabled: true
    name: my-operator
  
  helloWorld:
    enabled: true
    replicas: 1
    image: quay.io/my-org/hello-world:latest
  
  showroom:
    enabled: true
    content:
      repoUrl: https://github.com/my-org/my-workshop.git
```

### Ansible Pattern (deploy/ansible/)

Use when you need wait-for-ready, secret generation, API calls, or conditional logic.

ArgoCD creates a Kubernetes Job that runs your playbook via Ansible Runner.

**Example `playbook.yml`**:
```yaml
---
- name: Deploy workshop workload
  hosts: localhost
  tasks:
    - name: Create namespace
      kubernetes.core.k8s:
        name: "workshop-{{ namespace }}"
        kind: Namespace
        state: present
    
    - name: Wait for operator ready
      kubernetes.core.k8s_info:
        kind: Deployment
        name: my-operator
        namespace: "workshop-{{ namespace }}"
      register: operator
      until: operator.resources[0].status.readyReplicas == 1
      retries: 30
      delay: 10
```

---

## RHDP Integration Labels

Label your resources for Babylon integration:

```yaml
# Health monitoring — ArgoCD tracks application readiness
metadata:
  labels:
    demo.redhat.com/application: "my-workshop"

# Data passback — Babylon picks up URLs, credentials, etc.
metadata:
  labels:
    demo.redhat.com/userinfo: ""
```

**ConfigMap example for passing data back**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-workshop-info
  labels:
    demo.redhat.com/userinfo: ""
data:
  application_url: "https://my-app.apps.CLUSTER-DOMAIN"
  admin_username: "admin"
  admin_password: "generated-password"
```

---

## Writing Lab Guides (Showroom)

Showroom uses **Antora** with **AsciiDoc** for lab content.

**File: `content/showroom/content/modules/ROOT/pages/module-01.adoc`**
```asciidoc
= Lab 1: Deploy Your First Application

== Introduction

In this lab, you will deploy a simple application to OpenShift.

== Steps

. Login to OpenShift:
+
[source,bash]
----
oc login {openshift_api_url} -u {user} -p {password}
----

. Create a new project:
+
[source,bash]
----
oc new-project my-app
----

. Deploy the application:
+
[source,bash]
----
oc new-app https://github.com/sclorg/nodejs-ex.git
----

. Verify deployment:
+
[source,bash]
----
oc get pods
----

== Validation

You should see a pod running with name `nodejs-ex-*`.
```

**Variables** like `{openshift_api_url}` are populated by AgnosticD at deployment time from `agnosticd_user_info` data.

---

## Local Testing

**Test Showroom content**:
```bash
cd content/showroom
podman run --rm --name antora \
  -v $PWD:/antora:z \
  -p 8080:8080 -i -t \
  ghcr.io/juliaaano/antora-viewer
# Open http://localhost:8080
```

**Test Helm chart**:
```bash
cd deploy/helm
helm template my-workshop . --values values.yaml | oc apply --dry-run=client -f -
```

**Test Ansible playbook**:
```bash
cd deploy/ansible
ansible-playbook playbook.yml --check
```

---

## Deployment to Babylon

**Option 1: Manual Deployment**
```bash
./scripts/deploy-to-babylon.sh
```

**Option 2: Automatic via GitHub Actions**

Push to `main` branch triggers auto-deployment:
```bash
git add .
git commit -m "Update workshop content"
git push origin main
```

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically deploys to Babylon.

---

## Workshop Metadata (workshop.yaml)

Define your workshop for the Babylon catalog:

```yaml
apiVersion: babylon.gpte.redhat.com/v1
kind: Workshop
metadata:
  name: my-workshop
  namespace: babylon-workshops
  labels:
    category: containers
    difficulty: beginner
    duration: 2h
spec:
  displayName: "My Awesome Workshop"
  description: "Learn Kubernetes basics with hands-on labs"
  
  # How to provision this workshop
  provisioner:
    type: helm  # or: ansible, agnosticd
    source:
      git: https://github.com/my-org/my-workshop.git
      path: deploy/helm
      ref: main
  
  # What gets deployed
  resources:
    - type: namespace
      name: workshop-{{.user}}
    - type: deployment
      name: lab-environment
  
  # User access
  accessMethods:
    - type: route
      url: https://workshop-{{.user}}.apps.CLUSTER-DOMAIN
    - type: console
      url: https://console-openshift-console.apps.CLUSTER-DOMAIN
  
  # Workshop metadata
  tags:
    - kubernetes
    - containers
    - beginner
  estimatedDuration: 2h
  maxUsers: 50
```

---

## Development Resources

**RHPDS Development Skills** (AI assistance for workshop development):
- Clone: https://github.com/tosin2013/rhel-devops-skills-cli.git
- Provides AI skills for AgnosticD, Showroom, and field-sourced-content patterns
- Install: `./install.sh install --all`
- Use with Claude Code or Cursor IDE

**Upstream Templates**:
- [field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template)
- [showroom_template_default](https://github.com/rhpds/showroom_template_default)
- [agnosticd-v2](https://github.com/agnosticd/agnosticd-v2)

**Documentation**:
- [Open Demo Platform Docs](https://github.com/open-demo-platform/open-demo-platform)
- [Babylon Project](https://github.com/rhpds/babylon)
- [Showroom Deployer](https://github.com/rhpds/showroom-deployer)

---

## Example Workshops

See `examples/` directory for complete workshop examples:
- `kubernetes-101/` - Beginner Kubernetes workshop (Helm pattern)
- `advanced-observability/` - Advanced workshop (Ansible pattern)
- `multi-cloud-demo/` - Complex multi-cloud demo

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing workshops to the platform.

---

## License

See [LICENSE](LICENSE) for licensing details.
