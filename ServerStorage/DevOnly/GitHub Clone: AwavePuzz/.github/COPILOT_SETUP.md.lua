-- @ScriptType: Script
# Copilot Instructions Setup

This document describes the GitHub Copilot instructions configured for the AwavePuzz project.

## What Was Configured

GitHub Copilot instructions help the AI assistant understand your project's structure, coding standards, and best practices. This setup provides context-aware guidance when writing code for this Roblox multiplayer game.

## Files Created

### Main Instructions
- **`.github/copilot-instructions.md`** - Primary instructions covering:
  - Project overview (Roblox zombie survival game)
  - Technology stack (Lua/Luau, Roblox platform)
  - Core game systems (multiplayer, waves, cure-crafting, alliances)
  - Project structure and folder organization
  - Coding standards and conventions
  - Security considerations for multiplayer games
  - Common patterns and examples

### Context-Specific Instructions
Located in `.github/instructions/`, these provide targeted guidance:

1. **`server-side.md`** - For `src/server/**/*.lua`
   - Server authority principles
   - Manager pattern implementations
   - Remote event validation
   - Zombie AI guidelines
   - Security best practices

2. **`client-side.md`** - For `src/client/**/*.lua`
   - Client responsibilities and limitations
   - UI patterns and examples
   - Remote event usage from client side
   - Visual feedback practices
   - What clients should/shouldn't do

3. **`shared-code.md`** - For `src/shared/**/*.lua`
   - Configuration management patterns
   - Data structure definitions
   - Pure utility functions
   - Immutability guidelines

## How It Works

When you use GitHub Copilot in this repository:

1. **Global Context**: The main `copilot-instructions.md` provides overall project understanding
2. **File-Specific Context**: When editing files matching the `applyTo` patterns, the relevant instruction file provides additional context
3. **Better Suggestions**: Copilot generates code that:
   - Follows established patterns
   - Uses proper security practices (server authority)
   - Matches the existing code style
   - Respects multiplayer considerations

## Key Principles Enforced

### Server Authority
- All game logic runs on the server
- Client inputs are always validated
- No trusting client-side calculations

### Modular Design
- Manager classes for each system
- Clear separation of concerns
- Self-contained scripts

### Modern Lua Practices
- `task.wait()` instead of `wait()`
- Attributes for simple data
- Descriptive naming conventions

### Security First
- Input validation
- Rate limiting
- Anti-exploit measures
- Server-side raycasting

## Testing the Setup

To verify the instructions are working:

1. Open a Lua file in `src/server/`
2. Start typing a function or comment
3. Copilot suggestions should follow the server-side patterns
4. Try the same in `src/client/` and notice different guidance

## Maintaining the Instructions

When the project evolves:

- Update `copilot-instructions.md` for general changes
- Update specific instruction files for pattern changes
- Keep code examples current
- Document new systems and patterns

## Benefits

With these instructions, GitHub Copilot can:

✅ Generate server-authoritative code for multiplayer safety
✅ Follow established manager patterns
✅ Create proper RemoteEvent handlers with validation
✅ Suggest security-conscious implementations
✅ Match existing code style and conventions
✅ Understand Roblox-specific patterns and APIs
✅ Respect client-server boundaries

## References

- [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/tutorials/coding-agent)
- [Copilot Instructions Documentation](https://docs.github.com/en/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- Project Documentation: `Custom_instructions.md`, `GAME_DESIGN.md`, `API_DOCUMENTATION.md`

## Support

If you notice Copilot suggesting code that doesn't match project standards:
1. Check if the relevant instruction file covers that case
2. Update instructions to clarify the expected pattern
3. Provide examples of correct implementations

---

**Setup Date**: November 17, 2025
**Version**: 1.0.0
