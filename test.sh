#!/bin/bash
# Asciify Skills — Test Suite
# Validates build output, installer, skill structure, and management commands.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
PASS=0
FAIL=0
ERRORS=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  PASS=$((PASS + 1))
  echo -e "  ${GREEN}PASS${NC} $1"
}

fail() {
  FAIL=$((FAIL + 1))
  ERRORS="${ERRORS}\n  - $1"
  echo -e "  ${RED}FAIL${NC} $1"
}

section() {
  echo ""
  echo -e "${YELLOW}=== $1 ===${NC}"
}

# ---- Build Script Tests ----

section "Build Script"

# Test: build-skills.sh exists and is executable
if [[ -f "${SCRIPT_DIR}/build-skills.sh" ]]; then
  pass "build-skills.sh exists"
else
  fail "build-skills.sh missing"
fi

# Test: build-skills.sh runs without error
if bash "${SCRIPT_DIR}/build-skills.sh" > /dev/null 2>&1; then
  pass "build-skills.sh runs successfully"
else
  fail "build-skills.sh failed to run"
fi

# Test: all expected skill files were generated
EXPECTED_SKILLS=(
  ai-principles.md
  ansible-principles.md
  docker-principles.md
  git-principles.md
  go-principles.md
  kubernetes-principles.md
  nodejs-principles.md
  python-principles.md
  rust-principles.md
  security-principles.md
  shell-principles.md
  terraform-principles.md
)

for skill in "${EXPECTED_SKILLS[@]}"; do
  if [[ -f "${SKILLS_DIR}/${skill}" ]]; then
    pass "Generated: ${skill}"
  else
    fail "Missing generated skill: ${skill}"
  fi
done

# Test: .version file was generated
if [[ -f "${SKILLS_DIR}/.version" ]]; then
  pass ".version file generated"
else
  fail ".version file missing"
fi

# ---- Skill Structure Tests ----

section "Skill File Structure"

for skill in "${EXPECTED_SKILLS[@]}"; do
  filepath="${SKILLS_DIR}/${skill}"
  [[ -f "${filepath}" ]] || continue

  # Test: has YAML frontmatter
  if head -1 "${filepath}" | grep -q "^---$"; then
    pass "${skill}: has YAML frontmatter"
  else
    fail "${skill}: missing YAML frontmatter"
  fi

  # Test: has name field
  if grep -q "^name:" "${filepath}"; then
    pass "${skill}: has name field"
  else
    fail "${skill}: missing name field"
  fi

  # Test: has description field
  if grep -q "^description:" "${filepath}"; then
    pass "${skill}: has description field"
  else
    fail "${skill}: missing description field"
  fi

  # Test: not empty (at least 100 bytes)
  size=$(wc -c < "${filepath}" | tr -d ' ')
  if [[ ${size} -gt 100 ]]; then
    pass "${skill}: has content (${size} bytes)"
  else
    fail "${skill}: too small (${size} bytes)"
  fi
done

# ---- Management Skill Tests ----

section "Management Skills"

MGMT_SKILLS=(
  asciify-skills-update.md
  asciify-skills-uninstall.md
  asciify-skills-help.md
)

for skill in "${MGMT_SKILLS[@]}"; do
  filepath="${SKILLS_DIR}/${skill}"

  if [[ -f "${filepath}" ]]; then
    pass "${skill}: exists"
  else
    fail "${skill}: missing"
    continue
  fi

  # Test: has correct name in frontmatter
  expected_name="asciify-skills:$(echo "${skill}" | sed 's/asciify-skills-//; s/\.md$//')"
  if grep -q "name: ${expected_name}" "${filepath}"; then
    pass "${skill}: correct name (${expected_name})"
  else
    fail "${skill}: wrong name (expected ${expected_name})"
  fi

  # Test: has description
  if grep -q "^description:" "${filepath}"; then
    pass "${skill}: has description"
  else
    fail "${skill}: missing description"
  fi
done

# ---- Installer Tests ----

section "Installer"

# Test: install.sh exists and is executable
if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
  pass "install.sh exists"
else
  fail "install.sh missing"
fi

if [[ -x "${SCRIPT_DIR}/install.sh" ]]; then
  pass "install.sh is executable"
else
  fail "install.sh is not executable"
fi

# Test: install.sh contains all expected skill files
for skill in "${EXPECTED_SKILLS[@]}"; do
  if grep -q "${skill}" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh includes ${skill}"
  else
    fail "install.sh missing ${skill}"
  fi
done

for skill in "${MGMT_SKILLS[@]}"; do
  if grep -q "${skill}" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh includes ${skill}"
  else
    fail "install.sh missing ${skill}"
  fi
done

# Test: install.sh references asciify-skills (agentic-principles only in legacy cleanup)
non_legacy_refs=$(grep -c "agentic-principles" "${SCRIPT_DIR}/install.sh" | tr -d ' ')
legacy_refs=$(grep -c "legacy.*agentic-principles\|agentic-principles.*legacy\|legacy_" "${SCRIPT_DIR}/install.sh" | tr -d ' ')
if [[ ${non_legacy_refs} -le ${legacy_refs} ]]; then
  pass "install.sh uses 'asciify-skills' naming (legacy cleanup refs OK)"
