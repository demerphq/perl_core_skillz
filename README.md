# Perl Core Agent Skills

This repository contains the legacy mirror of the agent guidance and
subsystem skills used when developing Perl core.

The canonical source is maintained in the Perl checkout at:

```text
perl/.agents/skills/
```

In this repository, the mirrored skills are kept under:

```text
perl_agents/skills/
```

The mirror exists for tooling or checkouts that still expect the historical
`perl_agents/` layout. Make substantive skill changes in the canonical Perl
checkout first, then update this mirror.

## Repository layout

- `AGENTS.md` — guidance for this mirror repository.
- `CLAUDE.md` — concise pointer to `AGENTS.md`.
- `perl_agents/skills/` — mirrored Perl-core skill definitions and references.
- `perl_agents/AGENTS.md` and `perl_agents/CLAUDE.md` — guidance for the
  historical package layout.
- `sync-agent-skills` — checker and synchronizer for the guidance and skill
  tree.

The `AGENTS.md` and `CLAUDE.md` files use path-adjusted wording where needed;
the skill files themselves should be byte-identical to the canonical tree.

## Synchronizing the mirror

Run these commands from this repository's root:

```sh
./sync-agent-skills --check
./sync-agent-skills --sync
```

`--check` is non-mutating and is the normal verification command. `--sync`
copies missing or changed guidance and skill files from the canonical Perl
checkout to the mirror.  It adjusts the repository-specific paths in
`AGENTS.md` and `CLAUDE.md` for the destination layout.  This is the default
direction and can be written explicitly as `--from-perl`.

Use `--from-mirror` to reverse the direction. This is useful when restoring
`AGENTS.md`, `CLAUDE.md`, or the skill tree to a Perl branch which does not
contain them, or after independently reviewing changes made in the mirror:

```sh
./sync-agent-skills --check --from-mirror
./sync-agent-skills --sync --from-mirror
```

If the Perl checkout is not the sibling directory named `perl`, provide it
explicitly:

```sh
./sync-agent-skills --check /path/to/perl
./sync-agent-skills --sync /path/to/perl
./sync-agent-skills --sync --from-mirror /path/to/perl
```

Use `--prune` with `--sync` only when files which exist only in the destination
have been reviewed and should be removed.

## Updating skills

1. Edit the canonical skill under `perl/.agents/skills/`.
2. Run the relevant Perl validation from the Perl checkout.
3. Run `./sync-agent-skills --sync` here.
4. Confirm `./sync-agent-skills --check` passes and review the resulting diff.

Keep changes focused and update the relevant `SKILL.md` reference material
when the workflow or commands described by a skill change.
