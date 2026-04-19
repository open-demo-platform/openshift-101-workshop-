# Showroom Antora Attribute Substitution Investigation

**Date**: 2026-04-19  
**Category**: technical-validation  
**Status**: Blocked - Need External Research & Validation Tools  
**Severity**: Critical (blocks workshop usability)

## Research Question

**Why are AsciiDoc attributes (`{openshift_api_url}`, `{user}`, `{password}`) rendering as literal text in Showroom instead of being substituted with actual values from `user_data.yml`?**

## Background

### Problem Statement
After deploying the OpenShift 101 workshop to the odp-prod cluster, students see literal placeholders like `{openshift_api_url}` instead of actual values like `https://api.open-demo-platform.odp-prod.sandbox3047.opentlc.com:6443`.

This makes the workshop unusable - students cannot copy-paste commands that work.

### What We Know Works
1. **Merge script executes successfully** - Confirmed via init container logs:
   ```
   Updated user_data in content/antora.yml:
     openshift_cluster_domain: "apps.open-demo-platform.odp-prod.sandbox3047.opentlc.com"
     openshift_api_url: "https://api.apps.open-demo-platform.odp-prod.sandbox3047.opentlc.com:6443"
   ```

2. **Antora build completes without errors** - No warnings about missing attributes

3. **Content structure is correct** - Flattened to match reference pattern (`content/antora.yml` with `start_path: content`)

### What Doesn't Work
1. **Attributes don't substitute in rendered HTML** - Pages show `{openshift_api_url}` literally
2. **Local testing doesn't reproduce cluster behavior** - Cannot validate before deploying
3. **No clear documentation** on how Showroom/Antora attribute substitution actually works

## Methodology

### Approaches Attempted (Going in Circles)

1. **Tried different YAML formats** in `content/antora.yml`:
   - Quoted strings: `openshift_api_url: "https://..."`
   - Unquoted strings: `openshift_api_url: https://...`
   - Empty placeholders: `openshift_api_url: ""`
   - Result: No difference

2. **Tried restructuring directories**:
   - Original: `content/showroom/content/antora.yml`
   - Flattened: `content/antora.yml`  
   - Result: Merge works, substitution still fails

3. **Tried removing site.yml overrides**:
   - Removed `asciidoc.attributes` section from `site.yml`
   - Result: No change

4. **Tried local testing with CLI attributes**:
   ```bash
   antora --attribute openshift_api_url=https://test.com site.yml
   ```
   - Result: Cannot confirm if this works (container image differences)

5. **Web research**:
   - Found Antora docs on attribute precedence (CLI > playbook > component > page)
   - Found RHPDS showroom-deployer repo mentioning `user_data` parameter
   - Did NOT find actual implementation of merge script or how it works

## Key Findings

### Finding 1: Merge Script is a Black Box
- **Description**: The merge script that updates `content/antora.yml` is inside the `quay.io/rhpds/showroom-content:v1.3.1` container image
- **Evidence**: We see its output in logs but cannot inspect the code
- **Confidence**: High
- **Implication**: Cannot debug the merge logic or understand attribute handling

