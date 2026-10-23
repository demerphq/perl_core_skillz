# Ownership, cleanup, and magic

## Make an ownership ledger

For each value record: where it came from, whether this code owns a reference,
who takes that reference next, and what happens on an error. Explain transfers
in comments where the C statements alone hide them.

| Operation | Ownership consequence |
| --- | --- |
| `newSV*`, `newAV`, `newHV` | Normally returns a new value with one reference owned by the caller; inspect specialized constructors. |
| Argument `SV *`, `ST(i)`, `SvRV`, ordinary container fetch | Normally borrowed; do not release or transfer the owner's reference. Observe exact API and magic behavior. |
| `SvREFCNT_inc(sv)` | Creates another owned reference to the same SV, not a value snapshot. |
| `newSVsv(sv)` | Creates a new scalar value; references inside it still refer to the same referents. It is not a recursive deep copy. |
| `newRV_inc(sv)` / `newRV(sv)` | New RV owns an added reference; the caller still owns any reference it held before. |
| `newRV_noinc(sv)` | New RV takes an existing owned reference; do not decrement that transferred reference. |
| `sv_2mortal(sv)` | Transfers one owned reference to the temps stack for a later decrement; does not increment it. |
| `SvREFCNT_dec(sv)` | Releases one owned reference; final release may run Perl destructors and other cleanup. |

Do not decrement a borrowed value to balance somebody else's increment. Do
not mortalize the same ownership obligation twice. A mortal value may still
have independent owned references; reason about those references separately.

The normal `SV *` XSUB output mortalizes an owned return reference. Include
that implicit transfer in the ledger. Custom typemaps and AV/HV reference
typemaps can change the calculation: inspect generated C rather than applying
one rule to every pointer return.

## Containers

For ordinary arrays and hashes, `av_fetch`/`hv_fetch` can return NULL; test
before dereferencing `SV **`. An absent element and an existing undef element
are distinguishable. `lval` fetches can create entries, so do not use them for
read-only inspection. Empty arrays have a last index of -1; keep index types
signed when a negative sentinel is possible.

A successful ordinary `av_store`, `hv_store`, or `hv_store_ent` takes one
reference to the supplied value without adding one. Supply a new owned value
or increment a borrowed value before passing ownership. For APIs returning
NULL without retaining it, release that still-owned reference. Do not flatten
this into a generic “NULL means allocation failure” rule: tied containers can
return NULL for other reasons.

Read the exact target documentation for tied container access. A fetch/store
may arrange element magic rather than perform all Perl-level `FETCH`/`STORE`
work immediately. Scalar get/set magic is relevant too. Test tied semantics
through the public API rather than assuming an ordinary-container recipe is
sufficient. Fast `*_simple` APIs have stronger preconditions and may be absent
on supported Perls; use them only when those conditions are established.

Do not retain an `SV **` slot pointer across operations that can resize or
mutate its container. Retain the SV separately if it must survive mutation,
and re-fetch slots when needed. Hash iteration state can be disturbed by nested
iteration or callbacks; do not expose an iteration strategy that assumes users
cannot reenter it.

### Hash iteration

`hv_iterinit()` and `hv_iternext()` use the same iterator state (`HvRITER`,
`HvEITER`) as the caller's `each()`. Walking a hash with them from inside a
caller's `while (my ($k, $v) = each %h)` loop restarts that loop every time, so
it never terminates. Choose one of these strategies:

- For an untied hash that runs no callbacks during the walk, walk the
  `HvARRAY` buckets directly. This leaves the iterator alone but depends on the
  bucket layout.
- Otherwise save `HvRITER_get`, `HvEITER_get` and the `HvLAZYDEL` flag before
  the walk and restore them after. This works only for untied hashes; a tied
  hash keeps its iterator in Perl through `FIRSTKEY`/`NEXTKEY` and cannot be
  restored.

When the caller has deleted its current `each()` entry, perl has unlinked it
but defers freeing it until the iterator moves (`HvLAZYDEL`). `hv_iterinit()`
would free it while the caller still holds it. Turn the flag off for the walk
and put it back together with the saved entry.

If a callback can run between save and restore, the saved entry can be freed:
while the walk owns `HvEITER`, a deleted entry is freed immediately. Before
restoring, confirm that the entry is still linked in its bucket. Under
`PERL_HASH_RANDOMIZE_KEYS` `HvRITER` is a position in iteration order, not a
bucket number; the bucket is `(riter ^ xhv_rand) & HvMAX`, which
`PERL_HASH_ITER_BUCKET()` computes. A split changes `xhv_rand`; in that case
drop the saved entry, since perl documents iteration after insertion as
undefined. Read `HvAUX` only when `SvOOK` is set on the hash.

`HvRITER`, `HvEITER`, `HvLAZYDEL`, `HvAUX`, `xhv_rand` and
`PERL_HASH_ITER_BUCKET` are internal details, not public API. Feature-test each
per supported version and justify its use in a comment.

Test iterator handling with enough keys that several share a bucket: a small
hash can pass by luck of the hash seed. Bound every loop in such a test so a
regression fails instead of hanging, and run it under several
`PERL_HASH_SEED` values.

### Shared hash keys

Keys of hashes with `HvSHAREKEYS` live in the shared string table. A key's
address is stable only while some entry references it. A cache keyed by key
address, for example to refer back to an earlier copy of the same key, must
keep the entry alive across any callback that could delete the key. Otherwise
a different key can reuse the address and the cache silently points at the
wrong text.

