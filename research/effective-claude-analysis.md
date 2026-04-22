# Effective .claude Analysis

Source: `/Users/mikhailkrasilnikov/Downloads/mac with effective .claude/agents/`

## Structure

The effective-claude collection organizes 150+ agents into 16 divisions:
academic, design, engineering, game-development, integrations, marketing,
paid-media, product, project-management, sales, spatial-computing, specialized,
strategy, support, testing.

Each agent follows a consistent frontmatter format:
- name, description, tools, color, emoji, vibe
- Role definition section with identity, personality, memory, experience
- Core capabilities as structured lists
- Decision framework for when to use the agent
- Success metrics with specific targets
- Mandatory process steps

## Key patterns to adapt

### Agent definition structure
- Frontmatter: name, description, tools, color (we omit emoji and vibe)
- Clear role statement in second person ("You are...")
- When-to-use and when-not-to-use sections
- Success criteria tied to observable outcomes
- Handoff format for inter-agent work

### Division-to-pack mapping
- design + marketing + some product -> content-creation pack
- engineering + testing + project-management -> software-development pack
- product (trend-researcher, feedback-synthesizer) + strategy -> research-and-strategy pack

### What makes it productive
- Agents are domain-specific, not generic
- Each agent knows its boundaries and when to defer
- Memory and experience sections build institutional knowledge
- Mandatory process sections prevent skipping steps

## What NOT to copy
- Emoji in agent definitions (conflicts with our charset rule)
- "vibe" field (not used in our convention)
- 150+ agents (we curate 7-15 per pack)
- Game-development, spatial-computing, sales, paid-media divisions (not relevant)
