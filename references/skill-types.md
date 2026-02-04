# Skill Types

When generating skills, recognize three distinct types:

## 1. SOP Orchestration Skill

**Purpose**: Controls workflow, coordinates multiple capability/tool skills

**Characteristics**:
- Defines the overall process/sequence
- Contains decision logic for which skills to invoke
- Handles data flow between steps
- Provides unified entry point for complex tasks

**Freedom Level**: Medium (workflow logic, some flexibility in execution)

**Naming**: Verb-noun describing the goal
- `/setup-fullstack-project`
- `/deploy-to-production`
- `/process-data-pipeline`

## 2. Capability Skill

**Purpose**: Executes a specific, focused operation via guidance

**Characteristics**:
- Does ONE thing well
- Can be used independently OR called by an SOP skill
- Reusable across different SOP workflows
- Has clear inputs and outputs
- Contains instructions, not executable code

**Freedom Level**: High (guidance-based, context-dependent decisions)

**Naming**: Action-focused
- `/analyze-sentiment`
- `/evaluate-risk`
- `/review-code-security`

## 3. Tool Skill

**Purpose**: Provides executable scripts for specific tasks

**Characteristics**:
- Contains actual runnable code (Python, Node, Bash, etc.)
- Parameterized for reuse with different inputs
- Standardized output format (JSON with status/data/error)
- Can be invoked by SOP skills or used standalone
- Includes fallback instructions if script unavailable

**Freedom Level**: Low (deterministic, exact sequence matters)

**Naming**: Action-object
- `/fetch-api-data`
- `/parse-csv-file`
- `/run-database-migration`

**Directory Structure**:
```
.claude/skills/<tool-name>/
├── SKILL.md
├── scripts/
│   └── <script>.py
└── requirements.txt (if needed)
```

## How They Work Together

```
/deploy-to-production (SOP Orchestration)
    │
    ├── Step 1: Invoke /run-test-suite [Tool]
    │   └── Runs: python scripts/run_tests.py --coverage
    │   └── Returns: JSON test results
    │
    ├── Step 2: Invoke /check-deployment-readiness [Capability]
    │   └── Claude reviews test results and checks criteria
    │   └── Output: go/no-go decision with reasoning
    │
    ├── Step 3: Invoke /build-docker-image [Tool]
    │   └── Runs: bash scripts/build.sh --tag latest
    │   └── Returns: JSON with image ID, size
    │
    └── Step 4: Verify and report [Capability]
        └── Claude confirms deployment and summarizes changes
```

## Type Summary

| Type | Contains | Execution | Freedom |
|------|----------|-----------|---------|
| SOP Orchestration | Workflow logic | Claude follows steps | Medium |
| Capability | Guidance/instructions | Claude performs task | High |
| Tool | Executable scripts | Run script, get output | Low |

## Choosing the Right Type

| Session Characteristic | Recommended Type |
|------------------------|------------------|
| Multi-step workflow with clear phases | SOP + helpers |
| Reusable code was written | Tool Skill |
| Pure guidance/reasoning task | Capability Skill |
| Single focused operation | Capability or Tool |
| Complex multi-phase process | SOP Orchestration |
