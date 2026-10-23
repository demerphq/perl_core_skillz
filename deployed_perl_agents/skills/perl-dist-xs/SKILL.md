---
name: perl-dist-xs
description: "Write or repair XS modules built against an installed Perl: XSUB signatures, typemaps, xsubpp output, native library wrappers, object handles, and XSLoader. Does not prescribe interpreter implementation changes."
---

# XS interfaces for distributions

Treat an XSUB as a Perl API implemented through a generated C wrapper.
Correct C in a `CODE:` block is only part of correctness: argument conversion,
output conversion, mortalization, and return counts also come from `xsubpp`.

1. Read the Perl-facing POD, `.xs`, local typemaps, build inputs, and tests.
   Record the minimum Perl and ExtUtils::ParseXS versions. Consult `perldoc
   perlxs`, `perldoc perlxstut`, and `perldoc perlxstypemap` from the target
   environment; newer documentation may describe syntax its parser lacks.
2. Define each boundary: accepted Perl values, coercion or rejection policy,
   byte or character semantics, C size/range limits, native ownership, and
   failure behavior. A typemap conversion is not general argument validation.
3. Use normal typemaps and `CODE:`/`OUTPUT:` for a single conventional return;
   use `PPCODE:` when controlling the return list. Keep input access separate
   from pushes that overwrite argument slots.
4. Trace ownership through the generated C. With the usual `T_SV` output,
   return a fresh owned reference, or increment a borrowed one; do not also
   mortalize that same owned reference manually. Inspect custom typemaps before
   applying this rule.
5. Regenerate with the project's actual build, inspect the affected wrapper,
   and test the built extension through its Perl interface. A compile-only
   check misses lifetime, encoding, context, and loading failures.

Read [interfaces.md](references/interfaces.md) for conversions, return paths,
typemaps, and loading. Read [native-handles.md](references/native-handles.md)
when wrapping native resources or C++ objects.

For detailed ownership, magic, or encoding analysis, `perl-dist-xs-memory` is
an optional companion. For callbacks into Perl, `perl-dist-xs-callbacks` covers
stack and exception handling. Prefer documented extension APIs; an exported
symbol or visible struct member alone does not establish a supported interface.
