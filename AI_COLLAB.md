# AI Collaboration Guidelines

- All code comments in generated files must be **in English**.
- Keep backend (`/backend`) and frontend (`/frontend/kingraph-web`) strictly separated.
- Prefer **patches (unified diff)** for changes.
- When requesting changes, specify:
  1. Desired behavior (user story),
  2. Where to modify (file paths),
  3. Constraints (performance, security, style),
  4. Test/validation steps.
- Never include secrets in archives or messages.
- Keep responses concise; avoid refactoring unrelated code unless requested.
- Review policies and path filters are defined in `.coderabbit.yaml`, consult that configuration for precedence.
- Only modify files under paths explicitly listed in requests.
