# GitHub Copilot Configuration

This directory contains instructions for GitHub Copilot to better understand and assist with the AwavePuzz project.

## Files Overview

### Main Instructions

- **`copilot-instructions.md`** - Primary instructions for GitHub Copilot covering project overview, architecture, coding standards, and best practices for this Roblox multiplayer game.

### Specific Instructions

Located in the `instructions/` subdirectory, these provide context-specific guidance:

- **`server-side.md`** - Instructions for server-side code (`src/server/**/*.lua`)
  - Server authority principles
  - Manager patterns
  - Remote event handling
  - Zombie AI guidelines
  - Security and validation practices

- **`client-side.md`** - Instructions for client-side code (`src/client/**/*.lua`)
  - Client responsibilities
  - UI patterns
  - Remote event usage
  - Visual feedback practices
  - What clients should and shouldn't do

- **`shared-code.md`** - Instructions for shared modules (`src/shared/**/*.lua`)
  - Configuration management
  - Data structure definitions
  - Utility function patterns
  - Immutability principles

## How Copilot Uses These Instructions

GitHub Copilot reads these files to:
1. Understand the project structure and architecture
2. Follow established coding patterns and conventions
3. Apply appropriate security and validation practices
4. Generate code that fits the existing codebase style
5. Provide context-aware suggestions based on the file being edited

## Updating Instructions

When making significant changes to the codebase or establishing new patterns:
1. Update the relevant instruction files
2. Keep instructions clear and concise
3. Include code examples where helpful
4. Reference related documentation

## Related Documentation

For more detailed information about the project, see:
- `Custom_instructions.md` - Detailed system and development instructions
- `GAME_DESIGN.md` - Game design document and mechanics
- `API_DOCUMENTATION.md` - API reference and system interactions
- `IMPLEMENTATION_SUMMARY.md` - Implementation details and progress
- `README.md` - Project overview and setup guide

## Best Practices

These instructions follow GitHub's best practices for Copilot coding agents:
- Clear, well-scoped guidance
- Context-specific instructions using `applyTo` frontmatter
- Security-first approach
- Server-authoritative design for multiplayer games
- Modular, maintainable code patterns

For more information on GitHub Copilot best practices, visit:
https://docs.github.com/en/copilot/tutorials/coding-agent
