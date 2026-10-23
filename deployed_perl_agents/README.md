# Skills for development with an installed Perl

This is an independent, ordinary-Perl skill package for developing modules,
CPAN distributions, XS extensions, and applications embedding an installed Perl.
It needs neither a Perl source checkout nor any other skill package in this
repository. Its canonical sources live here, not in the sibling Perl checkout.

## Install

Copy the desired directories from `skills/` into the skill discovery directory
used by your agent. For a project using `.agents/skills/`, run from this
repository, replacing `/path/to/project` with the destination:

```sh
mkdir -p /path/to/project/.agents/skills
cp -R deployed_perl_agents/skills/perl-dist-* /path/to/project/.agents/skills/
```

Review existing destination skills before copying over them. Copy whole skill
directories, including their references. Do not copy this repository's or the
core package's `AGENTS.md` into a module project. Existing project instructions
remain authoritative. Each skill can be installed individually; suggestions
to consult another skill in this package are optional.

## Choose skills

| Skill | Use it for |
| --- | --- |
| `perl-dist-development` | Perl module APIs, language semantics, documentation, compatibility |
| `perl-dist-build` | MakeMaker, Module::Build, prerequisites, XS builds, distribution contents |
| `perl-dist-xs` | XSUBs, typemaps, generated wrappers, native handles, loading |
| `perl-dist-xs-memory` | Ownership, mortality, magic, containers, strings and encoding |
| `perl-dist-xs-callbacks` | Calling Perl from C, stack discipline, exceptions, embedding |
| `perl-dist-portability` | Supported Perls, public C APIs, ppport.h, interpreter state, platforms |
| `perl-dist-testing` | Test::More, Test2, TAP harnesses, regression tests, XS debugging |

Start with the skill matching the actual task; do not load the entire package
for every edit. Entry points contain essential decisions and link to detailed
references only where needed. These skills use distinct names so they can
coexist with core development skills, but they do not import core workflows.

## Maintain and validate

Edit this tree directly. `sync-agent-skills` maintains the existing core skill
mirrors and does not read or write this package. There is no Perl distribution
`MANIFEST` or `make manisort` target in this repository.

[The source review](SOURCE-REVIEW.md) records the manuals examined and their
effect on the guidance. Prefer the documentation belonging to the target Perl
and installed tool versions when maintaining version-sensitive instructions.
Do not copy development-branch APIs into general extension advice.

Run the package checks from the repository root:

```sh
prove -v deployed_perl_agents/t/package.t
prove -v deployed_perl_agents/t/xs-smoke.t
```

The smoke test builds temporary XS distributions using MakeMaker and, when
available, Module::Build. It checks the executable XS examples with Test::More
and, when available, Test2::V0. It does not install modules. A working C toolchain
is needed; unavailable optional tools are reported as skips. This verifies
examples and packaging, not every possible model response or supported platform.
