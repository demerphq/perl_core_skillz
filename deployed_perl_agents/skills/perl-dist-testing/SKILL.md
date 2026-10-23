---
name: perl-dist-testing
description: "Design and run Perl distribution regression tests with Test::More, Test2, and TAP harnesses; test built XS modules, diagnose native failures, and validate release contents with an installed Perl."
---

# Perl distribution tests and debugging

Use the distribution's existing framework and harness. Separate assertion
libraries from the runner and build driver. A bug fix does not require a test
framework migration or an added author-only dependency for ordinary users.

1. Identify the public behavior and a minimal test that fails for the original
   defect. Check values, mutation, warnings/errors, context, and lifetimes as
   needed; loading a module alone is not behavioral coverage.
2. Build XS first. Run the focused test with that build's Perl and staged
   module paths; then run the distribution suite through its normal driver.
   `prove -l` adds `lib`, not the compiled extension in `blib/arch`.
3. Use the assertions and signatures belonging to the actual framework.
   Test::More's `is` compares strings; Test2 comparison tools have different
   semantics. A name-preserving migration can silently weaken identity tests.
4. Give each test file a fixed plan or a reachable `done_testing` at its end.
   Do not put completion in `END`, suppress crashes, or skip missing required
   modules. Skip genuinely unavailable optional capabilities with a reason.
5. For XS defects, exercise the relevant boundary: retained input, repeated
   calls, exceptions, magic, encoding, reentry, or teardown. Use a subprocess
   for a potential native crash and check exit status as well as output.

Read [frameworks.md](references/frameworks.md) for Test::More, Test2 editions,
exception/warning helpers, and testing test tools. Read
[running-debugging.md](references/running-debugging.md) for focused commands,
XS test matrices, debugger use, and leak analysis.

Keep generated-file and metadata checks proportional to the change. For release
contents, test a fresh unpacked archive or the build tool's distribution test
directory. Tests that pass only with undeclared developer-installed modules do
not demonstrate a usable distribution.
