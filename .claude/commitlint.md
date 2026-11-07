# Commit Message Convention

This project uses **Conventional Commits** (`@commitlint/config-conventional`).

## Format

```
<type>(<scope>): <description>   <- header (max 72 chars)
                                  <- blank line
<body>                            <- body (max 120 chars per line)
                                  <- blank line
<footer>                          <- footer (max 120 chars per line)
```

## Allowed Types

| Type       | Purpose                                        |
|------------|------------------------------------------------|
| `feat`     | New feature                                    |
| `fix`      | Bug fix                                        |
| `docs`     | Documentation changes                          |
| `style`    | Formatting (no logic changes)                  |
| `refactor` | Refactoring (no new features, no fixes)        |
| `perf`     | Performance improvement                        |
| `test`     | Adding/changing tests                          |
| `build`    | Build system or dependency changes             |
| `ci`       | CI configuration changes                       |
| `chore`    | Other changes (not affecting src/test)         |
| `revert`   | Revert a previous commit                       |

## Length Rules (error level)

- **Header**: max **72** characters
- **Body**: max **120** characters per line
- **Footer**: max **120** characters per line

## Lint Exceptions

Commits starting with the following prefixes are ignored by commitlint:
- `chore(copier):` — Copier auto-generation
- `chore(deps):` — dependency updates
- `ci(pre-commit.ci):` — pre-commit.ci auto-commits
- `[CI merge]` — CI merges
