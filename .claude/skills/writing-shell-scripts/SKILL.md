---
name: writing-shell-scripts
description: Shell script style standards. Use when writing, reviewing, or modifying shell scripts (.sh, bash).
---

# Shell Script Style Standards

Apply these standards when writing or reviewing bash/shell scripts.

## Help flags

Every script must support `-h`/`--help` that prints clear usage text covering:
- What the script does
- Arguments and flags
- Usage examples

## Header comment

A brief description comment at the top of each script. Do not duplicate the help text — keep it to one or two lines explaining the script's purpose.

## Readability over comments

- Use clear variable names and function names so the code is readable without comments
- Functions should have self-explanatory names
- Comments explain *why*, not *what* — favour readable code over inline explanations
