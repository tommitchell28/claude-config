# Examples

Walked-through scenarios showing how the `creating-pull-requests` skill
behaves for the most common situations.

## Example 1: Same-repo issue inferred from conversation

User earlier said: "let's fix #42, the login bug." Now says: "open a PR".

1. `git rev-parse --abbrev-ref HEAD` → `fix/42-login`. Not the default
   branch — proceed.
2. Issue inferred: `#42`.
3. `gh issue view 42` → exists.
4. Ask the user: "Does this fully resolve #42?" → "yes".
5. Compose PR body with `Closes #42`.
6. `gh pr create` → return URL.

## Example 2: Cross-repo issue

User says: "open a PR in tooling-repo that closes app-repo#68".

1. Pre-flight checks pass.
2. Cross-repo reference: `acme/app-repo#68`.
3. `gh issue view 68 --repo acme/app-repo` → exists.
4. Body: `Closes acme/app-repo#68`.
5. `gh pr create`.

## Example 3: No associated issue

User says: "open a PR for this typo fix".

1. No issue in conversation, no obvious issue in branch name, none in
   commit messages.
2. Ask: "Which GitHub issue does this PR address? Reply with `#N`,
   `owner/repo#N`, an issue URL, or `none`."
3. User: "none".
4. Confirm: "This PR has no linked issue. Confirm you want to open it
   with `## Linked issue` set to `None`?" → "yes".
5. Body's `## Linked issue` section: `None`.
6. `gh pr create`.

## Example 4: Validation catches a typo

User says: "open a PR closing #86" (but the real issue is #68).

1. `gh issue view 86` → 404.
2. Surface the error to the user, ask for the correct number.
3. User: "sorry, #68".
4. `gh issue view 68` → exists. Proceed.

## Example 5: Multiple linked issues, mixed closure

User says: "this PR fixes #68 fully and partially addresses #72".

1. `gh issue view 68` → exists. `gh issue view 72` → exists.
2. Linked issue section:
   ```
   Closes #68
   Refs #72
   ```
3. `gh pr create`.

## Example 6: Partial closure asked for clarification

User says: "PR for #68" but the diff only ships half the issue.

1. `gh issue view 68` → exists.
2. Ask: "Does this PR fully resolve issue #68, or only part of it?
   (`Closes` will auto-close on merge; `Refs` only links.)" → "only
   part".
3. Linked issue section: `Refs #68`.
4. `gh pr create`.
