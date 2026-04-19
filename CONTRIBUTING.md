# Contributing to Open Demo Platform Workshops

Thank you for your interest in contributing workshops to the Open Demo Platform!

---

## Quick Start for Workshop Development

**1. Clone this template**
```bash
git clone https://github.com/open-demo-platform/workshop-template.git my-workshop
cd my-workshop
```

**2. Install AI development skills** (optional but recommended)

We provide AI-powered development assistance via the [RHEL DevOps Skills CLI](https://github.com/tosin2013/rhel-devops-skills-cli):

```bash
# Clone the skills CLI
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli

# Install all RHPDS development skills
./install.sh install --all

# Skills available:
#  - agnosticd: AgnosticD v2 deployment patterns
#  - field-sourced-content: Helm/Ansible deployment templates
#  - showroom: Lab guide content authoring (Antora/AsciiDoc)
#  - workshop-tester: AI-as-student module testing
#  - student-readiness: Environment validation
#  - agnosticd-hub-student: Hub-student topology patterns
```

**Use with Claude Code or Cursor IDE** for context-aware assistance while developing workshops.

**3. Customize your workshop**
- Edit `workshop.yaml` for metadata
- Choose deployment pattern (Helm or Ansible)
- Write lab content in `content/showroom/`
- Test locally with `./scripts/test-local.sh`

**4. Submit your workshop**
- Create a pull request to this repository
- Include `workshop.yaml` and all content
- Provide testing instructions

---

## Workshop Development Guide

### Directory Structure

```
my-workshop/
├── workshop.yaml           # Workshop metadata (required)
├── deploy/                 # Deployment manifests (required)
│   ├── helm/              # Helm chart (choose one)
│   └── ansible/           # Ansible playbook (or this)
└── content/showroom/      # Lab guide (required)
```

### Workshop Metadata (workshop.yaml)

```yaml
apiVersion: babylon.gpte.redhat.com/v1
kind: Workshop
metadata:
  name: my-workshop-name
  labels:
    category: containers      # containers, cloud, automation, etc.
    difficulty: beginner      # beginner, intermediate, advanced
    duration: 2h              # 1h, 2h, 4h, 8h, 1d
spec:
  displayName: "My Workshop Title"
  description: "Brief description for catalog"
  
  provisioner:
    type: helm  # or ansible
    source:
      git: https://github.com/YOUR-ORG/my-workshop.git
      path: deploy/helm
      ref: main
  
  tags:
    - kubernetes
    - openshift
  estimatedDuration: 2h
  maxUsers: 50
```

### Deployment Patterns

#### Helm Pattern (Simple)

Use when your workshop can be expressed as Kubernetes manifests.

**File**: `deploy/helm/values.yaml`
```yaml
components:
  myApp:
    enabled: true
    image: quay.io/my-org/my-app:latest
    replicas: 1
  
  showroom:
    enabled: true
    content:
      repoUrl: https://github.com/YOUR-ORG/my-workshop.git
```

#### Ansible Pattern (Complex)

Use when you need wait-for-ready logic, secret generation, or API calls.

**File**: `deploy/ansible/playbook.yml`
```yaml
- name: Deploy workshop
  hosts: localhost
  tasks:
    - name: Create namespace
      kubernetes.core.k8s:
        name: "{{ namespace }}"
        kind: Namespace
    
    - name: Deploy application
      kubernetes.core.k8s:
        definition: "{{ lookup('template', 'app-deployment.yml.j2') }}"
```

### Lab Content (Showroom)

Showroom uses **Antora** with **AsciiDoc** for lab guides.

**File**: `content/showroom/content/modules/ROOT/pages/index.adoc`
```asciidoc
= Welcome to My Workshop

== Overview

This workshop teaches you to...

== Prerequisites

* Basic Kubernetes knowledge
* OpenShift CLI installed

== Labs

* xref:module-01.adoc[Lab 1: Deploy Application]
* xref:module-02.adoc[Lab 2: Configure Networking]
```

**Use Variables**:
```asciidoc
. Login to OpenShift:
+
[source,bash]
----
oc login {openshift_api_url} -u {user} -p {password}
----
```

Variables like `{openshift_api_url}` are populated by AgnosticD at deployment time.

---

## Testing Your Workshop

### Local Testing

**Test Showroom content**:
```bash
./scripts/test-local.sh
# Opens http://localhost:8080
```

**Test Helm chart**:
```bash
cd deploy/helm
helm template my-workshop . --values values.yaml
```

**Test Ansible playbook**:
```bash
cd deploy/ansible
ansible-playbook playbook.yml --check
```

### Platform Testing

**Deploy to test environment**:
```bash
export KUBECONFIG=/path/to/your/kubeconfig
./scripts/deploy-to-babylon.sh
```

**Provision workshop**:
1. Login to Babylon catalog UI
2. Search for your workshop
3. Click "Provision"
4. Complete the workshop as a student would
5. Verify all labs work correctly

### AI-Assisted Testing

Use the **workshop-tester** skill from rhel-devops-skills-cli:

```bash
# Install skill
cd rhel-devops-skills-cli
./install.sh install --skill workshop-tester

# Run AI-as-student testing
# (from Claude Code or Cursor IDE)
# Ask: "Test my workshop modules as a student"
```

The AI will:
- Execute each lab step
- Classify failures (instruction fix, infrastructure fix, or rethink)
- Generate a test report

---

## RHPDS Development Patterns

### Hub-Student Topology

Workshops use the **hub-student** pattern from RHPDS:

```
┌─────────────────┐       ┌──────────────────┐
│ Hub Cluster     │       │ Student Cluster  │
│ (Showroom)      │──────→│ (Your Demo)      │
│ - Lab guide     │       │ - Deployed via   │
│ - Terminal      │       │   ArgoCD or AAP  │
└─────────────────┘       └──────────────────┘
```

- **Hub**: Runs Showroom (lab guide + terminal)
- **Student**: Runs your workshop workload (one per student or shared)
- **Provisioning**: AAP + AgnosticD provision both clusters
- **Deployment**: ArgoCD (Helm) or AAP (Ansible) deploys content

### RHDP Integration Labels

Label resources for Babylon integration:

```yaml
metadata:
  labels:
    demo.redhat.com/application: "my-workshop"   # Health monitoring
    demo.redhat.com/userinfo: ""                  # Data passback
```

**ConfigMap for data passback**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-workshop-userinfo
  labels:
    demo.redhat.com/userinfo: ""
data:
  application_url: "https://my-app.apps.CLUSTER-DOMAIN"
  admin_password: "generated-password"
```

This data appears in the RHDP catalog for students.

---

## AI Development Skills Reference

The [RHEL DevOps Skills CLI](https://github.com/tosin2013/rhel-devops-skills-cli) provides AI assistance for:

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **agnosticd** | AgnosticD v2 provisioning | Setting up infrastructure, configs, workloads |
| **field-sourced-content** | Helm/Ansible deployment patterns | Designing deploy/ directory structure |
| **showroom** | Lab guide authoring | Writing content/showroom/ AsciiDoc |
| **agnosticd-hub-student** | Hub-student topology | Multi-cluster workshop architecture |
| **workshop-tester** | AI-as-student testing | Validating lab instructions work |
| **student-readiness** | Environment validation | Pre-launch workshop checks |

**Installation**:
```bash
git clone https://github.com/tosin2013/rhel-devops-skills-cli.git
cd rhel-devops-skills-cli
./install.sh install --all
```

**Usage** (in Claude Code or Cursor IDE):
- Ask questions about AgnosticD configs
- Get help writing Helm charts or Ansible playbooks
- Debug Showroom content rendering
- Test workshop modules as a student would
- Validate environment readiness

---

## Contribution Checklist

Before submitting your workshop:

- [ ] `workshop.yaml` contains accurate metadata
- [ ] Deployment pattern (Helm or Ansible) is tested and working
- [ ] Showroom lab content renders correctly (test with Antora viewer)
- [ ] All AsciiDoc variables are populated from `agnosticd_user_info`
- [ ] RHDP integration labels added to resources
- [ ] Workshop tested end-to-end on platform
- [ ] README.md includes workshop description and prerequisites
- [ ] LICENSE file included
- [ ] No secrets or credentials committed

---

## Support and Resources

**Platform Documentation**:
- [Open Demo Platform Docs](https://github.com/open-demo-platform/open-demo-platform)
- [Babylon Project](https://github.com/rhpds/babylon)
- [AgnosticD v2](https://github.com/agnosticd/agnosticd-v2)

**RHPDS Templates**:
- [field-sourced-content-template](https://github.com/rhpds/field-sourced-content-template)
- [showroom_template_default](https://github.com/rhpds/showroom_template_default)

**AI Skills**:
- [RHEL DevOps Skills CLI](https://github.com/tosin2013/rhel-devops-skills-cli)

**Community**:
- GitHub Issues: https://github.com/open-demo-platform/open-demo-platform/issues
- Discussions: https://github.com/open-demo-platform/open-demo-platform/discussions

---

## License

By contributing, you agree that your contributions will be licensed under the same license as this project.
