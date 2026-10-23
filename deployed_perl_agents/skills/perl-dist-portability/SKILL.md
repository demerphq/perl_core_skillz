---
name: perl-dist-portability
description: "Keep Perl distributions and XS modules portable across their supported installed Perls, C toolchains, operating systems, character sets, threading configurations, and native library versions; use public APIs and Devel::PPPort."
---

# Distribution and XS portability

Determine the project's promised support before introducing syntax, APIs,
compiler features, dependencies, or platform assumptions. Keep support policy
changes explicit. The Perl used for development is one data point in that
support range.

1. Record the target Perl's version and `Config`, the minimum Perl and build
   tool versions, and relevant native library requirements. Keep Perl-language,
   C API, XS parser, and external-library compatibility checks distinct.
2. Prefer documented public APIs and their normal short names. A declaration
   in installed headers, a `Perl_` prefix, or documentation in `perlintern`
   does not establish an extension API guarantee. Check experimental and
   deprecated status as well as symbol presence. A function exported on the
   development Perl can be core-only on an older supported one.
3. Use the distribution's `ppport.h` where applicable; inspect its API support
   and diagnostics before adding version tests or private shims. Backport
   availability does not establish semantic equivalence on every target.
4. Preserve the target Perl's compiler, linker, include, and ABI configuration.
   Rebuild native artifacts separately for different Perls and incompatible
   configurations. Do not fix a loader mismatch by disabling version checks.
5. Choose validation for the affected support axis. Report which configurations
   actually ran and which remain untested; a local pass cannot establish
   Windows, EBCDIC, 32-bit, non-threaded, or oldest-supported-Perl support.

Read [api-platforms.md](references/api-platforms.md) for ppport, numeric and
character portability, native linking, and PerlIO. Read
[interpreter-state.md](references/interpreter-state.md) for `pTHX`/`aTHX`,
`MY_CXT`, ithreads, cloning, and process state.

For Perl-level behavior use the target `perlport`, `perlunicode`, and
`perllocale`. For XS use `perlapi`, `perlclib`, `perlxs`, and `Devel::PPPort`.
Neither interpreter source changes nor a new Perl build are routine steps in
fixing a distribution's portability.
