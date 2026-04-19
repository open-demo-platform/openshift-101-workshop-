# Tools to Add to Workshop Template

**Date**: 2026-04-19  
**Purpose**: Track what validation tools/docs should be contributed back to workshop-template  
**Status**: Ready to integrate

---

## Files to Copy from openshift-101-workshop to workshop-template

### 1. Validation Script
**Source**: `openshift-101-workshop/scripts/validate-showroom-attributes.sh`  
**Destination**: `workshop-template/scripts/validate-showroom-attributes.sh`  
**Why**: Essential for testing attribute substitution before deployment

**Features**:
- Tests local Antora build with test values
- Tests with showroom-content container (matches cluster)
- Tests cluster deployment
- Validates HTML output for literal `{placeholders}` vs substituted values
- Supports `--local-only`, `--cluster-only`, `--verbose` flags

### 2. Attribute Substitution Guide
**Source**: `openshift-101-workshop/docs/ATTRIBUTE_SUBSTITUTION_GUIDE.md`  
**Destination**: `workshop-template/docs/ATTRIBUTE_SUBSTITUTION_GUIDE.md`  
**Why**: Documents how Antora attribute substitution actually works

**Content**:
- Antora attribute precedence (CLI > Playbook > Component > Page)
- Hard set vs soft set attributes
- Showroom-specific workflow (merge → build → substitute)
- Common issues and solutions
- Best practices
- Debugging checklist
- Testing instructions

### 3. Research Documentation
**Source**: `openshift-101-workshop/docs/research/showroom-antora-attribute-substitution-investigation.md`  
**Destination**: `workshop-template/docs/research/showroom-patterns.md` (generalized)  
**Why**: Captures lessons learned for future workshop creators

**Keep**:
- Problem statement
- Research methodology
- Key findings
- Recommendations for validation tools

**Remove/Generalize**:
- OpenShift 101 specific details
- Specific cluster URLs
- Going-in-circles narrative (keep lessons, remove frustration)

### 4. Completion Status Template
**Source**: `openshift-101-workshop/docs/completion-status.md`  
**Destination**: `workshop-template/docs/completion-checklist.md` (generalized)  
**Why**: Provides checklist for workshop creators

**Generalize for template**:
```markdown
# Workshop Completion Checklist

## Phase 1-6: Content & Infrastructure
- [ ] Repository cloned from template
- [ ] Workshop modules written
- [ ] Helm/Ansible deployment configured
- [ ] Deployed to test cluster
- [ ] Documentation complete

## Phase 7: Validation
- [ ] **Attribute substitution tested** (CRITICAL)
  ```bash
  ./scripts/validate-showroom-attributes.sh --local-only
  ```
- [ ] Variables render correctly in content
- [ ] Workshop completable end-to-end
- [ ] Documentation accurate
```

---

## Updates to Existing Template Files

### workshop-template/README.md

Add new section after "Quick Start":

```markdown
## Validating Your Workshop

### Testing Attribute Substitution

Before deploying to a cluster, test that Antora attributes substitute correctly:

\`\`\`bash
# Test locally (fast)
./scripts/validate-showroom-attributes.sh --local-only

# Test with showroom-content container (matches cluster)
./scripts/validate-showroom-attributes.sh

# Test deployed workshop
./scripts/validate-showroom-attributes.sh --cluster-only
\`\`\`

**Why this matters**: If attributes like `{openshift_api_url}` don't substitute, students will see literal placeholders instead of working commands.

**See**: [Attribute Substitution Guide](docs/ATTRIBUTE_SUBSTITUTION_GUIDE.md) for details.
```

### workshop-template/scripts/test-local.sh

Update to reference validation script:

```bash
# After Showroom content test
echo ""
echo "3. Testing attribute substitution..."
if [ -f scripts/validate-showroom-attributes.sh ]; then
    ./scripts/validate-showroom-attributes.sh --local-only
else
    echo "   ⚠ Validation script not found"
    echo "   Install from: scripts/validate-showroom-attributes.sh"
fi
```

### workshop-template/CONTRIBUTING.md

Add validation requirement:

```markdown
### Before Submitting Content

1. Write your workshop modules
2. **Test attribute substitution**:
   ```bash
   ./scripts/validate-showroom-attributes.sh --local-only
   ```
3. Fix any issues found
4. Test on cluster if possible
5. Submit PR
```

---

## Integration Steps

### Step 1: Copy Files (5 min)
```bash
cd /home/vpcuser/open-demo-platform

# Copy validation script
cp openshift-101-workshop/scripts/validate-showroom-attributes.sh \
   workshop-template/scripts/

# Copy guide
cp openshift-101-workshop/docs/ATTRIBUTE_SUBSTITUTION_GUIDE.md \
   workshop-template/docs/

# Create research directory
mkdir -p workshop-template/docs/research

# Copy generalized research (manual edit needed)
cp openshift-101-workshop/docs/research/showroom-antora-attribute-substitution-investigation.md \
   workshop-template/docs/research/showroom-patterns.md
```

### Step 2: Generalize Content (15 min)

Edit `workshop-template/docs/research/showroom-patterns.md`:
- Remove openshift-101 specific details
- Keep the research findings
- Focus on the pattern, not the specific case
- Add "Based on research during openshift-101-workshop creation"

### Step 3: Update Template README (10 min)

Add validation section to `workshop-template/README.md`

### Step 4: Update test-local.sh (5 min)

Integrate validation into local testing workflow

### Step 5: Test Template (15 min)

```bash
cd workshop-template
./scripts/test-local.sh

# Should now include attribute validation
```

### Step 6: Document in Template (5 min)

Update `workshop-template/CONTRIBUTING.md` to require validation testing

---

## Expected Benefits

### For Workshop Creators
- **Catch issues early** - find attribute problems before deployment
- **Faster iteration** - test locally instead of deploying to cluster
- **Better understanding** - learn how Showroom attribute substitution works
- **Consistent quality** - all workshops follow same validation pattern

### For Workshop Template
- **Complete reference** - fully validated tools included
- **Best practices** - documented patterns from real implementation
- **Reduced support** - self-service validation reduces questions
- **Community value** - contribute back findings to RHPDS

---

## Timeline

**Estimated Time**: 1 hour total
- Copy files: 5 min
- Generalize content: 15 min
- Update README: 10 min
- Update test script: 5 min
- Test template: 15 min
- Documentation: 10 min

**Priority**: HIGH (unblocks future workshop creators)

**Dependencies**: 
- OpenShift 101 validation script proven to work
- Attribute substitution guide accurate

---

## Validation Criteria

Template integration is complete when:

- [ ] Validation script works in template context
- [ ] Guide accurately describes Showroom patterns
- [ ] Template README references validation tools
- [ ] test-local.sh includes attribute validation
- [ ] CONTRIBUTING.md requires validation testing
- [ ] Can create a new workshop from template and validate attributes
- [ ] Documentation clear for new workshop creators

---

## Future Enhancements

### Potential Additions
1. **CI/CD Integration**: GitHub Actions workflow to run validation
2. **Pre-commit Hook**: Validate attributes before committing
3. **VS Code Extension**: Real-time attribute validation in editor
4. **Web UI**: Browser-based validation tool
5. **RHPDS Contribution**: `/showroom:validate-runtime` skill

### Community Contribution
- Share validation tools with RHPDS team
- Propose addition to rhdp-skills-marketplace
- Write blog post about attribute substitution patterns
- Create video walkthrough

---

**Next Action**: Test openshift-101 validation script, then integrate to template  
**Owner**: Open Demo Platform Team  
**Status**: Pending validation test results
