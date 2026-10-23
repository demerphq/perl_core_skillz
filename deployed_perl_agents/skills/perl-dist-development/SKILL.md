---
name: perl-dist-development
description: "Develop Perl modules and distributions against an installed Perl: public interfaces, Perl semantics, documentation, and compatibility. Use for pure Perl code and the Perl side of XS modules, rather than changes to the interpreter."
---

# Perl module development

Work within the distribution's public contract and supported Perl versions.
Read its project instructions, module POD, build inputs, nearby tests, and CI
before choosing implementation patterns. A distribution can contain several
packages; a package name is not necessarily a separate distribution.

1. Establish the target interpreter, minimum Perl, declared dependencies, and
   actual authoring source. A generated `Makefile.PL` or module may be built
   from another input; change that input and regenerate through the project.
2. Describe the observable behavior being changed: arguments, context, return
   shape, mutation, encoding, errors, warnings, exports, or object lifecycle.
   Preserve established behavior outside that change.
3. Check Perl semantics before simplifying: definedness versus truth, scalar
   versus list context, aliases, autovivification, tied values, overload, and
   reference identity can make apparently equivalent code behave differently.
4. Add a regression test exercising the public interface and the failing
   boundary. Keep tests compatible with the declared Perl and test prerequisites.
5. Update module POD and the distribution's changelog for observable changes.
   Follow its versioning policy; do not bump every package version speculatively.

For API and language pitfalls, read [module-contracts.md](references/module-contracts.md).
Use the installed `perldoc perlmod`, `perldoc perlsub`, `perldoc perlref`, and
the specific builtin's documentation for disputed semantics. If local docs
are missing, obtain matching-version upstream documentation.

For build or metadata changes, the optional `perl-dist-build` skill supplies
that workflow. For tests, `perl-dist-testing` adds framework-specific guidance.
These are ordinary distribution tasks: core release notes, interpreter
regeneration, and core porting targets are not prerequisites.
