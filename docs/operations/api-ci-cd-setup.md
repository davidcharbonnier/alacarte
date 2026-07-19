# GitVersion CI/CD Setup Guide


This document explains the GitVersion-powered CI/CD pipeline for the À la carte REST API.

## 🔧 Required GitHub Secrets

### **Docker Hub Secrets**

1. **Go to Docker Hub**:
   - Visit [Docker Hub Security Settings](https://hub.docker.com/settings/security)
   - Create a new Access Token with Read & Write permissions
   
2. **Add GitHub Secrets**:
   - Go to your GitHub repository → Settings → Secrets and variables → Actions
   - Add these secrets:

   | Secret Name | Value | Description |
   |-------------|-------|-------------|
   | `DOCKERHUB_USERNAME` | `davidcharbonnier` | Your Docker Hub username |
   | `DOCKERHUB_TOKEN` | `dckr_pat_...` | Your Docker Hub access token |

### **GitHub Token**
The `GITHUB_TOKEN` is automatically provided by GitHub Actions.

## 🏷️ How GitVersion Works

### **Version Calculation**
GitVersion analyzes your git history and commit messages to automatically calculate semantic versions:

```bash
# Starting from v0.0.0 (or no tags)
feat: add OAuth support     → v0.1.0
fix: rating validation bug  → v0.1.1  
feat: wine rating system    → v0.2.0
feat!: redesign API         → v1.0.0 (breaking change)
```

### **Branch-Based Versioning**
- **master**: Production releases (v1.2.3)
- **feat/**: Pre-releases with dev tag (v1.3.0-dev.1+5)
- **fix/**: Pre-releases with dev tag (v1.2.4-dev.2+3)

## 🚀 Workflow Triggers

### **Pre-release Flow (feat/fix branches)**

**Trigger**: Create/update PR from `feat/*` or `fix/*` branch to `master`

**Example**:
```bash
git checkout -b feat/oauth-improvements
git commit -m "feat: improve OAuth error handling"
git push origin feat/oauth-improvements
# Create PR → Triggers pre-release build
```

**What happens**:
1. ✅ GitVersion calculates pre-release version (e.g., `v0.2.0-dev.1+3`)
2. ✅ Builds Docker image for `linux/amd64` and `linux/arm64`
3. ✅ Pushes to Docker Hub:
   - `davidcharbonnier/alacarte-api:v0.2.0-dev.1+3`
   - `davidcharbonnier/alacarte-api:dev-latest`
4. ✅ Creates GitHub pre-release with Docker instructions
5. ✅ Comments on PR with quick test commands

### **Production Release Flow (master)**

**Trigger**: PR merged to `master` branch

**Example**:
```bash
# After PR with "feat: add wine support" is merged:
# → GitVersion detects feat: commit
# → Automatically creates v0.2.0 release
```

**What happens**:
1. ✅ GitVersion analyzes commits and calculates new version
2. ✅ **Automatically creates and pushes git tag** (v0.2.0)
3. ✅ Builds Docker image for multiple platforms
4. ✅ Pushes to Docker Hub:
   - `davidcharbonnier/alacarte-api:v0.2.0`
   - `davidcharbonnier/alacarte-api:latest`
5. ✅ Creates GitHub release with auto-generated changelog
6. ✅ **No manual steps required!**

## 📋 Conventional Commits

GitVersion uses conventional commits to determine version bumps:

| Commit Pattern | Version Bump | Example |
|----------------|-------------|---------|
| `feat: ...` | Minor (0.1.0 → 0.2.0) | `feat: add wine rating support` |
| `fix: ...` | Patch (0.1.0 → 0.1.1) | `fix: oauth token validation error` |
| `feat!: ...` or `BREAKING CHANGE:` | Major (0.1.0 → 1.0.0) | `feat!: redesign rating API` |
| `perf: ...` | Patch (0.1.0 → 0.1.1) | `perf: optimize database queries` |
| `chore:`, `docs:`, `style:`, `test:` | No release | `chore: update dependencies` |

### **Advanced Patterns**
```bash
# Manual version control (override GitVersion)
git commit -m "feat: new feature +semver:major"  # Forces major bump
git commit -m "fix: bug fix +semver:none"        # Skips version bump
git commit -m "docs: update README +semver:skip" # Skips version bump
```

## 🎯 Branch Naming Strategy

Use these prefixes to trigger the correct workflow:

- `feat/description` → Triggers pre-release builds (minor version)
- `fix/description` → Triggers pre-release builds (patch version)  
- `chore/description` → Only tests build (no release)
- `docs/description` → Only tests build (no release)

## 🐳 Docker Image Tags

### **Production Images**
```bash
# Latest stable release
docker pull davidcharbonnier/alacarte-api:latest

# Specific version
docker pull davidcharbonnier/alacarte-api:v0.2.0
```

### **Development Images**
```bash
# Latest development build
docker pull davidcharbonnier/alacarte-api:dev-latest

# Specific pre-release (GitVersion format)
docker pull davidcharbonnier/alacarte-api:v0.2.0-dev.1+3
```

## 🔄 Version Examples

### **Starting from v0.1.0**
```bash
# Current state: v0.1.0 released on master

# Create feature branch
git checkout -b feat/wine-support
git commit -m "feat: add wine rating endpoints"
git commit -m "feat: add wine model validation"
# PR created → GitVersion calculates v0.2.0-dev.1+2

# Merge to master → GitVersion creates v0.2.0 automatically
```

### **Multiple Commit Types**
```bash
git commit -m "feat: add user profiles"        # Would bump minor
git commit -m "fix: oauth token refresh"       # Would bump patch  
git commit -m "docs: update API documentation" # No version change

# Result: Minor bump wins → v0.1.0 → v0.2.0
```

## 🎉 First Time Setup

1. **Add GitHub Secrets** (Docker Hub credentials)

2. **Create initial tag** (optional - GitVersion will start from v0.1.0):
   ```bash
   git tag v0.0.0
   git push origin v0.0.0
   ```

3. **Create test PR**:
   ```bash
   git checkout -b feat/test-gitversion
   echo "# GitVersion test" >> test.md
   git add . && git commit -m "feat: test GitVersion pipeline"
   git push origin feat/test-gitversion
   ```

4. **Create PR to master** → Should trigger pre-release (v0.1.0-dev.1+1)

5. **Merge PR** → Should create v0.1.0 release automatically

## 🔍 Troubleshooting

### **No Release Created**
- Check commit messages use conventional format (`feat:`, `fix:`)
- Verify commits are on master branch after PR merge
- Look at GitVersion logs in GitHub Actions for version calculation

### **Pre-release Not Triggered**
- Branch must start with `feat/` or `fix/`
- PR must target `master` branch
- Check if paths are ignored (*.md, docs/*)

### **Version Not What You Expected**
GitVersion uses these rules:
- **Major**: `feat!:` or `BREAKING CHANGE:` in commit body
- **Minor**: `feat:` commits
- **Patch**: `fix:`, `perf:` commits
- **No bump**: `chore:`, `docs:`, `style:`, `test:`, `ci:`

### **Docker Build Fails**
- Verify Docker Hub credentials in GitHub Secrets
- Check Dockerfile builds locally: `docker build -t test .`
- Review build logs in GitHub Actions

## 📊 Monitoring

### **GitVersion Outputs**
Check GitHub Actions logs for GitVersion calculations:
```
📊 GitVersion Results:
  • SemVer: 0.2.0
  • FullSemVer: 0.2.0-dev.1+3
  • Major: 0
  • Minor: 2
  • Patch: 0
  • PreReleaseTag: dev.1
```

### **Release Tracking**
- **Production releases**: [GitHub Releases](https://github.com/yourusername/yourrepo/releases)
- **Pre-releases**: Tagged with "Pre-release" label
- **Docker images**: [Docker Hub Repository](https://hub.docker.com/r/davidcharbonnier/alacarte-api/tags)

## ✅ Benefits of GitVersion Approach

### **🚀 Fully Automated**
- **No manual tagging** required
- **No manual version numbers** in code
- **No release preparation** steps
- **Immediate releases** on merge

### **🎯 Smart Version Calculation**
- **Analyzes entire git history**
- **Respects semantic versioning**
- **Handles complex branching scenarios**
- **Supports manual version overrides**

### **🔄 Predictable Workflow**
```
feat: commit → PR → Pre-release → Merge → Production release
    ↓            ↓         ↓          ↓           ↓
  v0.2.0   v0.2.0-dev.1  Docker   v0.2.0    Docker + GitHub
                         image    release   release
```

Your CI/CD pipeline is now fully automated with GitVersion! 🚀
