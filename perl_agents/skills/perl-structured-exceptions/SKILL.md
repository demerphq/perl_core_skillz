---
name: perl-structured-exceptions
description: Apply the structured exception model when changing Perl core exception handling or migrating error and warning paths.
---

# Structured exceptions in Perl core

Use this guidance when changing exception construction, propagation, warning
handling, or converting a core error or warning call site. For catalog entries,
generated macros, and regeneration, also follow
[`perl-structured-diagnostics`](../perl-structured-diagnostics/SKILL.md).
For the current implementation status and remaining work, consult
`planning/perl-core-structured-errors.md` in the Perl checkout.

## The basic model

`XPerl::Exception` is the wrapper and accumulator object. It holds an ordered
collection of `XPerl::Diagnostic` objects and the exception-level state needed
to handle or propagate that collection. `XPerl::Diagnostic` represents one
warning or error, including its structured message data and its association
with relevant source locations.
Do not use “exception” and “diagnostic” as interchangeable names.

An exception can contain warnings, errors, or both. Its disposition follows
its diagnostics:

- An exception containing only warning diagnostics is a warning exception.
  Throwing it follows warning handling.
- An exception containing at least one error diagnostic is an error exception.
  Throwing it follows the normal exception and stack-unwind path.

Append diagnostics in encounter order so earlier information is retained.
Use the exception machinery to accumulate warnings as well as errors. This is
the recommended way to collect warnings, including warnings whose delivery is
deferred or combined with other diagnostics. When a non-continuable error
requires an immediate throw, throw the whole accumulated exception, including
diagnostics collected before that error. Do not replace the accumulator with a
new exception containing only the last message.

## Converting a legacy path

When migrating a call site that builds or modifies an error string:

1. Trace how the message is produced, when it is emitted, and whether it is
   deferred or accumulated with other diagnostics.
2. Represent each distinct warning or error as a diagnostic. Put variable
   values in named, typed parameters and keep message structure in the
   diagnostic catalog. Avoid assembling English sentences in C.
3. Append the diagnostic to the active `XPerl::Exception`, creating the
   accumulator when needed. Use this for warnings as well as errors. Preserve
   encounter order and preserve the association between diagnostics and their
   source locations. The representation depends on the diagnostic type and
   scenario: a location may belong to one diagnostic, or a location entry may
   apply to a following group of lightweight diagnostics from the same source
   position. Do not assume either representation universally. Check that
   legacy rendering preserves each diagnostic's location association rather
   than attaching one suffix to the aggregate indiscriminately.
4. Choose the configured warning or error delivery path. Warning delivery
   must retain category enablement and fatalization behavior. Error delivery
   must retain the caller's continuation, parser recovery, or unwind behavior.
5. If the path must defer handling, leave the diagnostics in the accumulator.
   If it must throw now, throw the complete accumulator according to its
   resulting severity.
6. Update related tests, catalog data, generated files, and migration
   documentation. Test aggregation as well as the final rendered message.

Do not turn a warning into an error merely because both use the same wrapper
type. Do not stringify an accumulated exception and later treat that text as
the canonical state. Stringification is a presentation boundary.

Keep source locations in diagnostics distinct from the exception's
propagation stack. The exception stack identifies where the exception was
thrown or propagated. It does not identify where each error arose inside
compiled source. For example, a failed `require` can have propagation context
up to the `require` call and diagnostic locations in the file being compiled.
Represent both when the scenario needs them, and do not use the exception
stack as a substitute for compilation locations.

## Migrating string accumulators

Look for `SV *` or character buffers that collect warning text for later
emission, especially code that appends punctuation, clauses, or lists of
values. Replace the text accumulator with an `XPerl::Exception` accumulator.
Append a diagnostic when each warning condition is recognized, then deliver
the accumulated exception at the existing flush point. Preserve the existing
warning category, enablement, fatalization, and reset behavior.

Keep separate warning conditions as separate diagnostics in encounter order.
When one warning describes several values or properties, keep it as one
diagnostic with typed, named parameters. Do not pass a preassembled English
sentence as one text parameter when its semantic parts can be represented
directly. For example, a locale warning can carry locale type, problematic
characters, and codeset state as structured values, while the catalog owns
the sentence and language-specific ordering.

## Compatibility interfaces

The canonical structured state is the `XPerl::Exception`. Compatibility
interfaces such as `$@` may expose a historical user-thrown reference while
the structured exception retains the corresponding diagnostic. Keep that
projection separate from the canonical object. When touching this behavior,
follow the current design and status in the structured errors planning
document. Do not assume planned hooks or APIs exist just because they appear
in design notes.

`try`/`catch` accepts one or two lexical variables. In `catch ($value)`, the
variable follows `$@` compatibility behavior. In `catch ($value, $exception)`,
the second variable always receives the canonical `XPerl::Exception`, even
when the first variable is an original reference thrown by user code.

`$SIG{__EXCEPT__}` receives the canonical exception before the legacy warning
or die hooks. Its diagnostic content changes are visible to those hooks and
to rendering. It may promote a warning to an error, but an error's severity
must not be downgraded. Recheck disposition after the hook. A promoted
warning follows the fatal path and is not sent to `__WARN__`. Each warning
sent to `__WARN__` must use its rendered message, including source location,
while the second argument remains the aggregate canonical exception.

## Review checklist

- Is each warning or error represented as a separate diagnostic?
- Does the exception retain all diagnostics in chronological order?
- Does any non-continuable error throw the accumulated exception?
- Does a warning-only exception remain on the warning path, including its
  category and fatal-warning behavior?
- Are source locations and typed parameters preserved without building the
  final English sentence at the call site?
- Are compatibility projections kept distinct from canonical structured
  state?
- Do two-value catches expose the compatibility value and canonical object
  in the correct arguments?
- Do exception hooks preserve monotonic severity and deliver rendered warning
  text while retaining the canonical aggregate?
- Do tests cover accumulation, disposition, and any legacy behavior changed?
