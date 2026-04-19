# Showroom Attribute Substitution Guide

**Last Updated**: 2026-04-19  
**Based on Research**: Antora Official Documentation + Testing

---

## Problem Statement

Workshop content uses Antora/AsciiDoc attributes like `{openshift_api_url}`, `{user}`, `{password}` that should be replaced with actual values during build. However, these sometimes render as literal text instead of being substituted.

**Broken Output**:
```bash
oc login {openshift_api_url} -u {user} -p {password}
```

**Expected Output**:
```bash
oc login https://api.example.com:6443 -u admin -p ""
```

---

## How Antora Attribute Substitution Works

### Precedence Order (Highest to Lowest)

1. **CLI** (`antora --attribute key=value`)
2. **Playbook** (`site.yml` → `asciidoc.attributes`)
3. **Component Descriptor** (`content/antora.yml` → `asciidoc.attributes`)
4. **Page Header** (in `.adoc` files)

### Hard Set vs Soft Set

**Hard Set** (default):
```yaml
asciidoc:
  attributes:
    my_attribute: "hard value"  # BLOCKS lower levels
```
- Cannot be overridden by component descriptor or page
- Default behavior

**Soft Set** (with `@` modifier):
```yaml
asciidoc:
  attributes:
    my_attribute: "soft value@"  # CAN be overridden
```
- Can be overridden by component descriptor or page
- Use when you want lower levels to customize

### Critical Discovery

**External attributes (CLI/API) don't get substitutions applied** - they must be "ready as-is"

This means:
- Values passed via CLI must be final (no nested attribute references)
- Values from `user_data.yml` merge must be complete
- Don't use `{other_attribute}` inside attribute values

---

## Showroom-Specific Workflow

### 1. User Data Merge (Init Container)

The `showroom-content` init container merges `user_data.yml` into `content/antora.yml`:

```bash
# Inside antora-builder init container:
# 1. Read /user_data/user_data.yml
# 2. Read content/antora.yml  
# 3. Merge user_data values into antora.yml attributes
# 4. Save updated content/antora.yml
```

**Example `user_data.yml`**:
```yaml
openshift_cluster_domain: apps.example.com
openshift_api_url: https://api.example.com:6443
user: admin
password: ""
guid: my-workshop
```

**Merged `content/antora.yml`**:
```yaml
asciidoc:
  attributes:
    openshift_cluster_domain: apps.example.com
    openshift_api_url: https://api.example.com:6443
    user: admin
    password: ""
    guid: my-workshop
```

### 2. Antora Build

```bash
antora --to-dir=/showroom/www site.yml
```

Antora reads:
1. `site.yml` (playbook) - site-level attributes
2. `content/antora.yml` (component descriptor) - component attributes
3. Processes all `.adoc` files
4. Substitutes `{attribute_name}` with values
5. Generates HTML

### 3. Attribute Resolution

When Antora sees `{openshift_api_url}` in content:

1. Check CLI attributes (highest precedence)
2. Check playbook attributes (`site.yml`)
3. Check component attributes (`content/antora.yml`) ← **This is where merged values are**
4. Check page header
5. If found, substitute; if not, render literally or as undefined

---

## Common Issues & Solutions

### Issue 1: Playbook Blocks Component Attributes

**Problem**: `site.yml` has hard-set attributes that override component descriptor

```yaml
# site.yml - DON'T DO THIS
asciidoc:
  attributes:
    openshift_api_url: ""  # Hard-set empty value BLOCKS component!
```

**Solution**: Remove conflicting attributes from `site.yml` or make them soft-set

```yaml
# site.yml - CORRECT
asciidoc:
  attributes:
    # Don't define attributes that vary per environment
    # Let component descriptor handle them
```

OR soft-set to allow override:

```yaml
# site.yml - ALTERNATIVE
asciidoc:
  attributes:
    openshift_api_url: "default-value@"  # @ makes it soft-set
```

### Issue 2: Wrong antora.yml Location

**Problem**: Merge script updates one file, Antora reads another

```
# Wrong structure:
content/
  showroom/
    content/
      antora.yml  ← Antora reads this
  antora.yml  ← Merge script updates this
```

**Solution**: Flatten structure so they're the same file

```
# Correct structure:
content/
  antora.yml  ← Both merge and Antora use this
  modules/
    ROOT/
      pages/
```

Update `site.yml`:
```yaml
content:
  sources:
  - url: .
    branches: HEAD
    start_path: content  # Points to content/ directly
```

### Issue 3: Missing Attributes in antora.yml

**Problem**: Component descriptor doesn't define required attributes

**Solution**: Define with default values in `content/antora.yml`

