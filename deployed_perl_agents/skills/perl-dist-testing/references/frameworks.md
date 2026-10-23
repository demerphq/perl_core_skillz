# Test frameworks and helpers

## Keep the layers separate

`Test::More`, Test2 tools, and specialized helpers make assertions. Test::Harness/
TAP::Harness and `prove` run test programs and interpret TAP plus exit status.
MakeMaker and Module::Build build the code, set test paths, and invoke a harness.
Test2::Harness (`yath`) is another runner; using Test2 assertions does not require
replacing an existing TAP runner.

Inspect the actual imports and versions in nearby tests. Keep the existing
framework for a focused change. Do not import Test::More and a broad Test2
bundle into the same namespace: overlapping assertion names can have different
prototypes and semantics. Supporting a legacy test suite does not require a
wholesale framework conversion.

## Test::More

Use `perldoc Test::More` and `perldoc Test::Tutorial` for the supported version.

- Prefer `is`, `like`, `cmp_ok`, and `is_deeply` over `ok` around a comparison
  when their diagnostics describe the intended assertion. `is` uses string
  comparison; choose numeric or structural assertions deliberately.
- Structure equality is not reference identity. Use a suitable identity helper
  or `Scalar::Util::refaddr` with defined/reference checks; string overloading
  can make printed object addresses misleading.
- Use a fixed plan or `done_testing` at the real end of the file. Subtests need
  their own completion according to the framework version. Do not put file
  completion in `END`: a crash or premature exit must not look complete.
- `SKIP` describes an unavailable optional prerequisite/capability. Use a reason
  and the right count. Missing a declared mandatory test dependency is a setup
  failure, not an optional skip. TODO records a known incomplete behavior;
  remove it when fixing the behavior rather than hiding the regression.
- Use `diag`/`note` for diagnostics rather than emitting TAP-like stdout yourself.
  `BAIL_OUT` is for a condition preventing meaningful suite execution, not a
  replacement for every failed assertion.

Keep framework minimums consistent with features used: subtests, `done_testing`,
and helpers are not present in every historical release. Normal `use Module`
can load the code under test; a `use_ok` test is not a substitute for behavior.

## Test2 editions

Read the installed bundle's POD, not an example for a different edition.
`Test2::V0` and `Test2::V1` are edition names, separate from their module version
numbers. Declare the actual bundle/tools used in test prerequisites; do not
declare only Test2::Suite and assume the bundle will always be provided by it.

For an existing V0 suite, `use Test2::V0;` supplies tools and default pragmas/
plugins. Those defaults include behavior such as UTF-8 and random seeding;
consider their effects on byte-oriented tests and random tests. V1 has different
import behavior (`use Test2::V1;` supplies the `T2` interface; `-import` requests
tool imports). Verify edition/version support before adopting either syntax.
Do not force a new edition into an unrelated fix.

Test2's comparison `is` performs deep comparisons; Test::More's `is` compares
strings. Use `ref_is` when identity is required. Check `isa_ok`, `can_ok`, TODO,
skip, and exception tool signatures during any requested migration; replacing
only the `use` statement does not preserve semantics. A comparison that passes
after migration may now be checking a weaker property.

Use supported `dies`/`lives` or exception tools for errors and `warning`/
`warnings` tools for warnings, checking the actual return form and count. Assert
that the failure came from the intended operation, not an unrelated error in
test setup. Use scalar/list context deliberately inside assertion codeblocks.

## Specialized tools

Keep existing helpers when they fit the task. Examples to consult when present:

| Tool | What to verify |
| --- | --- |
| Test::Fatal | `exception { ... }` returns an exception or undef; it does not itself emit an assertion. Check class/message rather than only “something died.” |
| Test::Exception | Use its documented exception assertions if already used; do not assume it has the same call-stack behavior as another helper. |
| Test::Warnings / Test::Warn | Capture expected warnings and check content/count; check whether the helper adds an automatic no-unexpected-warnings assertion. |
| Test::Deep | Use matchers to describe intentionally partial/unordered data without weakening unrelated fields. Read the actual matcher contract. |
| Test::LeakTrace / Test::Refcount | Use for focused lifecycle bugs when available; account for warm-up, caching, temporary references, and supported configurations. |
| Test::Pod / Test::Pod::Coverage | Follow the project's author/release-test policy; syntactically valid POD and documented symbols are different checks. |

These are optional choices, not a requirement to add them all. Declare a helper
if ordinary tests import it. Avoid blanket warning suppression: capture the
specific expected warning and leave unrelated ones visible. Exception objects
may overload truth/stringification; test their intended identity or attributes.

## Writing test tools

Only use test-framework internals when developing a test helper itself.
For Test::Builder wrappers, preserve caller attribution using documented APIs
and test both passing and failing diagnostics with Test::Builder::Tester or
the project's existing tool tests.

For Test2 tools, acquire a context with `Test2::API`, emit events through it,
and release the real context on every path. Do not cache a live context across
calls. Use documented event interception (`intercept`) and testing helpers to
verify failure events, diagnostics, and source locations without turning an
expected failure into a failure of the outer test. Interception isolates events,
not necessarily every plugin's process-global state.

Consult `Test2::Manual::Testing`, `Test2::Manual::Tooling::FirstTool`,
`Test2::Manual::Tooling::Testing`, and the installed `Test2::API`/context docs.
Do not write new tooling against private framework object fields.
