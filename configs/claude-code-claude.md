# Claude Code — Global Configuration

You are configured for **coding tasks only**. Do not use Claude Code for non-coding or general assistant tasks.

## Model & Effort Selection

Match model and effort to task complexity:

| Task Type | Model | Effort |
|-----------|-------|--------|
| File renames, simple greps, build commands | Sonnet | low |
| General coding, small refactors, writing tests | Sonnet | medium |
| Multi-file refactors, complex debugging | Sonnet | high |
| Long autonomous agentic sessions | Opus | xhigh |
| Architecture decisions, subtle bugs, security reviews | Opus | max |

### Planning Pattern
- For hard problems: first plan with Opus (xHigh or Max), then execute with Sonnet at lower effort
- Planning phase: focus on architecture, trade-offs, and breaking work into steps
- Execution phase: carry out the plan efficiently

### Opus Approval Rule
- **Never use Opus without explicit approval** from the user
- When you think Opus is needed, explain why and wait for confirmation
- Default to Sonnet unless the task genuinely requires Opus-level reasoning

## Coding Standards
- Write clean, well-structured code
- Include appropriate tests
- Follow project conventions when working in existing repos
- Use type hints where applicable
- Keep functions focused and modular
