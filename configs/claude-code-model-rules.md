# Model Selection Rules

## Effort Mapping (task → model + effort)

- **effort=low** (Sonnet): File renames, simple greps, build commands, single-file trivial changes
- **effort=medium** (Sonnet): General coding, small refactors, writing tests, bug fixes with clear root cause
- **effort=high** (Sonnet): Multi-file refactors, complex debugging, cross-module changes
- **effort=xhigh** (Opus — needs approval): Long autonomous agentic sessions, multi-hour coding sessions
- **effort=max** (Opus — needs approval): Architecture decisions, subtle bugs, security reviews

## Opus Approval Process
Before switching to Opus, explain: (1) why Sonnet is insufficient, (2) the estimated cost difference, (3) wait for user confirmation.

## Plan → Execute Pattern
For hard tasks: Opus xHigh/Max for the plan (with approval), then execute each phase with Sonnet at appropriate effort level.
