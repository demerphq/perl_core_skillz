# Perl Repository Agent Directives

This file gives repository-wide instructions for coding agents working on
Perl core. Apply these directives to every task unless the user explicitly
asks for a different approach.

## Prime Directives

- Keep changes to existing code or infra small, incremental, and reviewable.
- Prefer self-contained commits that include code, tests, documentation, and
  generated-file updates required by the change.
- Add or update tests for behavior changes, bug fixes, generated-file checks,
  and regression-sensitive refactors.
- Update documentation when behavior, APIs, diagnostics, build behavior,
  release process, or contributor workflow changes.
- Consider whether `pod/perldelta.pod` needs an entry for user-visible,
  downstream-visible, release-note-worthy, or maintainer-relevant changes.
- Preserve portability. Check platform READMEs, `hints/`, `Cross/`, EBCDIC,
  locale, threads, multiplicity, and non-Unix assumptions when relevant.
- Prefer existing Perl core patterns, helper macros, regeneration targets, and
  porting tools over new local conventions.
- Do not change shared porting, build, test, regeneration, or other generic
  infrastructure merely to accommodate a specific feature or distribution.
  Such changes require the user's explicit authorization.
- Do not hand-edit generated files without also identifying and running the
  generator, or documenting why regeneration is not appropriate.
- Keep public API, binary compatibility, and XS/embedding compatibility in mind
  for C and header changes.
- Add every new distribution file to `MANIFEST` with a short description, then
  run `make manisort`.
- Use focused validation first, then broaden. `make test_porting` is a good
  broad check for documentation, metadata, generated-file, and policy changes;
  for preliminary screening, `TEST_JOBS=N make -jN test_porting` is a
  reasonable parallel form.
- Use code archaeology when it helps explain bug reports, surprising behavior,
  compatibility constraints, or old design choices.

## Agent Skills

Generic Perl skills live in `perl_agents/skills/`. XPerl-specific skills live
in `xperl_agents/skills/` and supplement the generic package for XPerl work.
Use only the generic package for ordinary Perl checkouts.

The canonical skills live in the sibling `perl/.agents/skills/` tree. Make
substantive changes there first. Run `./sync-agent-skills --sync` here for
generic guidance, or add `--xperl` to include the XPerl package. Verify with
`--check` and the same scope. Use `--from-mirror` only after reviewing mirror
changes or when restoring missing guidance to a checkout.

## Core API design

When adding experimental core functionality, prefer a builtin function over a
new keyword whenever ordinary function-call syntax is sufficient. Reserve
keywords for constructs that require parser or compiler context. When a
feature needs both special syntax and associated callable builtins, provide a
small wrapper pragma that enables the feature and imports the builtins
together; keep the underlying feature and builtin mechanisms independently
usable.

## Companion instructions

`CLAUDE.md` is a concise pointer to this file and should not contain new
guidance; `AGENTS.md` contains the full repository guidance and is the place
to make changes.