### Finding 2: Attribute Precedence May Be the Issue
- **Description**: Antora has attribute precedence rules (CLI > playbook > component descriptor > page header)
- **Evidence**: [Antora Docs - AsciiDoc Attributes](https://docs.antora.org/antora/latest/page/attributes/)
- **Confidence**: Medium
- **Implication**: If `site.yml` (playbook) defines attributes, they may override `content/antora.yml` (component descriptor)

### Finding 3: Local Testing is Insufficient  
- **Description**: The `ghcr.io/juliaaano/antora-viewer` image behaves differently than `quay.io/rhpds/showroom-content`
- **Evidence**: Local builds don't show merge script, use different Antora version
- **Confidence**: High
- **Implication**: Cannot validate fixes before deploying to cluster

### Finding 4: No Validation Tools Exist
- **Description**: There's no standalone tool to test Showroom attribute substitution
- **Evidence**: Searched RHPDS GitHub org, no testing utilities found
- **Confidence**: High
- **Implication**: Every fix requires full cluster deployment cycle (~5 minutes)

## Implications

### Architectural Impact
- **Workshop Template Pattern**: If attribute substitution doesn't work, the entire workshop-template pattern is broken for multi-environment deployments
- **User Experience**: Students get broken workshops with literal placeholders

### Technology Choices
- **Need for Validation Tools**: We should create a separate repository with:
  1. Local Showroom validation container
  2. Attribute substitution test suite
  3. Documentation of working patterns
  4. CI/CD pipeline to test before deployment

### Risk Assessment
- **High Risk**: Continuing without understanding the root cause
- **Medium Risk**: Creating workarounds that break in future Showroom versions
- **Low Risk**: Taking time to properly research and document the solution

## Recommendations

### Immediate Actions (Stop Going in Circles)

1. **Create a Validation Tools Repository**
   ```
   Repository: openshift-101-workshop-tools/
   ├── containers/
   │   └── showroom-validator/   # Custom container matching cluster behavior
   ├── tests/
   │   ├── test-attribute-substitution.sh
   │   ├── test-user-data-merge.sh
   │   └── fixtures/
   │       ├── sample-antora.yml
   │       └── sample-user-data.yml
   ├── docs/
   │   └── showroom-attribute-guide.md
   └── README.md
   ```

2. **Extract and Study the Merge Script**
   ```bash
   # Pull the actual showroom-content image
   podman pull quay.io/rhpds/showroom-content:v1.3.1
   
   # Find the merge script
   podman run --rm quay.io/rhpds/showroom-content:v1.3.1 find / -name "*merge*" -o -name "*user_data*"
   
   # Extract entrypoint script
   podman run --rm quay.io/rhpds/showroom-content:v1.3.1 cat /usr/local/bin/entrypoint.sh
   ```

3. **Research RHPDS Showroom Source Code**
   - Find the Containerfile/Dockerfile for `showroom-content`
   - Understand how it's supposed to work (not guess)
   - Document the correct pattern

4. **Test with Known Working Example**
   - Deploy a known working Showroom workshop (e.g., `showroom_template_nookbag`)
   - Compare its `content/antora.yml` structure with ours
   - Identify the difference

### Long-term Actions

1. **Contribute Back to RHPDS**
   - Document attribute substitution properly
   - Create PR to `showroom-deployer` with testing examples
   - Help future workshop creators

2. **Update Workshop Template**
   - Include validation tools
   - Add CI/CD pipeline for testing
   - Document the correct pattern clearly

3. **Create ADR**
   - Document the decision on how to handle attributes
   - Explain why we chose the solution we did
   - Reference this research

## Related ADRs

- None yet (this is Phase 7 of initial workshop creation)
- **Should create**: ADR for attribute substitution pattern

## Next Steps

- [ ] **STOP debugging blindly**
- [ ] Extract merge script from `quay.io/rhpds/showroom-content:v1.3.1`
- [ ] Study how it actually works (code > guessing)
- [ ] Deploy a known working Showroom example and compare
- [ ] Create validation tools repository
- [ ] Document the correct pattern
- [ ] Fix our workshop with confidence
- [ ] Create ADR documenting the decision

## References

### Documentation Found
- [Antora - AsciiDoc Attributes](https://docs.antora.org/antora/latest/page/attributes/)
- [Antora - Assign Attributes to Component](https://docs.antora.org/antora/latest/component-attributes/)
- [Antora - Assign Attributes to Site](https://docs.antora.org/antora/latest/playbook/asciidoc-attributes/)
- [RHPDS Showroom Deployer](https://github.com/rhpds/showroom-deployer)

### Repositories Referenced
- [showroom_template_nookbag](https://github.com/rhpds/showroom_template_nookbag) - Reference template
- [showroom-lb1136-rhel-10-hol](https://github.com/rhpds/showroom-lb1136-rhel-10-hol) - Working example

### Need to Find
- Containerfile for `quay.io/rhpds/showroom-content`
- Merge script source code
- Working examples with complex attribute substitution

## User Feedback

> "we should do external research because we may need to create a tools repo to validate things like this it feels like we are going in circles"

**Assessment**: User is 100% correct. We've been trying random fixes without understanding the root cause. Need structured research and validation tools.
