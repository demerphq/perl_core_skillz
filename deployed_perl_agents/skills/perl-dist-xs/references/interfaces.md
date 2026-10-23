# XSUB interfaces and generated wrappers

Use `perlxs`, `perlxstut`, `perlxstypemap`, `ExtUtils::ParseXS`, `xsubpp`, and
`XSLoader` documentation for the selected environment. Read the generated C
from the actual build whenever conversion or return ownership is in question.

## Follow the whole translation

The normal pipeline is `.xs` plus typemaps and includes → generated C → object
files → loadable extension under `blib/arch`. The `.pm` typically loads it via
`XSLoader::load(__PACKAGE__, $VERSION)`. Check `MODULE`, `PACKAGE`, naming,
version initialization, and `BOOT:` ordering together. Perl callbacks used by
boot code must exist before it runs. Keep runtime version checks enabled.

For an XS parser or compiler error, inspect input first, then the affected
generated wrapper and its line directives. Fix `.xs` or typemap input and
rebuild, rather than patching generated C. Not every C file in an XS project
is generated; identify its producer before editing.

## Choose the conversion deliberately

| Perl interface | Useful representation | Check |
| --- | --- | --- |
| Ordinary C number | Declared C type with existing numeric typemap | Coercion, negative unsigned input, overflow, narrowing, fractional values |
| Binary or text string | `SV *` with explicit pointer/length conversion | Encoding, embedded NULs, temporary pointer lifetime |
| Scalar requiring Perl semantics | `SV *` | Get magic, overload, mutation and ownership |
| Array/hash reference | Checked referent or appropriate typemap | Reference type, magic, missing elements, borrowed results |
| Native resource | Established wrapper with a documented owner | Type validation, closed state, parent lifetime, clone policy |

`SvIOK`/`SvPOK` describe cached representation, not a general Perl type system.
Do not reject a numeric string merely because it has not yet been converted,
unless strict representation is explicitly part of the API. Conversely,
`SvIV` followed by a cast is not proof that a user value fits a C `int`, size,
offset, or library enum. Validate ranges before narrowing or computing sizes.

The default `char *` mapping does not specify an external encoding and commonly
uses NUL-terminated output. Use explicit length-aware conversion for binary
data, and specify text conversion for native APIs. Do not infer encoding from
the fact that a pointer is `char *`.

## Return paths

`CODE:` does not automatically return a manually assigned `RETVAL` without
the corresponding `OUTPUT:`. A conventional fresh scalar return is:

```xs
SV *
answer()
    CODE:
        RETVAL = newSViv(42);
    OUTPUT:
        RETVAL
```

With the ordinary `T_SV` output, generated code mortalizes `RETVAL`. Do not add
`sv_2mortal(RETVAL)` in this example. To return a borrowed scalar, provide an
owned reference with `SvREFCNT_inc` first. Decide whether aliasing the existing
SV is intended; a fresh copy has different mutation/identity semantics.

For a new array reference, explicit RV creation makes ownership clear:

```xs
SV *
empty_array()
    CODE:
        RETVAL = newRV_noinc((SV *)newAV());
    OUTPUT:
        RETVAL
```

Do not generalize that rule to a declared `AV *` return without reading its
typemap. Traditional `T_AVREF`/`T_HVREF` mappings increment the referent, whereas
their `*_REFCOUNT_FIXED` counterparts transfer a reference. A newly created
container and a borrowed container therefore need different treatment.

Use `PPCODE:` for an explicit list of results. Reserve capacity with `EXTEND`
before `PUSH*`, or use the supported `XPUSH*` variants; ensure pushed SVs remain
alive for the required duration. It resets the local stack position for return
values, so pushing results can overwrite original `ST(i)` inputs. Extract or
retain needed arguments before overwriting them. Use `XSRETURN_*` for explicit
early XSUB returns rather than plain C `return`. Empty list, one `undef`, false,
and zero are different contracts.

## Typemap review

Typemaps generate code; inspect both INPUT and OUTPUT. Check local overrides,
inline `TYPEMAP:` declarations, `xsubpp` options, and the installed system
typemap. Order and parser behavior can vary with ExtUtils::ParseXS versions.
Use a distinct typedef/mapping when changing the semantics of just one type,
rather than overriding a common mapping across unrelated XSUBs.

Review validation and acquisition performed before `CODE:`: an early typemap
may allocate a resource before a later conversion croaks. OUTPUT conversion
can fail too. `CLEANUP:` is emitted on the normal return path, not a general
exception handler. Use unwind-safe ownership for resources that must survive
these stages.

For C header constants, use the project's `ExtUtils::Constant` generator and
regenerate both C and XS include outputs. `h2xs` can explain old skeletons;
its generated boilerplate is a starting point, not a complete tested API.