`newSVhek()` returns a copy-on-write shared-hash-key scalar
(`SvIsCOW_shared_hash`) that holds a reference to the entry for an ordinary key.
It returns a private copy instead for a key flagged not shared, and an upgraded
private copy for a WASUTF8 key: a key supplied as UTF-8 whose characters all fit
Latin-1, which perl stores downgraded with `HEK_WASUTF8`. A retention or
deduplication scheme built on `newSVhek()` therefore silently stops covering
those keys; handle them explicitly and test with them. Keys with the same bytes
but different UTF8/WASUTF8 flags are separate string-table entries, yet equal
as hash keys.

Taking an entry reference with `share_hek_hek()` is internal, and its release,
`unshare_hek()`, is core-only before 5.38. The portable form is to hold a
shared-hash-key scalar and release it through `SvREFCNT_dec`, letting
`sv_clear()` drop the entry.

## Cleanup across errors

Perl conversions, memory allocations, magic, callbacks, warnings configured as
fatal, and destructors can croak. Any C resource still owned at that point
needs an unwind plan. Acquire after validation where possible; use a suitable
Perl-owned guard or documented save-stack cleanup in a valid dynamic scope
when later work can throw. Consult `SAVEDESTRUCTOR_X`, `SAVEFREESV`, and related
entries for the target Perl before registering cleanup. Save-stack cleanup
and mortal cleanup have different boundaries; neither should be registered
twice for the same ownership obligation.

`ENTER`/`LEAVE` delimit dynamic scopes; `SAVETMPS`/`FREETMPS` delimit temporary
cleanup within them. A result that will be used after temporary cleanup needs
an independent reference or copy before cleanup. Do not insert a new temps
scope and then return its already-freed mortal.

The generated `CLEANUP:` section runs after normal output conversion. It will
not run when an earlier input/output conversion or `CODE:` croaks, nor after
an early `XSRETURN_*`. A manual `free` after a throwing operation is similarly
insufficient. Match allocators: `Newx`/`Newxz`/`Renew` with `Safefree`, library
allocations with that library's release operation. Check multiplication and
addition for overflow before allocating from user-controlled counts.

A size declared by untrusted input needs an upper bound, for example
`SSize_t_MAX`, and must not reach `Newx` unguarded: on allocation failure perl
prints "Out of memory!" and exits the process. Set `PL_nomemok = TRUE` around
the allocation, restore it afterwards, and test for NULL so failure becomes a
catchable croak.

## Magic and reentry

Use `perlapi` to distinguish a function's source get magic from destination
set magic. For example, `sv_setsv` gets source magic but does not set destination
magic; `sv_setsv_mg` does both. Ordinary `sv_setpvn` does not invoke set magic.
Use the appropriate `_mg` form or a deliberate `SvSETMAGIC` after the write,
without invoking it twice through generated output code too.

If checks require a fetched magical value, arrange one intentional get and use
compatible no-magic operations for subsequent checks/conversion. Do not simply
add `SvGETMAGIC` before a getter that already does it: a tied scalar may return
a different value on each `FETCH`. Document intentional repeated reads.

Get/set magic, stringification overload, callback execution, and a final
decrement can all reenter the module. Keep the current receiver/callback alive,
avoid half-updated native state, and invalidate stale buffer or container-slot
pointers. A refcount increment preserves object lifetime, not value immutability.

Before any operation that can run Perl, take owned references
(`SvREFCNT_inc` plus `SAVEFREESV`) on everything the C code still needs
afterwards: the inputs, caller-supplied outputs, the object being passed and
the code to be called. Such operations include get magic, tied `FETCH`,
serialisation hooks such as `FREEZE`/`THAW`, overloads, allow-list predicates,
and `DESTROY` triggered by any decrement, including `sv_setsv` overwriting a
caller-supplied output.

- Retain the CV, not the glob. A callback can `delete $Pkg::{name}` or replace
  the sub, so a `GvCV()` fetched before the callback can dangle afterwards.
- A retained input keeps the SV head alive, not its buffer. A callback that
  assigns to the input frees the PV the C code is reading. Copy the input
  first, or compare `SvPVX`/`SvCUR` with the captured pointer and length after
  each callback and croak on a change.
- Retain container elements along the whole path to the callback, not to a
  fixed depth. A tied scalar two levels down whose `FETCH` empties the outer
  container frees the siblings still to be visited. Either retain from the root
  whenever a callback-capable value may exist, or detect the first such value
  before its code runs and restart in a retaining mode. A depth-limited
  predicate is unsafe at any depth.

Before writing into a caller-supplied output scalar, refuse a read-only
destination with `croak("%s", PL_no_modify)` and reset it with
`sv_setsv(into, &PL_sv_undef)`. The reset releases any old referent and may run
`DESTROY`, so do it before capturing input buffer pointers. Repurposing a
scalar that holds a string into a reference without clearing its POK and COW
state leaves flags that crash on the next scope exit.

For private extension magic, use a unique `MGVTBL` identity, supported attachment
APIs, and explicit payload free/duplication rules. Check `mg_findext` preconditions
before calling it on an arbitrary SV. Do not reuse internal magic implementations
or remove another extension's magic of the same type.

Sources: `perlguts` sections on Reference Counts and Mortality, Working with AVs/
HVs, Magic Variables, and Localizing changes; `perlapi` entries for every API
named above; `perlxs` Returning Values from an XSUB; the target `hv.h` and
`sv.h` for the iterator, shared-key and copy-on-write internals; the
`embed.fnc` flag legend and `Devel::PPPort` for their availability per version.
