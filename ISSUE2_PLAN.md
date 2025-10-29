Issue 2: Scheduler capabilities — UI, CLI, Core

Branch: feat/scheduler-capabilities-ui-cli

Goal
- Provide a capability-aware scheduler surface: CLI subcommand, consolidated core functions, and UI changes to disable/hide schedule controls when scheduler unavailable.

Planned commits (3)
1) CLI: add `backintime schedule --status` which prints the short scheduler diagnostics line and exits 0 if scheduler available, 1 otherwise. Add unit tests for exit codes.
2) Core: consolidate cron-line creation into a capability-aware helper function and centralize error messages. Add unit tests for created cron lines.
3) UI/Qt: disable/hide Schedule controls when `HAS_SCHEDULER==False` and add tooltip "Scheduler not available on this host". Add small UI test or manual verification steps.

Checklist
- [ ] Create branch `feat/scheduler-capabilities-ui-cli`
- [ ] Implement CLI subcommand + tests
- [ ] Implement core consolidation + tests
- [ ] Implement UI changes + manual verification
- [ ] Run `docker build && docker run --rm bit-check` tests (simulate both presence/absence of cron)
- [ ] Add CHANGELOG entry and PR

Notes
- Keep changes focused to ~150+ LOC of production code (excluding tests/docs) by consolidating existing logic rather than adding duplicated code.
