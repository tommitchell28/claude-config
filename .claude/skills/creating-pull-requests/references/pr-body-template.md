# PR Body Template

The PR body MUST follow this structure, in this order:

```markdown
## Linked issue

<closing keyword line(s) — `Closes #N`, `Refs #N`, cross-repo, or `None`>

## Summary

- <1-3 bullets describing what the PR changes and why>

## Test plan

- [ ] <verification step>
- [ ] <verification step>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Rules

- Every section header is present, even when its content is `None`.
- The footer line is mandatory and verbatim.
- The Test plan is a markdown checkbox list, not prose.
- The Linked issue section accepts multiple lines for multi-issue PRs:
  ```
  Closes #68
  Closes #72
  Refs #15
  ```
- Cross-repo references use `owner/repo#N` syntax:
  ```
  Closes acme/app-repo#68
  ```

## Heredoc invocation

Pass the body to `gh pr create` via a heredoc to preserve formatting:

```bash
gh pr create --title "the pr title" --body "$(cat <<'EOF'
## Linked issue

Closes #68

## Summary

- <bullets>

## Test plan

- [ ] <step>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

For draft PRs, add `--draft`:

```bash
gh pr create --draft --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

The single-quoted `'EOF'` heredoc delimiter prevents shell expansion of
backticks, dollar signs, and other special characters inside the body.
Always use the quoted form.