```yaml
asciidoc:
  attributes:
    # OpenShift cluster configuration (defaults - overridden by user_data.yml)
    openshift_version: 4.14
    openshift_cluster_domain: apps.example.com
    openshift_api_url: https://api.example.com:6443
    openshift_console_url: https://console-openshift-console.apps.example.com
    
    # User credentials
    user: admin
    password: ""
    
    # Workshop settings
    guid: workshop
```

### Issue 4: Attribute Not Used in Content

**Problem**: Attribute defined but never referenced

**Solution**: Use the attribute in your content!

```asciidoc
// content/modules/ROOT/pages/module-01.adoc

oc login {openshift_api_url} -u {user} -p {password}
```

---

## Testing Locally

### Quick Test

```bash
# Run validation script
./scripts/validate-showroom-attributes.sh
```

### Manual Testing

1. **Create test user_data.yml**:
   ```yaml
   openshift_cluster_domain: apps.test.example.com
   openshift_api_url: https://api.test.example.com:6443
   user: testuser
   password: testpass123
   guid: test-abc
   ```

2. **Merge into antora.yml** (simulate showroom):
   ```bash
   # Use yq to merge
   yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
     content/antora.yml test-user-data.yml > content/antora-merged.yml
   
   cp content/antora-merged.yml content/antora.yml
   ```

3. **Build with Antora**:
   ```bash
   npx antora --to-dir=./test-www site.yml
   ```

4. **Check output**:
   ```bash
   grep "{openshift_api_url}" test-www/modules/module-01.html
   # Should return NOTHING (attribute was substituted)
   
   grep "https://api.test.example.com:6443" test-www/modules/module-01.html
   # Should find the substituted value
   ```

---

## Best Practices

### 1. **Keep Playbook Minimal**

Only define site-wide settings in `site.yml`:
```yaml
asciidoc:
  attributes:
    experimental: ''
    page-pagination: ''
    # Don't define environment-specific attributes here!
```

### 2. **Define Defaults in Component Descriptor**

Put environment-specific attributes in `content/antora.yml`:
```yaml
asciidoc:
  attributes:
    openshift_cluster_domain: apps.example.com  # Default
    openshift_api_url: https://api.example.com:6443  # Default
```

### 3. **Use Meaningful Attribute Names**

```asciidoc
// Good
{openshift_cluster_domain}
{openshift_api_url}
{user}

// Avoid
{domain}  // Too generic
{url}     // Ambiguous
{u}       // Unclear
```

### 4. **Document Required Attributes**

In `content/antora.yml`, add comments:
```yaml
asciidoc:
  attributes:
    # OpenShift cluster configuration (populated by user_data.yml merge)
    openshift_version: "4.14"
    openshift_cluster_domain: "apps.example.com"
    
    # User credentials (populated by user_data.yml merge)
    user: "admin"
    password: ""
```

### 5. **Test Locally Before Deploying**

```bash
# Always run validation before pushing
./scripts/validate-showroom-attributes.sh --local-only

# Only deploy if local tests pass
oc apply -f deploy/
```

---

## Debugging Checklist

When attributes don't substitute:

- [ ] Check `site.yml` doesn't hard-set conflicting attributes
- [ ] Verify `content/antora.yml` defines the attribute with default value
- [ ] Confirm `start_path` in `site.yml` points to correct directory
- [ ] Ensure attribute is actually used in `.adoc` content with `{attribute_name}`
- [ ] Check merge script logs in `antora-builder` init container
- [ ] Validate Antora build logs for warnings
- [ ] Test locally with validation script

---

## References

### Antora Documentation
- [Assign Attributes to a Site](https://docs.antora.org/antora/latest/playbook/asciidoc-attributes/)
- [Assign Attributes to Component](https://docs.antora.org/antora/latest/component-attributes/)
- [Define and Modify Attributes](https://docs.antora.org/antora/latest/page/define-and-modify-attributes/)
- [AsciiDoc Attributes in Antora](https://docs.antora.org/antora/latest/page/attributes/)

### AsciiDoc Documentation
- [Attribute Entry Substitutions](https://docs.asciidoctor.org/asciidoc/latest/attributes/attribute-entry-substitutions/)
- [Reference Document Attributes](https://docs.asciidoctor.org/asciidoc/latest/attributes/reference-attributes/)

### RHPDS Resources
- [RHPDS Skills Marketplace](https://github.com/rhpds/rhdp-skills-marketplace)
- [Showroom Deployer](https://github.com/rhpds/showroom-deployer)
- [Showroom Template](https://github.com/rhpds/showroom_template_nookbag)

---

**Created**: 2026-04-19  
**Author**: Open Demo Platform Team  
**License**: Apache 2.0
