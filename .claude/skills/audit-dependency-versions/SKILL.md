---
name: audit-dependency-versions
description: Audit dependency versions, support status and compatibility in any repository against current upstream evidence; produce an action summary and a full reference audit.
---

# Dependency Version Audit

Audit the repository's actual stack; do not assume a language, package manager, hosting service or deployment platform.

## Discovery

- Run `bash "${CLAUDE_SKILL_DIR}/scripts/discover.sh" <repository>` for the date, revision, working-tree status and file list.
- Use that list to find dependency declarations, resolved versions, environment overrides, images, tooling and external API/model versions.
- Distinguish declared constraints, resolved versions and observed deployments; configuration does not prove what is running.
- Respect repository restrictions on sensitive files and commands.
- Audit without upgrades, lockfile changes or live-environment access unless requested.

## Evidence

- Verify releases, support, compatibility, deprecations and security claims against current primary sources; flag unavailable or conflicting evidence with a follow-up check.
- Cite repository evidence and direct upstream links beside each finding, using commit-pinned source URLs when they match the inspected content.
- Label uncommitted evidence.
- Use a path and relevant excerpt when no usable remote exists.
- Distinguish upstream from vendor/paid support, and operating-system support from image maintenance.
- A newer release alone does not establish urgency or end of support.
- Identify security fixes by affected behaviour, advisory and fixed version where established.
- Assess exploitability against actual usage.
- Check upgrade compatibility and migration constraints, including staged upgrades, state/data compatibility and old/new workload coexistence.

## Reports

Follow repository output and validation conventions; default to `version-debt-summary.md` and `version-debt.md` unless the user specifies otherwise.

- Both reports stand alone, without referring to each other, and state the repository, audit date, revision, coverage and verification limits, including transitive dependencies and built artifacts.
- **Summary:** only actionable findings, prioritised by consequence and urgency in **Immediate**, **High Priority** and **Scheduled** tables, omitting empty levels.
  - Use **Component | Issue | Action** columns, linking components to source and giving unrelated components separate rows.
  - State the affected version, concrete issue, official deadline with year where relevant, and a practical action with essential migration constraints; do not invent delivery dates.
  - Explain repository shorthand and keep cells brief enough to scan.
- **Full audit:** organise the inventory, evidence, findings, migration/validation needs and unresolved checks to suit the stack, including supported dependencies and reasons to retain them.

- Check claims, versions and links before presenting the reports.
- Present the summary first, the full audit as reference, and any unresolved verification limits.
