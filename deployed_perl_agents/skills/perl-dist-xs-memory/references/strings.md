# Strings at the XS boundary

## Decide semantics before fetching a pointer

Perl strings can represent characters or encoded bytes. A `char *` alone carries
neither the byte length nor the interpretation. Define input and output semantics
independently, using the native library's contract.

| Contract | Starting API | Consequence |
| --- | --- | --- |
| Bytes / already encoded data | `SvPVbyte(sv, len)` | Obtains a byte representation; croaks if characters cannot be downgraded. It does not encode arbitrary Unicode as UTF-8. |
| Characters passed to a UTF-8 native API | `SvPVutf8(sv, len)` | Obtains Perl's UTF-8 representation; validate further if the native API requires strictly valid Unicode UTF-8. |
| Explicitly representation-aware code | `SvPV(sv, len)` plus `SvUTF8(sv)` after conversion | Handles the buffer together with its encoding flag; raw bytes alone are ambiguous. |

`len` here is a `STRLEN` lvalue filled by the macro, measured in bytes. Fetch
the pointer and length in a separate statement before calling a native function;
C argument evaluation order does not guarantee `f(SvPVbyte(sv, len), len)` uses
the updated length. Avoid side effects in API macro arguments, especially when
supporting older Perls that may evaluate them more than once.

The UTF-8 flag describes internal representation; it does not prove external
input was decoded, validate an arbitrary byte sequence, or say whether an
interface promises text. Perl's extended internal encoding can represent values
outside Unicode, and on EBCDIC the internal encoding differs. A native protocol
requiring standard Unicode UTF-8 needs a suitable validated encoding boundary,
not an assumption that all `SvPVutf8` results meet it.

## Length and lifetime

Use explicit lengths for binary data and embedded NULs. If a native interface
only accepts a NUL-terminated string, reject embedded NULs when truncation would
change meaning. Default `char *` output and `newSVpv(ptr, 0)` determine length
with C string rules; `newSVpvn(ptr, len)` copies the given byte count.

Treat returned PV pointers as borrowed views. A subsequent conversion, overload,
magic invocation, mutation, callback, or destruction can invalidate a view. It
may point to a temporary rather than directly into the original SV. Merely
incrementing that SV's refcount does not pin this address. Copy when a native
operation retains data, invokes Perl that can change it, or outlives the view.
Release the copy with its matching allocator.

Check native return values before using a buffer: NULL is not automatically an
empty string. Validate lengths and numeric conversions to narrower native size
types. Consider aliasing when input and output share an SV or buffer.

## Output and mutation

Prefer a fresh SV and high-level setters for a fresh result. For binary output,
`newSVpvn` creates a byte string; for text, perform the intended decoding or
establish validated internal UTF-8 bytes and set the flag deliberately. Never
set `SvUTF8_on` merely to “convert” arbitrary bytes.

When reusing an existing SV, some setters such as `sv_setpvn` leave its UTF-8
flag unchanged. Establish the correct flag before invoking set magic, so a
tied `STORE` sees the intended value. Do not clear flags indiscriminately on
text output or copy the input flag when the operation changes the encoding.

Do not write through a borrowed PV just because its C type is mutable. Read-only
values, copy-on-write sharing, cached numeric values, allocated size, logical
length, and the terminal NUL must stay consistent. Prefer Perl's mutation APIs.
If direct writing is necessary, establish writability and capacity through
documented target APIs, maintain flags/length/NUL, invoke required set magic,
and test read-only and COW cases. Avoid raw SV body fields.

## Regression inputs

Select cases relevant to the interface: empty input, ASCII, embedded NUL,
Latin-1-range characters in upgraded and downgraded representations, characters
above 255, malformed encoded bytes, native errors, tied inputs with observable
FETCH counts, overloaded stringification, and aliased input/output. For a byte
API, unrepresentable characters should follow its documented rejection policy.
For a text API, equivalent character strings should behave consistently despite
their internal representation.

Sources: `perlguts` Working with SVs and Unicode Support; target `perlapi` entries
for `SvPV*`, `newSVpvn`, `sv_setpvn`, `sv_utf8_*`; `perlunitut`, `perlunicode`,
and `Encode` for character/octet boundaries.
