# Perl and XPerl Agent Skills

This repository mirrors guidance maintained in `perl/.agents/skills/`.
Generic Perl skills and XPerl-specific skills are separate packages:

- `perl_agents/skills/` contains generic Perl-core development guidance.
- `xperl_agents/skills/` contains XPerl-specific guidance, including structured
  exceptions, diagnostic migration, and diagnostic inventory.

XPerl uses the generic skills together with its specialized package. Ordinary
Perl checkouts use the generic package. XPerl skill names begin with `xperl-`
and their descriptions identify their scope.

Make substantive skill changes in the canonical checkout first. Each mirrored
skill file must be byte-identical to its canonical counterpart. The union of
both packages corresponds to the canonical skill tree.

## Repository layout

- `AGENTS.md` and `CLAUDE.md` describe this mirror repository.
- `perl_agents/` provides generic skills and guidance for the historical layout.
- `xperl_agents/` provides the XPerl supplement and its scope guidance.
- `sync-agent-skills` checks or updates the selected packages.

## Synchronizing

Run these commands from this repository's root:

```sh
# Generic Perl skills and guidance.
./sync-agent-skills --check
./sync-agent-skills --sync

# Generic skills and the XPerl supplement.
./sync-agent-skills --check --xperl
./sync-agent-skills --sync --xperl
```

The default source is the sibling `perl` checkout. Provide another checkout
path as the final argument when needed. `--check` changes no files; `--sync`
copies missing or changed files. Wrapper paths are adapted for the destination.

## Restoring a checkout

Use `--from-mirror` to restore a missing skill tree or to propagate reviewed
mirror changes back to the canonical checkout:

```sh
# Ordinary Perl: generic skills only.
./sync-agent-skills --sync --from-mirror /path/to/perl

# XPerl: generic skills and its supplement.
./sync-agent-skills --sync --from-mirror --xperl /path/to/xperl
```

XPerl skills are never copied by a generic restoration. Existing XPerl skills
in the destination are outside the scope of a generic check or synchronization.
Use `--xperl` to maintain them. The checker also recognizes the historical
`perl-structured-*` skill names as XPerl-specific.

Use `--prune` with `--sync` only after reviewing destination-only files.
Pruning follows the selected scope.

## Updating guidance

1. Edit the canonical skills and their references.
2. Prefix XPerl-specific skill names with `xperl-` and state that scope in their
   descriptions. Keep general improvements in the generic skills.
3. Synchronize the appropriate packages and check them in both directions.
4. Review and commit the mirror changes.
