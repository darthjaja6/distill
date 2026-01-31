#!/bin/bash
# Upload a single skill to dstl.dev
#
# Usage:
#   # Upload new skill (reads name from SKILL.md frontmatter)
#   upload-skill.sh --skill-dir ~/.claude/skills/my-skill --description "..."
#
#   # Update existing skill (slug auto-detected from registry.json)
#   upload-skill.sh --skill-dir ~/.claude/skills/my-skill
#
#   # Explicit slug override
#   upload-skill.sh --skill-dir ~/.claude/skills/my-skill --slug abc123

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${SKILLBASE_API_URL:-https://skillbase.work}"
CRED_FILE="$HOME/.skillbase/credentials"
REGISTRY_FILE="$HOME/.skillbase/registry.json"

# Parse arguments
SKILL_DIR=""
DESCRIPTION=""
SLUG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skill-dir)
            SKILL_DIR="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --slug)
            SLUG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate
if [ -z "$SKILL_DIR" ]; then
    echo "Usage: upload-skill.sh --skill-dir <dir> [--description <desc>] [--slug <slug>]"
    exit 1
fi

if [ ! -d "$SKILL_DIR" ]; then
    echo "Error: Skill directory not found: $SKILL_DIR"
    exit 1
fi

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    echo "Error: SKILL.md not found in $SKILL_DIR"
    exit 1
fi

# Step 1: Check authentication
echo "Checking authentication..."
AUTH_RESULT=$("$SCRIPT_DIR/check-auth.sh")
AUTHENTICATED=$(echo "$AUTH_RESULT" | grep -o '"authenticated": *[^,}]*' | cut -d':' -f2 | tr -d ' ')

if [ "$AUTHENTICATED" != "true" ]; then
    echo "Not authenticated. Starting authentication flow..."
    echo ""
    "$SCRIPT_DIR/auth.sh"

    AUTH_RESULT=$("$SCRIPT_DIR/check-auth.sh")
    AUTHENTICATED=$(echo "$AUTH_RESULT" | grep -o '"authenticated": *[^,}]*' | cut -d':' -f2 | tr -d ' ')

    if [ "$AUTHENTICATED" != "true" ]; then
        echo "Error: Authentication failed"
        exit 1
    fi
fi

echo "Authenticated."