else
  fail "install.sh still references 'agentic-principles' outside legacy cleanup"
fi

# Test: local install to temp directory
section "Install Integration"

TEMP_DIR="$(mktemp -d)"
TEMP_PROJECT="${TEMP_DIR}/test-project"
mkdir -p "${TEMP_PROJECT}"
cd "${TEMP_PROJECT}" && git init --quiet

if bash "${SCRIPT_DIR}/install.sh" --local > /dev/null 2>&1; then
  pass "Local install completed"

  # Verify skill files were installed
  installed_count=0
  for skill in "${EXPECTED_SKILLS[@]}"; do
    if [[ -f ".claude/skills/asciify-skills/${skill}" ]]; then
      installed_count=$((installed_count + 1))
    fi
  done

  if [[ ${installed_count} -eq ${#EXPECTED_SKILLS[@]} ]]; then
    pass "All ${#EXPECTED_SKILLS[@]} skill files installed to skills/"
  else
    fail "Only ${installed_count}/${#EXPECTED_SKILLS[@]} skill files installed to skills/"
  fi

  # Verify command files were installed to commands directory
  cmd_count=0
  for cmd in update.md uninstall.md help.md; do
    if [[ -f ".claude/commands/asciify-skills/${cmd}" ]]; then
      cmd_count=$((cmd_count + 1))
    fi
  done

  if [[ ${cmd_count} -eq 3 ]]; then
    pass "All 3 command files installed to commands/"
  else
    fail "Only ${cmd_count}/3 command files installed to commands/"
  fi

  # Verify .version was installed
  if [[ -f ".claude/skills/asciify-skills/.version" ]]; then
    pass ".version installed"
  else
    fail ".version not installed"
  fi
else
  fail "Local install failed"
fi

# Test: uninstall
if bash "${SCRIPT_DIR}/install.sh" --uninstall > /dev/null 2>&1; then
  if [[ ! -d ".claude/skills/asciify-skills" ]]; then
    pass "Uninstall removed skills directory"
  else
    fail "Uninstall did not remove skills directory"
  fi
  if [[ ! -d ".claude/commands/asciify-skills" ]]; then
    pass "Uninstall removed commands directory"
  else
    fail "Uninstall did not remove commands directory"
  fi
else
  fail "Uninstall failed"
fi

# Cleanup
rm -rf "${TEMP_DIR}"
cd "${SCRIPT_DIR}"

# ---- Naming Consistency Tests ----

section "Naming Consistency"

# Test: no references to old name in key files
KEY_FILES=(
  install.sh
  build-skills.sh
  README.md
  CLAUDE.md
  CONTRIBUTING.md
  skills/README.md
)

for kf in "${KEY_FILES[@]}"; do
  filepath="${SCRIPT_DIR}/${kf}"
  [[ -f "${filepath}" ]] || continue

  # install.sh is allowed to reference agentic-principles for legacy cleanup
  if [[ "${kf}" == "install.sh" ]]; then
    if grep "agentic-principles" "${filepath}" | grep -qv "legacy"; then
      fail "${kf}: references 'agentic-principles' outside legacy cleanup"
    else
      pass "${kf}: uses 'asciify-skills' naming (legacy cleanup OK)"
    fi
  elif grep -q "agentic-principles" "${filepath}"; then
    fail "${kf}: still references 'agentic-principles'"
  else
    pass "${kf}: uses 'asciify-skills' naming"
  fi
done

# Test: management skills reference correct repo URL
for skill in "${MGMT_SKILLS[@]}"; do
  filepath="${SKILLS_DIR}/${skill}"
  [[ -f "${filepath}" ]] || continue

  if grep -q "asciifylabs/asciify-skills" "${filepath}"; then
    pass "${skill}: correct repo URL"
  else
    # Not all management skills need repo URLs
    if grep -q "github" "${filepath}"; then
      fail "${skill}: wrong repo URL"
    else
      pass "${skill}: no repo URL needed"
    fi
  fi
done

# ---- Legacy File Cleanup Tests ----

section "Legacy Cleanup"

LEGACY_FILES=(
  install-skills.sh
  update-check.sh
)

for lf in "${LEGACY_FILES[@]}"; do
  if [[ -f "${SCRIPT_DIR}/${lf}" ]]; then
    fail "Legacy file still exists: ${lf}"
  else
    pass "Legacy file removed: ${lf}"
  fi
done

# ---- Summary ----

echo ""
echo "================================"
total=$((PASS + FAIL))
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC} (${total} total)"

if [[ ${FAIL} -gt 0 ]]; then
  echo -e "\nFailures:${ERRORS}"
  echo ""
  exit 1
else
  echo -e "\n${GREEN}All tests passed.${NC}"
  echo ""
  exit 0
fi