# Step 2: Read credentials
ACCESS_TOKEN=$(grep -E "^access_token=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)

# Step 3: Build payload and upload using Python
echo "Preparing upload..."

export API_URL ACCESS_TOKEN SLUG DESCRIPTION REGISTRY_FILE
export SKILL_DIR_ABS="$(cd "$SKILL_DIR" && pwd)"

python3 << 'PYEOF'
import json
import os
import sys
import re
import urllib.request
import urllib.error
from datetime import datetime

api_url = os.environ.get('API_URL', 'https://dstl.dev')
access_token = os.environ.get('ACCESS_TOKEN', '')
slug = os.environ.get('SLUG', '')
description_cli = os.environ.get('DESCRIPTION', '')
registry_file = os.environ.get('REGISTRY_FILE', os.path.expanduser('~/.skillbase/registry.json'))
skill_dir = os.environ.get('SKILL_DIR_ABS', '')

# --- Helper functions ---

def parse_frontmatter(content):
    """Parse YAML frontmatter from SKILL.md, including multi-line lists."""
    result = {}
    match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return result
    fm = match.group(1)

    current_key = None
    current_list = None

    for line in fm.split('\n'):
        stripped = line.strip()
        if not stripped:
            continue

        # Check for list item under current key
        if current_key and (stripped.startswith('- ') or stripped.startswith('- ')):
            item = stripped[2:].strip()
            if current_list is None:
                current_list = []
            current_list.append(item)
            continue
        else:
            # Save accumulated list
            if current_key and current_list is not None:
                result[current_key] = current_list
                current_list = None
                current_key = None

        # Simple key: value
        m = re.match(r'^(\w[\w_]*)\s*:\s*(.*)$', stripped)
        if m:
            key = m.group(1)
            val = m.group(2).strip()
            if val == '' or val == '|':
                # Might be followed by list items or multiline
                current_key = key
                current_list = None if val != '' else None
            else:
                result[key] = val
                current_key = key  # In case list follows
                current_list = None

    # Final flush
    if current_key and current_list is not None:
        result[current_key] = current_list

    return result


def read_skill_dir(skill_dir):
    """Read a skill directory and return skill info."""
    skill_md_path = os.path.join(skill_dir, 'SKILL.md')
    with open(skill_md_path, 'r') as f:
        content = f.read()

    fm = parse_frontmatter(content)

    skill_name = fm.get('name', os.path.basename(os.path.abspath(skill_dir)))
    description = fm.get('description', '')
    if isinstance(description, list):
        description = ' '.join(description)

    depends_on = fm.get('depends_on', [])
    if isinstance(depends_on, str):
        depends_on = [d.strip() for d in depends_on.split(',') if d.strip()]

    # Read scripts
    scripts = {}
    scripts_dir = os.path.join(skill_dir, 'scripts')
    if os.path.isdir(scripts_dir):
        for filename in os.listdir(scripts_dir):
            filepath = os.path.join(scripts_dir, filename)
            if os.path.isfile(filepath):
                with open(filepath, 'r') as f:
                    scripts[filename] = f.read()

    return {
        'name': skill_name,
        'description': description,
        'content': content,
        'scripts': scripts if scripts else None,
        'depends_on': depends_on if depends_on else None,
        'path': os.path.abspath(skill_dir),
    }


def api_request(method, url, data=None):
    """Make an API request and return parsed JSON."""
    body = json.dumps(data).encode('utf-8') if data else None
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header('Content-Type', 'application/json')
    req.add_header('Authorization', f'Bearer {access_token}')

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8')), resp.status
    except urllib.error.HTTPError as e:
        resp_body = e.read().decode('utf-8')
        try:
            return json.loads(resp_body), e.code
        except json.JSONDecodeError:
            return {'error': resp_body}, e.code


def load_registry():
    """Load registry.json."""
    if not os.path.exists(registry_file):
        return {'skills': {}}
    try:
        with open(registry_file) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {'skills': {}}


def save_registry(registry):
    """Save registry.json."""
    os.makedirs(os.path.dirname(registry_file), exist_ok=True)
    with open(registry_file, 'w') as f:
        json.dump(registry, f, indent=2)


def migrate_manifests():
    """Migrate old per-slug manifests to registry.json on first run."""
    manifest_dir = os.path.expanduser('~/.skillbase/manifests')
    if not os.path.isdir(manifest_dir):
        return

    if os.path.exists(registry_file):
        return  # Already migrated

    registry = {'skills': {}}

    for fname in os.listdir(manifest_dir):
        if not fname.endswith('.json'):
            continue
        try:
            with open(os.path.join(manifest_dir, fname)) as f:
                manifest = json.load(f)

            manifest_slug = manifest.get('slug', fname.replace('.json', ''))
            skillset_id = manifest.get('skillset_id', '')

            for s in manifest.get('skills', []):
                skill_name = s.get('name', '')
                if skill_name:
                    registry['skills'][skill_name] = {
                        'slug': manifest_slug,
                        'skill_id': skillset_id,  # Best we have from old format
                        'path': s.get('path', ''),
                        'version': manifest.get('version', 1),
                        'uploaded_at': manifest.get('uploaded_at', datetime.now().isoformat()),
                    }
        except (json.JSONDecodeError, IOError):
            continue

    if registry['skills']:
        save_registry(registry)
        print(f"Migrated {len(registry['skills'])} skills from manifests to registry.json")

    # Clean up old manifests
    import shutil
    try:
        shutil.rmtree(manifest_dir)
        print(f"Removed old manifests directory")
    except IOError:
        pass


# --- Main logic ---

# Auto-migrate old manifests
migrate_manifests()

# Read skill
skill_info = read_skill_dir(skill_dir)
skill_name = skill_info['name']

# Load registry and check for existing slug
registry = load_registry()

if not slug and skill_name in registry.get('skills', {}):
    slug = registry['skills'][skill_name].get('slug', '')
    if slug:
        print(f"Found existing slug '{slug}' for '{skill_name}' in registry")

# Use CLI description if provided, otherwise from frontmatter
desc = description_cli or skill_info.get('description', '') or ''

# Build payload
payload = {
    'name': skill_name,
    'content': skill_info['content'],
}

if desc:
    payload['description'] = desc
if skill_info.get('scripts'):
    payload['scripts'] = skill_info['scripts']
if skill_info.get('depends_on'):
    payload['depends_on'] = skill_info['depends_on']
if slug:
    payload['slug'] = slug

action = "Updating" if slug else "Uploading"
print(f"{action} skill '{skill_name}'...")

url = f"{api_url}/api/skills/upload"
result, status = api_request('POST', url, payload)

if status >= 400:
    print(f"Error: {result.get('error', 'Unknown error')}")
    sys.exit(1)

result_slug = result.get('slug', slug)
skill_id = result.get('skill_id', '')
version = result.get('version', 1)

# Update registry
registry['skills'][skill_name] = {
    'slug': result_slug,
    'skill_id': skill_id,
    'path': skill_info['path'],
    'version': version,
    'uploaded_at': datetime.now().isoformat(),
}
save_registry(registry)

print("")
if slug:
    print("Skill updated successfully!")
    print(f"  Version: {version}")
else:
    print("Uploaded successfully!")
print("")
print(f"Configure access: {result.get('manage_url', '')}")
print(f"Registry updated: {registry_file}")
print("")
print("Your skill is private by default. Visit the link above to:")
print("  - Add specific people by email, or")
print("  - Make it publicly accessible")
print("")
print("Once shared, others can install with:")
print(f"  curl -sSL {api_url}/s/{result_slug}/install.sh | bash")
PYEOF
